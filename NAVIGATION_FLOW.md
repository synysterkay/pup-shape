# PupShape Navigation Flow

## ✅ Complete Navigation Map

All screens are properly connected with working navigation paths.

### App Flow

```
┌─────────────────┐
│  SplashScreen   │ (Initial entry point)
│   /splash       │
└────────┬────────┘
         │ 3 seconds delay
         ▼
┌─────────────────┐
│ OnboardingScreen│ (3 slides: Problem → Promise → Solution)
│  /onboarding    │
└────────┬────────┘
         │ "Get Started" button
         ▼
┌─────────────────┐
│   AuthScreen    │ (Sign In / Sign Up tabs)
│     /auth       │ • Email/Password (all platforms)
└────────┬────────┘ • Google Sign-In (Android only)
         │ After successful auth
         ▼
┌─────────────────┐
│ AssessmentWizard│ (4-step dog profile wizard)
│  /assessment    │ • Basic info (name, breed, age)
└────────┬────────┘ • Weight goals (current/target)
         │         • Activity level
         │         • AI plan generation (DeepSeek)
         │ After profile creation
         ▼
┌─────────────────┐
│ NewHomeScreen   │ (Main dashboard)
│     /home       │ • Calorie ring widget
└────────┬────────┘ • Quick actions (meal logging)
         │         • Weight progress chart
         │         • Dog selector dropdown
         │
         ├───────────────┐
         │               │
         ▼               ▼
┌─────────────┐   ┌──────────────┐
│ProfileScreen│   │SettingsScreen│
│  /profile   │   │  /settings   │
└─────────────┘   └──────────────┘
   • User info       • Notifications
   • Photo upload    • Appearance
   • Statistics      • Data & Privacy
   • Edit profile    • Support/About
                     • Sign Out → /auth
```

### Navigation Details

