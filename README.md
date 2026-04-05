# Aquality-Arduino-based-water-quality-monitoring
**Description:**
Aquality is an Arduino‑based IoT water quality monitoring system for freshwater tilapia ponds, providing continuous, remote sensing, alerts, and basic analytics to optimize fish health and align with Sustainable Development Goal 6 on clean water and sanitation.

**Technologies Used:**
Dart, Flutter, C++, Cloud Computing, Github, Git, Swift, Visual Studio Code, Android Studio, Arduino IDE

**Features:**
* Real-Time Water Monitoring 
* Automated Alerts and Notifications 
* Logs and Reports 
* Remote Access 
* Supports Sustainable Aquaculture

**Installation Instructions**

1. Navigate to the Code Button on the top right side
2. Copy the HTTPS URL
3. Paste it on the Github Desktop
4. Open the repository

**Setup**
* Step 1: Create a Firebase project and register the app.
* Step 2: Install the SDK and initialize Firebase.
* Step 3: Access Firebase in the app.
* Step 4: Use a module bundler (webpack/rollup) for size reduction.

---

# AQUALITY: IoT-Based Water Quality Monitoring System for Tilapia Farms

**Real-time water quality monitoring for tilapia aquaculture — Reducing fish mortality through data-driven intervention**

---

## 📋 Quick Overview

AQUALITY is an IoT-based system designed to help small-scale tilapia farmers in the Philippines monitor water quality in real-time. By combining Arduino sensors with a mobile application, farmers can:

- ✅ Monitor **4 critical water parameters** in real-time: Temperature, pH, Turbidity, and Ammonia
- ✅ Receive **automated alerts** when parameters reach dangerous levels
- ✅ Track **historical data** and identify trends over time
- ✅ Make **timely interventions** to prevent fish mortality and economic loss

---

## 🎯 Project Overview

### The Problem
Traditional water quality monitoring in tilapia farms relies on manual testing, making it difficult to detect problems quickly. Studies show this can result in **up to 30% fish loss per event**. Farmers lack real-time visibility and often cannot react in time.

### The Solution
AQUALITY automates water quality monitoring with:
- **IoT Hardware**: Arduino-based sensor system deployed in tilapia ponds
- **Mobile App**: Native Android application for real-time visualization and alerts
- **Cloud Backend**: Centralized data storage and processing
- **Smart Analytics**: Signal processing algorithms (EWMA, MAD, CUSUM) to filter noise and detect anomalies

---

## 📊 Monitored Parameters

| Parameter | Safe (Optimal) | Warning | Danger |
|-----------|---|---|---|
| **Temperature** | 26–29°C | 25–26°C / 29–30°C | <25°C or >30°C |
| **pH Level** | 7.0–8.5 | 6.5–7.0 / 8.5–9.0 | <6.5 or >9.0 |
| **Turbidity** | ≤30 NTU | 30–50 NTU | >50 NTU |
| **Ammonia** | ≤0.02 mg/L | ≤0.05 mg/L | >0.05 mg/L |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────┐
│   Presentation Tier             │
│   (Mobile App - Android)        │
│   Dashboard | Alerts | History  │
└─────────────┬───────────────────┘
              │
┌─────────────▼───────────────────┐
│   Logic Tier                    │
│ • Data Reception & Processing   │
│ • Threshold Comparison          │
│ • Alert Generation              │
│ • Data Visualization            │
└─────────────┬───────────────────┘
              │
┌─────────────▼───────────────────┐
│   Data Tier                     │
│ • Cloud Database                │
│ • Historical Storage            │
│ • Historical Records            │
└─────────────────────────────────┘
              ▲
              │
    ┌─────────┴─────────┬────────────┬─────────┐
    │                   │            │         │
  ┌─▼──┐  ┌──────┐  ┌──▼───┐  ┌────▼──┐
  │Temp│  │ pH   │  │Turbid│  │Ammonia│
  └────┘  └──────┘  └──────┘  └───────┘
    (Arduino Sensors in Tilapia Pond)
