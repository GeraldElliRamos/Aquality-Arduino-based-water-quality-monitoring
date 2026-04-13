const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = Number(process.env.PORT || 3001);
const MODEL_CANDIDATES = String(
  process.env.GEMINI_MODELS || 'gemini-2.5-flash,gemini-1.5-flash'
)
  .split(',')
  .map((m) => m.trim())
  .filter(Boolean);

const FREE_RPM_LIMIT = Number(process.env.FREE_RPM_LIMIT || 5);
const FREE_RPD_LIMIT = Number(process.env.FREE_RPD_LIMIT || 20);
const ONE_MINUTE_MS = 60 * 1000;
const ONE_DAY_MS = 24 * 60 * 60 * 1000;

let minuteWindowStart = Date.now();
let minuteUsed = 0;
let dayWindowStart = Date.now();
let dayUsed = 0;

function resetQuotaWindows(now) {
  if (now - minuteWindowStart >= ONE_MINUTE_MS) {
    minuteWindowStart = now;
    minuteUsed = 0;
  }

  if (now - dayWindowStart >= ONE_DAY_MS) {
    dayWindowStart = now;
    dayUsed = 0;
  }
}

function getQuotaStatus(now = Date.now()) {
  resetQuotaWindows(now);

  const minuteRemaining = Math.max(0, FREE_RPM_LIMIT - minuteUsed);
  const dayRemaining = Math.max(0, FREE_RPD_LIMIT - dayUsed);

  return {
    limits: {
      rpm: FREE_RPM_LIMIT,
      rpd: FREE_RPD_LIMIT,
    },
    usage: {
      currentMinute: minuteUsed,
      currentDay: dayUsed,
    },
    remaining: {
      minute: minuteRemaining,
      day: dayRemaining,
    },
    resetInSeconds: {
      minute: Math.max(0, Math.ceil((ONE_MINUTE_MS - (now - minuteWindowStart)) / 1000)),
      day: Math.max(0, Math.ceil((ONE_DAY_MS - (now - dayWindowStart)) / 1000)),
    },
  };
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isRetryableStatus(status) {
  return status === 429 || status === 500 || status === 503;
}

async function callGeminiWithFallback({ apiKey, payload }) {
  let lastError = null;

  for (const model of MODEL_CANDIDATES) {
    for (let attempt = 1; attempt <= 3; attempt += 1) {
      try {
        const response = await axios.post(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
          payload,
          {
            headers: {
              'Content-Type': 'application/json',
            },
            timeout: 20000,
          }
        );

        return { model, response };
      } catch (error) {
        lastError = error;
        const status = error?.response?.status;

        // Retry transient failures for the same model.
        if (isRetryableStatus(status) && attempt < 3) {
          await sleep(500 * attempt);
          continue;
        }

        // Try the next model for unsupported/invalid model errors.
        if (status === 400 || status === 404) {
          break;
        }

        // For non-retryable errors, bubble up immediately.
        throw error;
      }
    }
  }

  throw lastError || new Error('All configured Gemini models failed.');
}

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Chatbot proxy server is running',
    quota: getQuotaStatus(),
  });
});

// Proxy endpoint for Gemini API
app.post('/api/chat', async (req, res) => {
  try {
    const { messages, systemPrompt } = req.body;
    const resolvedApiKey = process.env.GEMINI_API_KEY;

    // Validate input
    if (!messages || !Array.isArray(messages) || messages.length == 0) {
      return res.status(400).json({
        error: 'Missing or invalid messages payload',
      });
    }

    if (!resolvedApiKey) {
      return res.status(400).json({
        error: 'Missing API key. Set GEMINI_API_KEY in backend/.env',
      });
    }

    const now = Date.now();
    const quotaBefore = getQuotaStatus(now);
    if (quotaBefore.remaining.minute <= 0 || quotaBefore.remaining.day <= 0) {
      return res.status(429).json({
        message: 'Free-tier limit reached for this backend tracker.',
        details: `Requests left this minute: ${quotaBefore.remaining.minute}, today: ${quotaBefore.remaining.day}.`,
        quota: quotaBefore,
      });
    }

    minuteUsed += 1;
    dayUsed += 1;

    const geminiMessages = messages.map((m) => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: String(m.content ?? '') }],
    }));

    const payload = {
      system_instruction: {
        parts: [{ text: systemPrompt || 'You are a helpful assistant.' }],
      },
      contents: geminiMessages,
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 500,
      },
    };

    const { model, response } = await callGeminiWithFallback({
      apiKey: resolvedApiKey,
      payload,
    });

    const parts = response.data?.candidates?.[0]?.content?.parts ?? [];
    const reply = parts
      .map((p) => p.text)
      .filter((t) => typeof t === 'string' && t.trim().length > 0)
      .join('\n')
      .trim();

    if (!reply) {
      return res.status(502).json({
        message: 'Gemini returned an empty response',
      });
    }

    // Return normalized response
    res.json({ success: true, reply, model, quota: getQuotaStatus() });
  } catch (error) {
    console.error('Proxy error:', error.message);

    if (error.response) {
      console.error('Proxy error response:', JSON.stringify(error.response.data));
      // Gemini API error
      return res.status(error.response.status).json({
        error: error.response.data,
        message: `Gemini API error: ${error.response.status}`,
        details: error.response.data?.error?.message || 'Unknown Gemini error',
        quota: getQuotaStatus(),
      });
    }

    // Network or other error
    res.status(500).json({
      error: error.message,
      message: 'Failed to connect to Gemini API',
      quota: getQuotaStatus(),
    });
  }
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`🚀 Chatbot proxy server running on http://localhost:${PORT}`);
  console.log(`📍 POST /api/chat - Forward messages to Gemini API`);
  console.log(`💚 GET /health - Check server status`);
});

server.on('error', (error) => {
  if (error && error.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Set PORT in backend/.env to another value and restart.`);
    process.exit(1);
  }
  throw error;
});
