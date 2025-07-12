<div align='center'>
  
# 💬 KChat 

A Flutter-based chat application designed for university departments, enabling students to connect and communicate with their departmental peers in a secure and organized environment.

<img height="300" alt="Screenshot (168)" src="https://github.com/user-attachments/assets/e7e75129-6c75-4c36-991b-8baae6167253" />
<img height="300" alt="Screenshot (184)" src="https://github.com/user-attachments/assets/0b10c07c-a2dd-4bfa-9866-c9f87265b94a" />


</div>


## 🎯 Overview

KChat is a department-wise chat application that allows university students to register with their specific departments and chat exclusively with their departmental colleagues. The app features **AI-powered conversations**, **group chats**, **file sharing**, and **real-time messaging** with a modern, intuitive interface.

## ✨ Features

### 🔐 Authentication & Security
- **Firebase Authentication** for secure user management
- **Email verification** required during registration
- **Password reset** functionality
- **Profile protection** with password verification for edits

### 👥 Department-Based Networking
- **Department selection** during registration
- **Department-exclusive** user visibility
- **Real-time user status** (active/inactive)
- **Profile customization** with image uploads

### 💬 Chat Features
- **Real-time messaging** with departmental peers
- **Group chat creation** with selected members
- **File sharing** (images and PDFs)
- **Message notifications** when logged out
- **Chat history** persistence

### 🤖 AI Integration
- **Gemini API** integration for AI conversations
- **Groq API** (Llama3-8b-8192) for enhanced AI responses
- **Smart chat assistance** for students

### 📁 File Management
- **Image sharing** in chats
- **PDF document sharing**
- **Profile picture uploads**
- **Secure file storage** via Supabase

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language
- **Get** - State management and navigation
- **Google Fonts** - Typography

### Backend Services
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Document database
- **Firebase Realtime Database** - Real-time data sync
- **Supabase** - File storage and management

### APIs & Integrations
- **Gemini API** - AI chat functionality
- **Groq API** - Advanced AI responses
- **Flutter PDF** - PDF handling and viewing

## 📦 Dependencies

```yaml
dependencies:
  cupertino_icons: ^1.0.8
  firebase_core: ^3.13.1
  firebase_auth: ^5.5.4
  get_it: ^8.0.3
  dash_chat_2: ^0.0.21
  cloud_firestore: ^5.6.8
  firebase_database: ^11.3.6
  uuid: ^4.5.1
  google_fonts: ^6.2.1
  delightful_toast: ^1.1.0
  path: ^1.9.1
  image_picker: ^1.1.2
  badges: ^3.1.2
  get: ^4.7.2
  http: ^1.4.0
  pdf: ^3.11.3
  syncfusion_flutter_pdf: ^29.2.7
  file_picker: ^10.1.9
  flutter_dotenv: ^5.2.1
  fluttertoast: ^8.2.12
  toastification: ^3.0.2
  supabase_flutter: ^2.9.0
  url_launcher: ^6.3.1
  flutter_pdfview: ^1.3.2
  path_provider: ^2.1.5
  flutter_markdown: ^0.7.7+1
  intl: ^0.19.0
```

## Screenshots:
<div align="center">


<details>
<summary>
<strong>Splash Screen</strong> 
</summary>
<br>
  
<img height="500" alt="splash2" src="https://github.com/user-attachments/assets/da5432f2-994d-4a48-a79a-7d4f66a26c9b" />
<img height="500" alt="Splash1" src="https://github.com/user-attachments/assets/17788289-83d5-4c82-ac9c-2e31a066fbe2" />

</details>

<details>
<summary>
<strong>Register</strong> 
</summary>
<br>
  
<img height="500" alt="reg2" src="https://github.com/user-attachments/assets/4fdbb677-ff3d-44e9-a6b1-4d4b55143b73" />
<img height="500" alt="reg1" src="https://github.com/user-attachments/assets/6e27a98f-0d6e-4e25-bf8b-a87d182d9028" />

</details>

<details>
<summary>
<strong>Login</strong> 
</summary>
<br>
  
<img height="500" alt="Screenshot__164_-removebg-preview" src="https://github.com/user-attachments/assets/b9c343cf-e268-46b3-bdce-4c1c940ac5a7" />

</details>

<details>
<summary>
<strong>Reset Password</strong> 
</summary>
<br>
  
<img height="400" alt="Screenshot__165_-removebg-preview" src="https://github.com/user-attachments/assets/fe6d4372-2060-4ea5-999d-2f620b092239" />
<img height="400" alt="Screenshot (200)" src="https://github.com/user-attachments/assets/64e8d098-122b-49f2-bf5a-fc158f32e404" />

</details>

<details>
<summary>
<strong>Home</strong> 
</summary>
<br>

<img height="500" alt="Screenshot (184)" src="https://github.com/user-attachments/assets/2c1ea22f-13a9-4b70-8f59-1870aab94334" />
<img height="500" alt="Screenshot (178)" src="https://github.com/user-attachments/assets/86b0ed76-6e4c-4377-b528-15f176a14b73" />


</details>

