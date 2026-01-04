# MedDoc - Medical Consultation Platform 

A comprehensive Flutter-based telemedicine application connecting doctors and patients for seamless healthcare consultations, appointments, and medical management.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green.svg)

##  Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [Running the Application](#running-the-application)
- [Project Structure](#project-structure)
- [Firebase Functions](#firebase-functions)
- [Available Scripts](#available-scripts)
- [Troubleshooting](#troubleshooting)

##  Overview

MedDoc is a modern telemedicine platform built with Flutter that enables:
- **Patients** to search for doctors, book appointments, and manage their health records
- **Doctors** to manage their practice, schedule, patients, and provide consultations

The platform supports both in-person and video consultations, real-time messaging, appointment notifications, and comprehensive medical record management.

##  Features

### For Patients
-  **Smart Doctor Search** - Find doctors by specialty, location, and availability
-  **Easy Appointment Booking** - Schedule appointments with preferred doctors
-  **Real-time Messaging** - Chat with doctors securely
-  **Video Consultations** - Join virtual consultations from anywhere
-  **Medical Records** - Access prescriptions, reports, and health history
-  **Reviews & Ratings** - Rate and review doctors after appointments
-  **Notifications** - Get reminders for upcoming appointments

### For Doctors
-  **Professional Dashboard** - Overview of appointments, patients, and statistics
-  **Agenda Management** - Manage availability and appointment slots
-  **Patient Management** - View patient details, history, and medical records
-  **Prescription Management** - Create and manage prescriptions
-  **Medical Reports** - Generate and store medical reports
-  **Patient Communication** - Secure messaging with patients
-  **Video Consultations** - Conduct remote consultations
-  **Profile Management** - Customize profile, specialty, and pricing

##  Technologies Used

### Frontend
- **Flutter** (3.0+) - Cross-platform UI framework
- **Dart** - Programming language
- **Riverpod** (2.6.1) - State management
- **Go Router** (14.6.2) - Navigation and routing
- **Image Picker** (0.8.9) - Photo selection
- **File Picker** (8.3.7) - Document selection

### Backend & Services
- **Firebase Authentication** - User authentication and authorization
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File and image storage
- **Firebase Functions** (Node.js + TypeScript) - Serverless backend logic
- **Firebase Cloud Messaging** - Push notifications

### Additional Packages
- **flutter_local_notifications** (17.2.4) - Local notifications
- **intl** (0.18.1) - Internationalization and date formatting
- **timezone** (0.9.4) - Timezone support
- **uuid** (4.5.1) - Unique ID generation
- **flutter_rating_bar** (4.0.1) - Rating UI component

##  Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.0 or higher)
   ```bash
   flutter --version
   ```
   Download from: https://flutter.dev/docs/get-started/install

2. **Dart SDK** (Included with Flutter)

3. **Git**
   ```bash
   git --version
   ```

4. **Node.js** (16.x or higher) - For Firebase Functions
   ```bash
   node --version
   npm --version
   ```
   Download from: https://nodejs.org/

5. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

6. **IDE** (Choose one)
   - Visual Studio Code with Flutter extension
   - Android Studio with Flutter plugin
   - IntelliJ IDEA with Flutter plugin

7. **Platform-specific requirements:**
   - **Android**: Android Studio, Android SDK
   - **iOS**: Xcode (macOS only), CocoaPods
   - **Web**: Chrome browser
   - **Windows**: Visual Studio 2022 with C++ development tools
   - **macOS**: Xcode
   - **Linux**: Required Linux development libraries

##  Installation

### 1. Clone the Repository

```bash
git clone https://github.com/oumaymahammami/meddoc-flutter.git
cd meddoc-flutter
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Install Firebase Functions Dependencies

```bash
cd functions
npm install
cd ..
```

##  Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enable **Google Analytics** (optional)

### 2. Enable Firebase Services

In your Firebase project console:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable **Email/Password** authentication

2. **Firestore Database**
   - Go to Firestore Database → Create database
   - Start in **test mode** (update rules later)
   - Choose your region

3. **Storage**
   - Go to Storage → Get started
   - Start in **test mode** (update rules later)

4. **Cloud Messaging** (Optional)
   - Already enabled by default
   - Configure for push notifications

### 3. Add Firebase to Your Flutter App

#### For Android:
1. In Firebase Console, add Android app
2. Package name: `com.example.meddoc` (or your package name from `android/app/build.gradle`)
3. Download `google-services.json`
4. Place it in `android/app/`

#### For iOS:
1. In Firebase Console, add iOS app
2. Bundle ID: `com.example.meddoc` (or from `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

#### For Web:
1. In Firebase Console, add Web app
2. Copy the Firebase config
3. Update `lib/firebase_options.dart` if needed

### 4. Generate Firebase Options (FlutterFire CLI)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure
```

### 5. Deploy Firestore Security Rules

```bash
firebase login
firebase use --add  # Select your project
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### 6. Deploy Firebase Functions (Optional)

```bash
cd functions
npm run build
firebase deploy --only functions
cd ..
```

##  Running the Application

### Run on Chrome (Web)

```bash
flutter run -d chrome
```

### Run on Android Emulator

```bash
# List available devices
flutter devices

# Run on Android
flutter run -d <device-id>
```

### Run on iOS Simulator (macOS only)

```bash
flutter run -d "iPhone 15 Pro"
```

### Run on Physical Device

1. Enable USB debugging (Android) or trust computer (iOS)
2. Connect device
3. Run:
```bash
flutter run
```

### Build for Production

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

#### Windows
```bash
flutter build windows --release
```

##  Project Structure

```
meddoc-flutter/
├── android/                 # Android native code
├── ios/                     # iOS native code
├── web/                     # Web assets
├── windows/                 # Windows native code
├── linux/                   # Linux native code
├── macos/                   # macOS native code
├── functions/               # Firebase Cloud Functions (Node.js + TypeScript)
│   ├── src/
│   │   ├── index.ts        # Main functions entry
│   │   └── appointmentReminders.ts
│   ├── package.json
│   └── tsconfig.json
├── lib/
│   ├── main.dart           # App entry point
│   ├── firebase_options.dart
│   ├── app/                # App-level configuration
│   │   ├── router.dart     # Navigation routes
│   │   ├── theme.dart      # App theme
│   │   └── auth_gate.dart  # Auth routing logic
│   ├── core/               # Core utilities
│   │   ├── models/
│   │   ├── router/
│   │   └── usecases/
│   ├── features/           # Feature modules
│   │   ├── auth/           # Authentication
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── pages/
│   │   ├── doctor/         # Doctor features
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── pages/
│   │   ├── patient/        # Patient features
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── pages/
│   │   ├── agenda/         # Doctor agenda/schedule
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── widgets/
│   │   └── video_consultation/  # Video calls
│   └── shared/             # Shared utilities
│       ├── services/
│       ├── pages/
│       └── design_system/
├── firestore.rules         # Firestore security rules
├── firestore.indexes.json  # Firestore indexes
├── storage.rules           # Storage security rules
├── firebase.json           # Firebase configuration
├── pubspec.yaml           # Flutter dependencies
└── README.md              # This file
```

##  Firebase Functions

The project includes Cloud Functions for:

### Appointment Reminders
- **Function**: `sendAppointmentReminders`
- **Schedule**: Runs daily to send reminders for upcoming appointments
- **Trigger**: Scheduled (Firebase Cloud Scheduler)

### Deploy Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

##  Available Scripts

### Flutter Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run tests
flutter test

# Format code
flutter format .

# Analyze code
flutter analyze

# Clean build
flutter clean

# Build APK
flutter build apk --release

# Build Web
flutter build web --release
```

### Firebase Commands

```bash
# Login to Firebase
firebase login

# Select project
firebase use <project-id>

# Deploy all
firebase deploy

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only Functions
firebase deploy --only functions

# View logs
firebase functions:log
```

##  Troubleshooting

### Common Issues

1. **"Firestore permission denied" error**
   - Make sure you've deployed Firestore rules: `firebase deploy --only firestore:rules`
   - Check that the user is authenticated
   - Verify the rules in `firestore.rules` match your use case

2. **"Google Services" configuration error**
   - Ensure `google-services.json` (Android) is in `android/app/`
   - Ensure `GoogleService-Info.plist` (iOS) is in `ios/Runner/`
   - Run `flutterfire configure` to regenerate config

3. **Build errors on iOS**
   - Run `cd ios && pod install && cd ..`
   - Clean build: `flutter clean && flutter pub get`
   - Update CocoaPods: `sudo gem install cocoapods`

4. **Flutter not recognized**
   - Add Flutter to PATH
   - Restart terminal/IDE

5. **Firebase Functions deployment fails**
   - Check Node.js version: `node --version` (should be 16+)
   - Install dependencies: `cd functions && npm install`
   - Build TypeScript: `npm run build`

### Getting Help

- Flutter Documentation: https://docs.flutter.dev/
- Firebase Documentation: https://firebase.google.com/docs
- FlutterFire Documentation: https://firebase.flutter.dev/

##  Security Rules

The application uses Firebase Security Rules to protect data:

- **Firestore Rules**: See `firestore.rules`
- **Storage Rules**: See `storage.rules`

Make sure to review and customize these rules for production use.

##  Supported Platforms

- ✅ Android (6.0+)
- ✅ iOS (12.0+)
- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Windows (Windows 10+)
- ✅ macOS (10.14+)
- ✅ Linux

##  Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

##  License

This project is licensed under the MIT License - see the LICENSE file for details.

##  Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All open-source contributors

---

**Built with ❤️ using Flutter and Firebase**
