const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Chatbot proxy server is running' });
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

    const geminiMessages = messages.map((m) => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: String(m.content ?? '') }],
    }));

    // Call Gemini API
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${resolvedApiKey}`,
      {
        system_instruction: {
          parts: [{ text: systemPrompt || 'You are a helpful assistant.' }],
        },
        contents: geminiMessages,
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 500,
        },
      },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 20000,
      }
    );

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
    res.json({ success: true, reply });
  } catch (error) {
    console.error('Proxy error:', error.message);

    if (error.response) {
      console.error('Proxy error response:', JSON.stringify(error.response.data));
      // Gemini API error
      return res.status(error.response.status).json({
        error: error.response.data,
        message: `Gemini API error: ${error.response.status}`,
        details: error.response.data?.error?.message || 'Unknown Gemini error',
      });
    }

    // Network or other error
    res.status(500).json({
      error: error.message,
      message: 'Failed to connect to Gemini API',
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Chatbot proxy server running on http://localhost:${PORT}`);
  console.log(`📍 POST /api/chat - Forward messages to Gemini API`);
  console.log(`💚 GET /health - Check server status`);
});
