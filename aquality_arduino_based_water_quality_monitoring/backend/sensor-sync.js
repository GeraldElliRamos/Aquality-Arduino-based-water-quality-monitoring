/**
 * Firebase Backend Endpoint for Sensor Data Synchronization
 * 
 * This file demonstrates how to set up a Node.js backend endpoint
 * that receives sensor data from your ESP32 and syncs it to Firestore.
 * 
 * Use this if your ESP32 has difficulty writing directly to Firestore.
 */

const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

// Initialize Firebase Admin SDK
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountKey) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable not set');
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(serviceAccountKey)),
});

const app = express();
const db = admin.firestore();

// Middleware
app.use(cors());
app.use(express.json());

// ──────────────────────────────────────────────────────────────
// Endpoint: POST /api/sensor-data
// 
// Receives sensor data from ESP32 and writes to Firestore
// 
// Expected request body:
// {
//   "temperature": 27.5,
//   "ph": 7.2,
//   "ammonia": 0.1,
//   "turbidity": 23.4,
//   "device_id": "esp32_001"
// }
// ──────────────────────────────────────────────────────────────
app.post('/api/sensor-data', async (req, res) => {
  try {
    const { temperature, ph, ammonia, turbidity, device_id = 'esp32_001' } = req.body;

    // Validate required fields
    if (temperature === undefined || ph === undefined || ammonia === undefined || turbidity === undefined) {
      return res.status(400).json({
        error: 'Missing required fields: temperature, ph, ammonia, turbidity',
      });
    }

    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // Write to Firestore at: sensor_readings/{device_id}
    await db.collection('sensor_readings').doc(device_id).set({
      readings: {
        temperature: parseFloat(temperature),
        ph: parseFloat(ph),
        ammonia: parseFloat(ammonia),
        turbidity: parseFloat(turbidity),
        timestamp: Date.now(), // milliseconds since epoch
      },
      device_id,
      updated_at: timestamp,
      updated_at_ms: Date.now(),
    });

    // Also save to history for trend analysis
    const historyTimestamp = Date.now();
    await db.ref(`sensor_readings/${device_id}/history`).child(historyTimestamp.toString()).set({
      temperature: parseFloat(temperature),
      ph: parseFloat(ph),
      nh3: parseFloat(ammonia),
      turbidity: parseFloat(turbidity),
    });

    console.log(`[Sensor Data] Updated device ${device_id} at ${new Date().toISOString()}`);

    res.json({
      success: true,
      timestamp: historyTimestamp,
      message: `Sensor data saved for device ${device_id}`,
    });
  } catch (error) {
    console.error('[Sensor Data] Error:', error);
    res.status(500).json({
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

// ──────────────────────────────────────────────────────────────
// Endpoint: GET /api/sensor-data/:device_id
// Returns the latest sensor reading for a device
// ──────────────────────────────────────────────────────────────
app.get('/api/sensor-data/:device_id', async (req, res) => {
  try {
    const { device_id } = req.params;
    const snapshot = await db.collection('sensor_readings').doc(device_id).get();

    if (!snapshot.exists) {
      return res.status(404).json({
        error: `No data found for device ${device_id}`,
      });
    }

    res.json({
      device_id,
      data: snapshot.data(),
    });
  } catch (error) {
    console.error('[Get Sensor Data] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ──────────────────────────────────────────────────────────────
// Endpoint: POST /api/batch-sensor-data
// Bulk insert multiple readings (for backfilling historical data)
// ──────────────────────────────────────────────────────────────
app.post('/api/batch-sensor-data', async (req, res) => {
  try {
    const { readings, device_id = 'esp32_001' } = req.body;

    if (!Array.isArray(readings) || readings.length === 0) {
      return res.status(400).json({
        error: 'readings must be a non-empty array',
      });
    }

    const batch = db.batch();
    let count = 0;

    for (const reading of readings) {
      const { temperature, ph, ammonia, turbidity, timestamp } = reading;

      if (!timestamp) {
        console.warn('Skipping reading without timestamp:', reading);
        continue;
      }

      const docRef = db
        .collection('sensor_readings')
        .doc(device_id)
        .collection('history')
        .doc(timestamp.toString());

      batch.set(docRef, {
        temperature: parseFloat(temperature),
        ph: parseFloat(ph),
        nh3: parseFloat(ammonia),
        turbidity: parseFloat(turbidity),
        timestamp: parseInt(timestamp),
      });

      count++;
    }

    await batch.commit();

    console.log(`[Batch Sensor Data] Inserted ${count} readings for device ${device_id}`);

    res.json({
      success: true,
      count,
      message: `Inserted ${count} readings`,
    });
  } catch (error) {
    console.error('[Batch Sensor Data] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ──────────────────────────────────────────────────────────────
// Health Check
// ──────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`[Server] Aquality Sensor Data Sync listening on port ${PORT}`);
  console.log(`POST  /api/sensor-data          - Submit sensor reading`);
  console.log(`GET   /api/sensor-data/:device_id - Get latest reading`);
  console.log(`POST  /api/batch-sensor-data    - Bulk insert readings`);
  console.log(`GET   /api/health               - Health check`);
});

/**
 * ═════════════════════════════════════════════════════════════
 * SETUP INSTRUCTIONS
 * ═════════════════════════════════════════════════════════════
 * 
 * 1. Create .env file with:
 *    FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
 *    PORT=3000
 * 
 * 2. Install dependencies:
 *    npm install express firebase-admin cors dotenv
 * 
 * 3. Run server:
 *    node sensor-sync.js
 * 
 * 4. Configure ESP32 to POST to:
 *    POST http://your-backend.com/api/sensor-data
 *    Content-Type: application/json
 *    
 *    {
 *      "temperature": 27.5,
 *      "ph": 7.2,
 *      "ammonia": 0.1,
 *      "turbidity": 23.4,
 *      "device_id": "esp32_001"
 *    }
 * 
 * 5. In your Arduino/ESP32 code:
 *    
 *    #include <WiFi.h>
 *    #include <HTTPClient.h>
 *    #include <ArduinoJson.h>
 *    
 *    void sendSensorData() {
 *      if (WiFi.status() == WL_CONNECTED) {
 *        HTTPClient http;
 *        String serverName = "http://your-backend.com/api/sensor-data";
 *        
 *        http.begin(serverName);
 *        http.addHeader("Content-Type", "application/json");
 *        
 *        StaticJsonDocument<200> doc;
 *        doc["temperature"] = sensorTemperature;
 *        doc["ph"] = sensorPH;
 *        doc["ammonia"] = sensorAmmonia;
 *        doc["turbidity"] = sensorTurbidity;
 *        doc["device_id"] = "esp32_001";
 *        
 *        String body;
 *        serializeJson(doc, body);
 *        
 *        int httpResponseCode = http.POST(body);
 *        
 *        if (httpResponseCode > 0) {
 *          Serial.println("Data sent successfully");
 *        } else {
 *          Serial.println("Error sending data");
 *        }
 *        
 *        http.end();
 *      }
 *    }
 * ═════════════════════════════════════════════════════════════
 */