#### 1. **SplashScreen** → `/onboarding`
- **Type**: `pushReplacementNamed` (can't go back)
- **Trigger**: Automatic after 3 seconds
- **Animation**: Dog transformation (round → fit)

#### 2. **OnboardingScreen** → `/auth`
- **Type**: `pushReplacementNamed` (can't go back)
- **Trigger**: "Get Started" button on last slide
- **Features**: 3 swipeable slides with animations

#### 3. **AuthScreen** → `/assessment`
- **Type**: `pushReplacementNamed` (can't go back)
- **Triggers**:
  - Google Sign-In success (Android only)
  - Email Sign-In success
  - Email Sign-Up success
- **Validation**: 
  - Email regex pattern
  - Password: 8+ chars, uppercase, number, special char

#### 4. **AssessmentWizard** → `/home`
- **Type**: `pushReplacementNamed` (can't go back)
- **Trigger**: Complete all 4 steps
- **Process**:
  1. Collect dog info (name, breed, age, gender)
  2. Set weight goals (current: 5-100 kg, target: 5-100 kg)
  3. Choose activity level (sedentary, light, moderate, active, very active)
  4. Generate AI plan via DeepSeek API
- **Data Created**: Dog profile saved to Firestore and DogProvider

#### 5. **NewHomeScreen** → `/assessment`
- **Type**: `pushNamed` (can go back)
- **Trigger**: "Add Dog" button when no dogs exist
- **Purpose**: Create additional dog profiles

#### 6. **NewHomeScreen** → `/profile`
- **Type**: `pushNamed` (can go back)
- **Trigger**: Profile menu → "Profile" option
- **Features**:
  - View/edit user information
  - Upload profile photo
  - View account statistics

#### 7. **NewHomeScreen** → `/settings`
- **Type**: `pushNamed` (can go back)
- **Trigger**: Profile menu → "Settings" option
- **Features**:
  - Notification preferences
  - Theme selection
  - Data export
  - Account deletion

#### 8. **Settings/HomeScreen** → `/auth`
- **Type**: `pushReplacementNamed` (can't go back)
- **Trigger**: "Sign Out" action
- **Process**: Calls `AuthProvider.signOut()`, clears session

---

## ✅ Route Registry (main.dart)

All routes are registered in `MaterialApp.routes`:

```dart
routes: {
  '/splash': (context) => const SplashScreen(),           ✅ Working
  '/onboarding': (context) => const OnboardingScreen(),   ✅ Working
  '/auth': (context) => const AuthScreen(),               ✅ Working
  '/start': (context) => const StartScreen(),             ✅ Working
  '/assessment': (context) => const AssessmentWizard(),   ✅ Working
  '/home': (context) => const NewHomeScreen(),            ✅ Working
  '/calendar': (context) => const CalendarScreen(),       ✅ Working
  '/profile': (context) => const ProfileScreen(),         ✅ Working
  '/settings': (context) => const SettingsScreen(),       ✅ Working
  '/progress': (context) => const ProgressScreen(),       ✅ NEW
  '/weight-logging': (context) => const WeightLoggingScreen(), ✅ NEW
  '/meal-suggestions': (context) => const MealSuggestionsScreen(), ✅ NEW
  '/tip-history': (context) => const TipHistoryScreen(),  ✅ NEW
}
```

---

## ✅ Navigation Methods Used

### `pushReplacementNamed` (No Back Button)
Used for one-way transitions where users shouldn't return:
- Splash → Onboarding
- Onboarding → Auth
- Auth → Assessment (after successful login)
- Assessment → Home (after profile creation)
- Settings/Home → Auth (after sign out)

### `pushNamed` (Can Go Back)
Used for temporary navigation:
- Home → Profile
- Home → Settings
- Home → Assessment (add another dog)

---

## ✅ Data Flow Integration

### Providers Connected:
1. **AuthProvider**: Manages user authentication state
   - Used in: AuthScreen, ProfileScreen, SettingsScreen, NewHomeScreen
   
2. **DogProvider**: Manages dog profiles
   - Used in: AssessmentWizard, NewHomeScreen, SettingsScreen
   
3. **MealProvider**: Manages meal logging
   - Used in: NewHomeScreen (meal logging modal)

### Services Connected:
1. **DeepSeekService**: AI integration
   - Used in: AssessmentWizard (generates nutrition plans)
   
2. **NotificationService**: Push notifications
   - Used in: SettingsScreen (notification preferences)

---

## 🔧 Fixed Issues

### Before Fix:
❌ Profile/Settings used old package name `cal_dogs_ai`
❌ Settings tried to navigate to non-existent `/login` route
❌ Profile/Settings not registered in main.dart routes
❌ Home screen had TODO placeholders for navigation

### After Fix:
✅ All imports updated to `pupshape` package
✅ Settings navigates to `/auth` route
✅ Profile/Settings routes registered in main.dart
✅ Home screen profile menu fully connected

---

## 📱 Navigation Testing Checklist

- [x] Splash screen auto-navigates after 3 seconds
- [x] Onboarding swipes through 3 slides
- [x] "Get Started" button navigates to auth
- [x] Email sign-in navigates to assessment
- [x] Google sign-in navigates to assessment (Android)
- [x] Assessment wizard creates dog and navigates to home
- [x] Home screen shows "Add Dog" when no dogs exist
- [x] "Add Dog" button navigates to assessment
- [x] Profile menu opens bottom sheet
- [x] Profile menu → "Profile" navigates to /profile
- [x] Profile menu → "Settings" navigates to /settings
- [x] Profile menu → "Sign Out" signs out and navigates to /auth
- [x] Back button works from Profile to Home
- [x] Back button works from Settings to Home
- [x] No compilation errors (`flutter analyze` passes)

---

## 🎯 All Screens Are Accessible

### Core Screens
Every screen in the app can be reached through proper navigation:

1. ✅ **SplashScreen** - App entry point
2. ✅ **OnboardingScreen** - From splash (auto after 3s)
3. ✅ **AuthScreen** - From onboarding or sign out
4. ✅ **StartScreen** - Navigation screen
5. ✅ **AssessmentWizard** - From auth or "Add Dog" button
6. ✅ **NewHomeScreen** - From assessment completion (Main Hub)
7. ✅ **CalendarScreen** - From home "Plan" quick action
8. ✅ **ProfileScreen** - From home profile menu
9. ✅ **SettingsScreen** - From home profile menu

### 🆕 New Feature Screens (December 2025)

10. ✅ **ProgressScreen** - From home "Progress" quick action button
    - **Features**: Weight chart, milestones, streak counter
    - **Access Path**: Home → Progress button (Row 2, Left)
    - **FAB**: "Log Weight" → WeightLoggingScreen

11. ✅ **WeightLoggingScreen** - From Progress FAB or route `/weight-logging`
    - **Features**: Weight entry, body condition score, notes
    - **Access Path**: Progress → FAB "Log Weight"
    - **Returns to**: Progress screen after save

12. ✅ **MealSuggestionsScreen** - From home "Recipes" quick action button
    - **Features**: 3 tabs (Recipe Ideas, Shopping List, Portion Guide)
    - **Access Path**: Home → Recipes button (Row 2, Right)
    - **Navigation**: Tab controller for internal navigation

13. ✅ **TipHistoryScreen** - From Daily Tip Card history icon
    - **Features**: View all past daily tips by category
    - **Access Path**: Home → Daily Tip Card → History Icon
    - **Returns to**: Home screen

### 📍 Quick Access Map from Home Screen

```
┌─────────────────────────────────────────┐
│         NEW HOME SCREEN (Hub)           │
├─────────────────────────────────────────┤
│  📝 Daily Tip Card (with history icon)  │ → TipHistoryScreen
├─────────────────────────────────────────┤
│  Quick Actions Row 1:                   │
│  [🍳 Breakfast] [🍽️ Dinner] [🍪 Treat]  │ → Meal Logging Modal
├─────────────────────────────────────────┤
│  Quick Actions Row 2:                   │
│  [📊 Progress] [📅 Plan] [🍖 Recipes]   │ → New Screens
├─────────────────────────────────────────┤
│  📈 Weight Progress Chart                │
│  🍽️ Today's Meals List                   │
│  FAB: ➕ Log Meal                        │
└─────────────────────────────────────────┘
```

### Navigation Paths to New Features

#### Path to Progress Tracking:
```
Home → Progress Button → ProgressScreen
  ├─ View weight chart (fl_chart)
  ├─ See current streak (🔥 X days)
  ├─ View milestones achieved
  └─ FAB → WeightLoggingScreen
      ├─ Enter weight (kg)
      ├─ Body condition score (1-9)
      ├─ Add notes
      └─ Save → Returns to Progress
```

#### Path to Meal Suggestions:
```
Home → Recipes Button → MealSuggestionsScreen
  ├─ Tab 1: Recipe Ideas (AI-generated)
  │   └─ View meal cards with ingredients
  ├─ Tab 2: Shopping List Generator
  │   └─ Generate weekly shopping list
  └─ Tab 3: Portion Guide
      └─ Visual portion comparisons
```

#### Path to Tip History:
```
Home → Daily Tip Card → History Icon → TipHistoryScreen
  └─ Chronological list of all tips
      ├─ Categorized (motivation, nutrition, etc.)
      ├─ Date stamps
      └─ Tap to view full tip
```

#### Path to Calendar/Plan:
```
Home → Plan Button → CalendarScreen
  ├─ View weekly meal calendar
  ├─ Select day to see meal plan
  ├─ Track daily calorie targets
  └─ (Future: Add day notes)
```

**Status**: 🟢 All 13 screens verified and fully accessible!

### 🔗 Navigation Testing Results

✅ All new routes registered in `main.dart`
✅ All imports correct and compiling
✅ Quick action buttons functional
✅ Back navigation works on all screens
✅ FABs navigate to correct screens
✅ Tab navigation works (MealSuggestionsScreen)
✅ Modal navigation works (Daily Tip detail)
✅ Deep navigation paths tested (Home → Progress → Weight Logging)

**Last Updated**: December 2, 2025
