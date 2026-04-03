# 🌱 GramGyan

> **A Voice-First Farmer Knowledge Sharing App**

GramGyan is a comprehensive Agri-Tech platform designed to bridge the digital and linguistic divide in Indian agriculture. By moving beyond traditional top-down information sharing, the app creates a peer-to-peer (P2P) knowledge loop where local expertise is verified by AI and made accessible to every farmer, regardless of their native language or literacy level.

---

## ✨ Key Features

- **🎙️ Multilingual Voice Interface**  
  Leverages [Sarvam AI](https://sarvam.ai/) (STT/TTS) to enable farmers to ask queries and receive advice in 11 Indian languages, entirely removing literacy barriers.
- **🗺️ Disease Radar & Spatial Analytics**  
  Real-time tracking system via [Supabase](https://supabase.com/) to log user-reported crop issues with GPS coordinates, generating visual heatmaps of pest outbreaks across regions.
- **📸 Vision-Based Diagnostics**  
  Integrates the [Google Gemini API](https://deepmind.google/technologies/gemini/) for instant image-based disease detection and actionable recovery advice from crop photos.
- **🛡️ Knowledge Verification Engine**  
  A dual-layer verification system using AI flag detection and a human-in-the-loop admin approval process to ensure the accuracy and safety of community-shared advice.
- **🌾 Smart Crop Advisor**  
  An ML-driven recommendation engine (using predictive modeling) that suggests the top 5 most viable crops based on environmental data, weather patterns, and risk-level analysis.

## 🛠️ Technical Stack

### **Frontend** (Mobile & Web)
- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** Riverpod
- **Mapping & Location:** Google Maps Flutter, Flutter Map, Geolocator
- **Media & Audio:** AudioPlayers, Record, Image Picker
- **Styling:** Custom ThemeData, Google Fonts

### **Backend**
- **Framework:** FastAPI (Python)
- **Hosting:** Render (Cloud Native Deployment)
- **AI Integration:** Sarvam AI (Speech translation), Google Generative AI (Vision)

### **Database & Authentication**
- **Database Backend:** Supabase (Relational Data & Vector Search)
- **Auth:** Firebase (OTP/OAuth)

---

## 🚀 Getting Started

Follow these steps to set up the GramGyan project locally.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.11.0 or higher)
- [Python 3.9+](https://www.python.org/downloads/)
- Accounts and API Keys for:
  - Supabase
  - Firebase
  - Google Gemini API
  - Sarvam AI

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/gramgyan.git
cd gramgyan
```

### 2. Backend Setup (FastAPI)

Navigate to the backend directory, set up your Python environment, and start the server:

```bash
cd backend

# Create a virtual environment
python -m venv venv
source venv/bin/activate  # On Windows use: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Environment variables
cp .env.example .env
# Edit .env and add your SARVAM_API_KEY

# Run the server
uvicorn app.main:app --reload
```

The backend server will run at `http://localhost:8000`.

### 3. Frontend Setup (Flutter)

Open a new terminal and navigate to the root directory of the project:

```bash
# Get Flutter dependencies
flutter pub get

# Setup environment variables
cp .env.example .env
# Edit .env with your Supabase URL, Anon Key, Gemini API Key, etc.

# Run the app 
# Note: Ensure you have an emulator running or a device connected
flutter run
```

---

## 📂 Project Structure

```text
gramgyan/
├── android/             # Android native platform code
├── ios/                 # iOS native platform code
├── lib/                 # Flutter application code
│   ├── app/             # App routing and entry
│   ├── core/            # Theme, utils, constants, widgets
│   └── features/        # Feature modules (Domain, Presentation, Data)
├── backend/             # FastAPI Python backend for TTS/STT and ML
│   ├── app/             # API routes and core logic
│   └── requirements.txt # Python dependencies
├── assets/              # Images, icons, fonts, animations
└── pubspec.yaml         # Flutter dependencies and configuration
```

---

## 🤝 Contributing

We welcome contributions to make GramGyan even better for the farming community!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

> “Empowering every farmer with the knowledge they need, in the language they speak.”
