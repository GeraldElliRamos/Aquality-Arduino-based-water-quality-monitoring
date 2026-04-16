# ✅ Firestore Live Data - Quick Start

## What Was Done

I've implemented a complete solution to get live Firestore data into your app:

### 1. **New Diagnostic Tool**
- Added **Firestore Diagnostics** screen in Settings
- Tests connection, verifies data structure, shows live updates
- Path: Settings → Support → Firestore Diagnostics

### 2. **Enhanced Firebase Service**
- Added `testConnection()` method for detailed diagnostics
- Better error messages and logging
- Improved timeout handling

### 3. **Documentation & Backend Examples**
- `FIRESTORE_SETUP_GUIDE.md` - Complete setup checklist
- `backend/sensor-sync.js` - Node.js backend endpoint for ESP32 → Firestore sync

---

## 🚀 Quick Start (3 Steps)

### Step 1: Verify Your Firestore Setup
1. Open the app and go to **Settings → Firestore Diagnostics**
2. Check the status indicator:
   - ✅ **Green** = Data is flowing correctly
   - ⚠️ **Yellow** = Connected but no data
   - ❌ **Red** = Connection problem

### Step 2: Fix Any Issues

**If document shows as empty:**
```
1. Go to Firebase Console
2. Create document at: Collection "sensor_readings", Document "esp32_001"
3. Add test data:
   - readings.temperature = 27.5
   - readings.ph = 7.2
   - readings.ammonia = 0.1
   - readings.turbidity = 23.4
   - readings.timestamp = [current time in milliseconds]
```

**If you see permission denied:**
```
1. Go to Firestore Rules in Firebase Console
2. Replace with:
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /sensor_readings/{document=**} {
         allow read: if true;
         allow write: if request.auth != null;
       }
     }
   }
3. Publish the rules
```

### Step 3: Ensure Your ESP32 is Writing Data

**Option A: If ESP32 writes directly to Firestore**
- Make sure it writes to `sensor_readings/esp32_001` every 5 minutes

**Option B: If you prefer backend synchronization**
1. Set up `backend/sensor-sync.js` (see that file for setup)
2. Configure ESP32 to POST to your backend instead
3. Backend will sync to Firestore automatically

---

## 📊 Testing the Connection

### Via Diagnostics Screen
1. Settings → Firestore Diagnostics
2. Watch for status changes as data updates
3. Should show "Updates received: X" as stream updates

### Via Console Logs
When app starts, look for these logs:
```
✅ [Dashboard] Starting Firestore sensor stream listener
✅ [Dashboard] Received sensor reading: temp=27.5, ph=7.2, ...
```

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Diagnostics shows "Document empty" | Add test data to Firebase Console (see Step 2) |
| "Permission denied" error | Update & publish Firestore security rules (see Step 2) |
| Updates arrive then stop | ESP32 may not be writing; check upload schedule |
| App crashes on diagnostics | Ensure flutter pub get ran successfully |

---

## 📝 Files Created/Modified

- ✅ `lib/widgets/firestore_diagnostics.dart` - Diagnostic UI
- ✅ `lib/services/firebase_service.dart` - Enhanced with testConnection()
- ✅ `lib/pages/settings.dart` - Added diagnostics option
- ✅ `FIRESTORE_SETUP_GUIDE.md` - Complete guide
- ✅ `backend/sensor-sync.js` - Backend sync endpoint

---

## ❓ Need Help?

1. **Dashboard still showing placeholders?**
   - Verify document exists at `sensor_readings/esp32_001` with test data
   - Check Firestore rules allow reading

2. **Stream not updating?**
   - Check ESP32 is actually writing data
   - Verify intervals between uploads (should be ≤ 5 mins)

3. **Error messages in logs?**
   - Note the exact error from Diagnostics screen
   - Check FIRESTORE_SETUP_GUIDE.md for common issues

---

Next, try the Diagnostics tool and let me know what status it shows!