<details>
<summary>
<strong>Chat page</strong> 
</summary>
<br>
<p>One can send and view image and pdfs</p>

<img height="500" alt="Screenshot (193)" src="https://github.com/user-attachments/assets/3f047f09-0473-42b3-bc50-b9a973ddb62e" />
<img height="500" alt="Screenshot (192)" src="https://github.com/user-attachments/assets/d496dd17-98ca-4a97-8644-79c3ece4b9e8" />


</details>



<details>
<summary>
<strong>Edit profile</strong> 
</summary>
<br>
<p>Correct password is required to modify profile</p>

<img height="500" alt="Screenshot (180)" src="https://github.com/user-attachments/assets/bb4620bd-5e9c-4a09-9593-24a1a79e879d" />

</details>


<details>
<summary>
<strong>Group Chat</strong> 
</summary>
<br>

<img height="400" alt="Screenshot (185)" src="https://github.com/user-attachments/assets/50a2a6bd-3e99-435d-81c9-ac90d7ae5a75" />
<img height="400" alt="Screenshot (189)" src="https://github.com/user-attachments/assets/b9487fcf-e085-405c-80cb-fed5709c282e" />
<img height="400" alt="Screenshot (186)" src="https://github.com/user-attachments/assets/f51b2dde-5f4f-4cf3-bf49-ae3722545ea6" />
<img height="400" alt="Screenshot (188)" src="https://github.com/user-attachments/assets/585fcf05-84e3-427d-970b-f5c55c127356" />
<img height="400" alt="Screenshot (186)" src="https://github.com/user-attachments/assets/dfc4d340-d82e-4baa-9728-b6502e1f83ce" />

</details>


<details>
<summary>
<strong>Chat with Ai</strong> 
</summary>
<br>
<p>User can switch between <b>Gemini</b> and <b>Groq</b></p>
  
<img height="500" alt="Screenshot (182)" src="https://github.com/user-attachments/assets/aef83e21-8a1b-4a83-989f-94352567171e" />
<img height="500" alt="Screenshot (181)" src="https://github.com/user-attachments/assets/d0548600-5387-4208-89ee-8fa7c5741cf1" />


</details>


<details>
<summary>
<strong>Notifications</strong> 
</summary>
<br>
<p>Notifications will arrive if you are inactive</p>
  
<img height="500" alt="Screenshot (198)" src="https://github.com/user-attachments/assets/cef8c061-7ec8-43a8-a548-956fbf6fe559" />

</details>


<details>
<summary>
<strong>Email verification and Reset password mails</strong> 
</summary>
<br>
  
<img height="500" alt="Screenshot (175)" src="https://github.com/user-attachments/assets/d2cab47a-e7f6-434b-82fa-6e9230e9615f" />
<img height="500" alt="Screenshot (201)" src="https://github.com/user-attachments/assets/6c0decf5-f075-4a93-8d1b-be020254647f" />


</details>


</div>



## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase project setup
- Supabase project setup
- Gemini API key
- Groq API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/AHMED-SAFA/KChat.git
   cd kchat
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project
   - Add your Android/iOS app to the project
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication, Firestore, and Realtime Database

4. **Configure Supabase**
   - Create a new Supabase project
   - Set up storage buckets for profile images and chat files
   - Note your project URL and anon key

5. **Environment Setup**
   Create a `.env` file in the root directory:
   ```env
   GEMINI_API_KEY=
   GROQ_API_KEY=
    
   FIREBASE_API_KEY_ANDROID=
   FIREBASE_APP_ID_ANDROID=
   FIREBASE_MESSAGING_SENDER_ID=
   FIREBASE_PROJECT_ID=
   FIREBASE_STORAGE_BUCKET=
    
   FIREBASE_API_KEY_IOS=
   FIREBASE_APP_ID_IOS=
   FIREBASE_IOS_BUNDLE_ID=
    
   FIREBASE_API_KEY_WEB=
   FIREBASE_APP_ID_WEB=
   FIREBASE_AUTH_DOMAIN=
   FIREBASE_MEASUREMENT_ID=
    
   SUPABASE_URL=
   SUPABASE_ANON_KEY=
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── models/           # Data models
├── services/         # API and database services
├── controllers/      # State management
├── widgets/         # Reusable components
├── utils/           # Helper functions
└── main.dart        # App entry point
```

## 🔧 Configuration

### Supabase Storage Policies
Set up appropriate storage policies for file uploads based on user authentication.

## Setup SupaBase
```dart
Future<void> setupSupabase() async {
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}
```

## Setup FireBase

```dart
Future<void> setupFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
```

## 🎨 Features in Detail

### Registration Flow
1. User provides email, password, name, and department
2. Profile picture selection (optional)
3. Email verification sent
4. Account activated only after email verification

### Department-Based Chat
- Users only see peers from their selected department
- Real-time status updates
- Group creation with departmental colleagues

### AI Chat Integration
- Seamless integration with **Gemini** and **Groq APIs**
- Context-aware responses
- Educational assistance for students

### File Sharing
- Image sharing with preview
- PDF document sharing with built-in viewer
- Secure cloud storage via Supabase

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add some new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request
