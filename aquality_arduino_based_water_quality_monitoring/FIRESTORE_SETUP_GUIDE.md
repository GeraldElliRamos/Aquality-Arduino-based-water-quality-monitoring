# Firestore Live Data Integration Guide

## Problem
The app is not receiving live data from Firestore. The dashboard shows loading or placeholder values.

## Solution Checklist

### 1. **Verify Firestore Document Structure**

Your app expects data at:
```
Collection: sensor_readings
Document: esp32_001
Data structure:
{
  "readings": {
    "temperature": 27.5,
    "ph": 7.2,
    "ammonia": 0.1,
    "turbidity": 23.4,
    "timestamp": 1713000000000  // milliseconds since epoch
  },
  "device_id": "esp32_001"
}
```

**Action:** Log into Firebase Console and verify this exact structure exists in your Firestore database.

### 2. **Enable Firestore Security Rules**

Create Firestore security rules that allow reading:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow anyone to read sensor data
    match /sensor_readings/{document=**} {
      allow read: if true;
      allow write: if request.auth != null; // Only authenticated users can write
    }
  }
}
```

**Action:** 
- Go to Firebase Console → Firestore Database → Rules
- Replace with rules above
- Click "Publish"

### 3. **Ensure Data is Being Written to Firestore**

#### Option A: Arduino/ESP32 Code
Make sure your Arduino/ESP32 is uploading data to the correct Firestore path:

```cpp
// Example Arduino code
void sendToFirestore() {
  // Use Firebase Realtime Database or Cloud Functions to write to Firestore
  FirebaseJson content;
  content.add("readings/temperature", temperature);
  content.add("readings/ph", ph_value);
  content.add("readings/ammonia", nh3_value);
  content.add("readings/turbidity", turbidity);
  content.add("readings/timestamp", millis());
  content.add("device_id", "esp32_001");
  
  if (Firebase.Firestore.createDocument(&fbdo, 
      "projects/aquality-80539/databases/(default)/documents", 
      "sensor_readings/esp32_001", 
      content.raw())) {
    Serial.println("Firestore updated");
  }
}
```

#### Option B: Manual Test Data
Temporarily add test data via Firebase Console:

1. Go to Firebase Console → Firestore Database
2. Create Document → Collection: `sensor_readings`, Document ID: `esp32_001`
3. Add fields:
   ```
   readings: {
     temperature: 27.5
     ph: 7.2
     ammonia: 0.1
     turbidity: 23.4
     timestamp: [current time in milliseconds]
   }
   device_id: "esp32_001"
   ```
4. Save and watch your app update in real-time

### 4. **Enable Real-Time Listener Debugging**

Add debug prints to verify the stream is working:

```dart
@override
void initState() {
  super.initState();
  debugPrint('[Dashboard] Initializing Firebase listener...');
  
  _sensorSub = FirebaseService.instance.sensorStream.listen(
    (reading) {
      debugPrint('[Dashboard] ✅ Got data! Temp: ${reading.temperature}°C, pH: ${reading.ph}');
    },
    onError: (e) {
      debugPrint('[Dashboard] ❌ Stream error: $e');
    },
  );
}
```

**Check the console output:**
- If you see `✅ Got data!` → Firestore is working
- If you see `❌ Stream error:` → Check security rules or Firebase config

### 5. **Verify Firebase Project Configuration**

**Action:**
1. Open `lib/firebase_options.dart` and confirm:
   - `projectId` matches your Firebase project
   - `databaseURL` points to the correct region
   - `appId` is correct

2. Check `android/app/build.gradle.kts` has:
   ```kotlin
   dependencies {
     implementation("com.google.firebase:firebase-bom:X.X.X")
   }
   ```

3. Ensure `google-services.json` is updated:
   - Download latest from Firebase Console
   - Replace `android/app/google-services.json`
   - Run `flutter pub get`

### 6. **Test with Flutter Emulator**

```bash
# Clean build
flutter clean
flutter pub get

# Run with verbose logging
flutter run -v

# Watch for Firebase connection messages in console
```

### 7. **Alternative: Backend Cloud Function**

If ESP32 writing directly to Firestore is problematic, use a backend service:

**Option: Node.js Cloud Function**
```javascript
// backend/functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.updateSensorData = functions.https.onRequest(async (req, res) => {
  try {
    const { temperature, ph, ammonia, turbidity } = req.body;
    
    await admin.firestore().collection('sensor_readings').doc('esp32_001').set({
      readings: {
        temperature,
        ph,
        ammonia,
        turbidity,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      },
      device_id: 'esp32_001'
    });
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

Then have your ESP32 POST to this endpoint instead.

---

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| No data in app | Check Firestore Console → verify data exists at `sensor_readings/esp32_001` |
| "Permission denied" error | Check Firestore Security Rules are published |
| Stream not updating | Restart the app or pull-to-refresh |
| Placeholder values (all zeros) | Data isn't being written to Firestore |
| Green "connected" indicator but no data | Check the document structure matches exactly |

---

## Next Steps

1. **Immediate:** Log into Firebase Console and verify the document exists with correct data
2. **Short-term:** Test with manual data entry to confirm stream works
3. **Long-term:** Ensure ESP32/Arduino continuously writes to Firestore on a schedule (e.g., every 5 minutes)

