Gram Gyan is a comprehensive Agri-Tech platform designed to bridge the digital and linguistic divide in Indian agriculture. By moving beyond traditional top-down information sharing, the app creates a peer-to-peer (P2P) knowledge loop where local expertise is verified by AI and made accessible to every farmer, regardless of their native language or literacy level.

Key Features
Multilingual Voice Interface: Leveraged Sarvam AI (STT/TTS) to enable farmers to ask queries and receive advice in 11 Indian languages, removing literacy barriers.

Disease Radar & Spatial Analytics: Developed a real-time tracking system using Supabase to log user-reported crop issues with GPS coordinates, generating a visual heatmap of pest outbreaks.

Vision-Based Diagnostics: Integrated the Gemini API for instant image-based disease detection and actionable recovery advice.

Knowledge Verification Engine: Implemented a dual-layer verification system using AI flag detection and human-in-the-loop admin approval to ensure the accuracy of community-shared advice.

Smart Crop Advisor: Built an ML-driven recommendation engine that suggests the top 5 most viable crops based on environmental data and risk-level analysis.

Technical Stack
Frontend: Flutter (Mobile & Web)

Backend: FastAPI (Python) hosted on Render

Database & Auth: Supabase (Data & Vector Search), Firebase (OTP/OAuth)

AI/ML: Gemini API (Vision/LLM), Sarvam AI (Localization), Vector Embeddings for Knowledge Retrieval
