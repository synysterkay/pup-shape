# 🐕 PupShape - AI-Powered Dog Weight Management

[![Codemagic build status](https://api.codemagic.io/apps/YOUR_APP_ID/YOUR_WORKFLOW_ID/status_badge.svg)](https://codemagic.io/apps/YOUR_APP_ID/YOUR_WORKFLOW_ID/latest_build)

**Transform your dog's health with personalized AI-driven nutrition and weight loss plans.**

---

## 📱 About

PupShape is a comprehensive Flutter mobile application that helps dog owners manage their pet's weight through:

- 🤖 **AI-Powered 12-Week Plans**: Personalized weight loss journeys tailored to breed, age, and activity level
- 🍽️ **Daily Meal Planning**: Exact portion sizes and nutritional guidance
- 📊 **Progress Tracking**: Weight logs, photo comparisons, and milestone celebrations
- 💬 **24/7 AI Nutritionist**: Instant answers to food and health questions
- 📲 **Smart Notifications**: Automated reminders and engagement campaigns via OneSignal

---

## 🚀 Features

### Core Features
- **Assessment Wizard**: Multi-step onboarding to capture dog profile
- **Meal Logging**: Track daily meals and portions
- **Weight Tracking**: Monitor progress with charts and analytics
- **AI Chat**: DeepSeek-powered nutritionist for instant advice
- **Superwall Integration**: Premium subscription management

### Technical Stack
- **Framework**: Flutter 3.39.0-0.1.pre (Dart 3.11.0)
- **Backend**: Firebase (Auth, Firestore, Storage)
- **AI**: DeepSeek API for meal plans and chat
- **Notifications**: OneSignal + Flutter Local Notifications
- **Subscriptions**: Superwall SDK
- **State Management**: Provider
- **Platforms**: iOS & Android

---

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK 3.39.0+ 
- Dart 3.11.0+
- Xcode 15+ (for iOS)
- Android Studio / Gradle 8.11.1+ (for Android)
- Firebase Project
- OneSignal Account
- Superwall Account

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/synysterkay/pup-shape.git
   cd pup-shape
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   ```

3. **Configure Firebase**
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`

4. **Set up environment variables**
   Create `.env` file:
   ```
   ONESIGNAL_APP_ID=582318b8-bb3d-4fe5-a8a8-fb7c653290eb
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📦 Building

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS IPA
```bash
flutter build ipa --release --export-options-plist=ExportOptions.plist
```

---

## 🔧 CI/CD - Codemagic

This project uses Codemagic for automated builds and deployments.

### Workflows
- **`ios-workflow`**: Builds and publishes iOS app to TestFlight
- **`android-workflow`**: Builds and publishes Android app to Play Store (Internal Track)

### Required Environment Variables in Codemagic
- `ONESIGNAL_APP_ID`: OneSignal App ID
- `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`: Google Play Store credentials
- Firebase config files must be committed (google-services.json, GoogleService-Info.plist)

### App Store Connect Integration
- Ensure App Store Connect API key is configured in Codemagic
- Bundle ID: `com.mealplanner.foodofdogs.petmeal`

---

## 📱 App Store Information

### Bundle Identifiers
- **iOS**: `com.mealplanner.foodofdogs.petmeal`
- **Android**: `com.mealplanner.foodofdogs.petmeal`

### Current Version
- **Version**: 3.0.0
- **Build Number**: 3

### Categories
- **Primary**: Lifestyle
- **Secondary**: Health & Fitness

### Keywords (iOS - 100 chars)
```
dog,diet,weight,loss,pet,nutrition,food,health,vet,puppy,tracker,meal,plan,ai,breed,calculator
```

---

## 🔔 Push Notifications (OneSignal)

### Configuration
- **App ID**: `582318b8-bb3d-4fe5-a8a8-fb7c653290eb`
- **REST API Key**: (Stored securely - see `ONESIGNAL_AUTOMATION_GUIDE.md`)

### Automated Campaigns
- Onboarding flow (Days 1-7)
- Daily meal reminders
- Weekly weigh-in prompts
- Milestone celebrations
- Re-engagement for inactive users

See [`ONESIGNAL_AUTOMATION_GUIDE.md`](ONESIGNAL_AUTOMATION_GUIDE.md) for complete setup instructions.

---

## 🔐 Security & Privacy

- **Authentication**: Firebase Auth (Email/Password, Google Sign-In on Android only)
- **Data Storage**: Firestore with user-level security rules
- **API Keys**: Stored in environment variables (never committed)
- **Privacy Policy**: Required for App Store/Play Store submission

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/
│   └── theme.dart              # App-wide theming
├── models/
│   ├── dog.dart                # Dog profile model
│   ├── meal.dart               # Meal data model
│   └── plan.dart               # Weight loss plan model
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   ├── dog_provider.dart       # Dog profiles management
│   ├── meal_provider.dart      # Meal logging
│   └── plan_provider.dart      # Plan generation
├── screens/
│   ├── auth/                   # Login/signup screens
│   ├── assessment/             # Dog profile wizard
│   ├── home/                   # Dashboard
│   ├── meals/                  # Meal suggestions
│   ├── progress/               # Weight tracking
│   └── start/                  # Welcome screen
├── services/
│   ├── deepseek_service.dart   # AI integration
│   ├── notification_service.dart
│   └── onesignal_service.dart  # Push notifications
└── widgets/                    # Reusable UI components
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

---

## 📄 Documentation

- [`FEATURES_IMPLEMENTED.md`](FEATURES_IMPLEMENTED.md) - Complete feature list
- [`NAVIGATION_FLOW.md`](NAVIGATION_FLOW.md) - App navigation structure
- [`ONESIGNAL_AUTOMATION_GUIDE.md`](ONESIGNAL_AUTOMATION_GUIDE.md) - Push notification setup

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📧 Contact

**Developer**: Anas Kay  
**Email**: anaskay.13@gmail.com  
**GitHub**: [@synysterkay](https://github.com/synysterkay)

---

## 📝 License

This project is proprietary software. All rights reserved.

---

## 🎯 Roadmap

### Version 3.1
- [ ] Social sharing features
- [ ] Community forum
- [ ] Vet integration
- [ ] Recipe library expansion

### Version 3.2
- [ ] Apple Watch app
- [ ] Widget support
- [ ] Multi-dog profiles
- [ ] Voice commands

---

**Made with ❤️ for dogs and their humans**