```

---

## 🚀 Getting Started

### Prerequisites

- **Hardware**:
  - Arduino microcontroller (Uno/Mega recommended)
  - Water quality sensors: Temperature, pH, Turbidity, Ammonia
  - WiFi module for connectivity

- **Software**:
  - Android 6.0+ for mobile application
  - Active internet connection for cloud sync
  - Node.js 14+ (Backend server)

### Installation

#### 1. Backend Setup
```bash
cd backend
npm install
node server.js
```

#### 2. Mobile App
- Download from Google Play Store (Year 1: Android only)
- Or build from source:
```bash
cd aquality_arduino_based_water_quality_monitoring
flutter pub get
flutter run
```

#### 3. Arduino Hardware
- Program Arduino with sensor integration code
- Configure WiFi credentials for cloud connectivity
- Deploy sensors in tilapia pond

---

## 📱 Mobile App Features

### Dashboard
- **Circular gauge indicators** for quick visual status of all parameters
- Real-time data updates from sensors
- Color-coded status: Green (Safe) | Yellow (Warning) | Red (Critical)

### Alerts & History
- **Instant notifications** when parameters exceed thresholds
- **Historical data table** for side-by-side comparisons
- **Trend graphs** to visualize water quality changes over time

### User Profiles
- **Tilapia Farmers**: Simple interface for pond monitoring and quick actions
- **Fish Pond Owners**: Multi-pond management and efficiency tracking
- **LGU/Officials**: Aggregate reports across multiple farms

---

## 📂 Project Structure

```
aquality_arduino_based_water_quality_monitoring/
├── lib/                      # Flutter/Dart source code
│   ├── main.dart
│   ├── pages/               # UI screens
│   ├── services/            # Business logic & APIs
│   ├── models/              # Data models
│   ├── widgets/             # Reusable UI components
│   └── utils/               # Helper functions
├── android/                 # Android-specific configuration
├── backend/                 # Node.js backend server
│   ├── server.js
│   └── package.json
├── assets/                  # Images and static files
├── test/                    # Unit and widget tests
├── pubspec.yaml            # Flutter dependencies
└── firebase.json           # Firebase configuration
```

---

## 🔧 Key Technologies

| Layer | Technology |
|-------|-----------|
| **IoT Device** | Arduino, Water Quality Sensors |
| **Connectivity** | WiFi/Bluetooth, MQTT/REST APIs |
| **Mobile App** | Flutter, Dart |
| **Backend** | Node.js, Express (optional) |
| **Database** | Firebase / Cloud Storage |
| **Analytics** | EWMA, MAD, CUSUM algorithms |

---

## 📈 Signal Processing Algorithms

1. **EWMA (Exponentially Weighted Moving Average)**
   - Smooths sensor noise
   - Weights recent readings more heavily
   - Reduces false alerts

2. **MAD (Median Absolute Deviation)**
   - Detects statistical outliers
   - Flags anomalous sensor readings
   - More robust than standard deviation

3. **CUSUM (Cumulative Sum)**
   - Detects gradual drift in parameters
   - Identifies sustained shifts in water quality
   - Enables early warning of deteriorating conditions


## 👥 Team

**Developers & Researchers**
- Legarde, David Chester M.
- Ramos, Gerald Elli T.
- Salonga, Justin Aaron K.
- Soliven, Sean Calvin C.
- Tegio, Gerald

**Adviser**  
- Ms. Nila D. Santiago

**Institution**  
- TIP-Quezon City, College of Computer Studies  
- Bachelor of Science in Information Technology

---

## 🎯 Objectives

### Primary Goals
1. Design an IoT system that monitors temperature, pH, turbidity, and ammonia with real-time alerts
2. Develop a user-friendly Android mobile app for data visualization and notifications
3. Reduce economic losses for small-scale tilapia farmers through accurate, timely alerts
4. Implement advanced signal processing to minimize false alerts

### Expected Impact
- **Reduce tilapia mortality** by 30%+ through early intervention
- **Lower operational costs** by reducing manual monitoring labor
- **Improve farm profitability** through data-driven management decisions
- **Enhance sustainability** of Philippine aquaculture

---

## 📊 Expected Benefits

| Stakeholder | Benefit |
|---|---|
| **Tilapia Farmers** | Real-time alerts → timely intervention → reduced mortality → increased income |
| **Aquaculture Industry** | Modernization of farming practices & IoT adoption models |
| **Environment** | Sustainable water management & minimal ecosystem pollution |
| **Rural Communities** | Economic stability through reduced farm losses & improved livelihoods |
| **Researchers** | Historical water quality data for analysis and policy recommendations |

---

## 📚 Documentation

### Complete Documentation
- [Full Technical Report](./README.md)
- [Weather Setup Guide](./WEATHER_SETUP_GUIDE.md)

### Key Files
- **Architecture**: See System Architecture section above
- **Database Schema**: Entity Relationship Design in technical documentation
- **API Documentation**: Backend API endpoints in backend/README.md

---

## 🔗 References

Key citations from reviewed literature:
- Flores-Iwasaki et al. (2025): IoT sensors for water-quality monitoring in aquaculture
- Molato et al. (2022): Arduino-based water quality monitoring effectiveness
- Erawati et al. (2025): IoT-based monitoring with mobile app interface for tilapia farming
- Boyd (2024): Effects of weather and climate on aquaculture

**[Full Reference List Available in Technical Documentation]**

---

## 📝 License & Usage

This project is developed for the TIP-Quezon City Bachelor of Science in Information Technology program. 

**For inquiries or partnerships**, contact the development team through:
- Local Government Units (LGUs)
- Bureau of Fisheries and Aquatic Resources (BFAR)
- Department of Agriculture (DA)

---

## 🐠 Significance

AQUALITY addresses critical challenges in Philippine tilapia aquaculture by:
- **Reducing economic losses** from undetected water quality deterioration
- **Enabling data-driven decisions** for small-scale farmers with limited resources
- **Supporting food security** through improved aquaculture productivity
- **Demonstrating IoT viability** for rural agricultural applications

For a sustainable future of Philippine aquaculture. 🌊
