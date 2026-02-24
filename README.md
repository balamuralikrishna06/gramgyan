
Gram Gyan is an AI-powered, audio-first knowledge transfer system designed to bridge the information gap for Indian farmers. By combining Google Gemini with a community-driven validation loop, the app ensures farmers receive instant, accessible, and verified agricultural advice.

🚀 Key Features

🎙️ Audio-First UI: Farmers record queries in their local language—no typing required.
🤖 AI Fallback: Uses Gemini 1.5 Flash to provide instant "AI-labeled" answers if no database match exists.
🤝 Community Knowledge: Questions are posted to a community feed where experts and peers can provide verified solutions.
🛡️ Admin Moderation: All human answers require admin approval before the user is notified, preventing misinformation.
📊 Statistical Reporting: Generates automated HTML reports on regional agricultural trends (pest outbreaks, crop health) via EmailJS.
🛠️ Tech StackComponentTechnologyMobileAndroid (Java/Kotlin)AI/LLMGoogle Gemini (via Vertex AI / Gemini API)BackendPython/Node.js hosted on RenderDatabaseSupabase (PostgreSQL & Vector Search)StorageSupabase Storage (Audio Files)AuthFirebase AuthenticationAutomationEmailJS (Reporting)
🔄 System ArchitectureInput: Farmer uploads an audio query to Supabase Storage.Processing: The Render backend triggers an AI search.Response: * If found in DB: Audio answer is retrieved instantly.If not found: Gemini generates a labeled AI response.

Community: 
The query enters the community pool for human experts.

Notification: Once an admin approves a community answer, a Firebase Cloud Messaging notification is sent.

Gram Gyan focuses on:
Inclusivity: Overcoming literacy barriers with voice.Decision 
Support: Providing government-level statistical insights for regional crop health.
📄 LicenseThis project is developed for academic and competition purposes at Kalasalingam Academy of Research and Education.
