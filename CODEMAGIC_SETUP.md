# 🚀 Codemagic Setup Guide for PupShape

## ✅ Repository Successfully Uploaded!

Your PupShape app is now on GitHub: **https://github.com/synysterkay/pup-shape**

---

## 📋 Next Steps: Configure Codemagic

### 1. **Connect Repository to Codemagic**

1. Go to [Codemagic Dashboard](https://codemagic.io/apps)
2. Click **Add application**
3. Select **GitHub** and authorize Codemagic
4. Choose the **synysterkay/pup-shape** repository
5. Select **Flutter** as the project type

### 2. **Configure Environment Variables**

Go to **App Settings > Environment variables** and add:

#### **Android Workflow Variables**
| Variable Name | Value | Group |
|--------------|-------|-------|
| `ONESIGNAL_APP_ID` | `582318b8-bb3d-4fe5-a8a8-fb7c653290eb` | Default |
| `PACKAGE_NAME` | `com.mealplanner.foodofdogs.petmeal` | Default |

#### **iOS Workflow Variables**
| Variable Name | Value | Group |
|--------------|-------|-------|
| `ONESIGNAL_APP_ID` | `582318b8-bb3d-4fe5-a8a8-fb7c653290eb` | Default |
| `XCODE_WORKSPACE` | `ios/Runner.xcworkspace` | Default |
| `XCODE_SCHEME` | `Runner` | Default |

---

### 3. **Configure Code Signing**

#### **For iOS (App Store Connect)**

1. Go to **Teams > Personal Account > Integrations**
2. Click **App Store Connect**
3. Add your **App Store Connect API Key**:
   - **Issuer ID**: (from App Store Connect > Users & Access > Keys)
   - **Key ID**: (from your API key)
   - **API Key file**: Upload `.p8` file
4. Save as integration name: `codemagic`

#### **For Android (Google Play)**

1. Go to **Teams > Personal Account > Integrations**
2. Click **Google Play**
3. Upload your **service account JSON** file:
   - Go to Google Cloud Console
   - Create service account for Play Store
   - Download JSON key
   - Upload to Codemagic
4. Save credentials

#### **Android Keystore**

1. Go to **App Settings > Code signing**
2. Under **Android**, click **Upload keystore**
3. Upload your keystore file (`.jks` or `.keystore`)
4. Add keystore details:
   - **Keystore password**
   - **Key alias**
   - **Key password**
5. Save as reference: `keystore_reference`

---

### 4. **Enable Workflows**

The `codemagic.yaml` file in your repo defines two workflows:

#### **iOS Workflow** (`ios-workflow`)
- **Triggers**: Push to `main`, `develop`, or `release/*` branches
- **Builds**: iOS IPA for App Store
- **Publishes**: TestFlight (beta testing)
- **Notifications**: Email to `anaskay.13@gmail.com`

#### **Android Workflow** (`android-workflow`)
- **Triggers**: Push to `main`, `develop`, or `release/*` branches
- **Builds**: APK + App Bundle (AAB)
- **Publishes**: Google Play Internal Track (draft)
- **Notifications**: Email to `anaskay.13@gmail.com`

To enable:
1. Go to **App Settings > Workflow settings**
2. Ensure **codemagic.yaml** is detected
3. Both workflows should appear automatically

---

### 5. **First Build Test**

1. Go to **Builds** tab
2. Click **Start new build**
3. Select workflow: `android-workflow` (easier to test first)
4. Select branch: `main`
5. Click **Start new build**

**Expected Result:**
- ✅ Build completes successfully (~15-20 minutes)
- ✅ APK + AAB artifacts available for download
- ✅ Email notification sent

---

## 🔧 Troubleshooting Common Issues

### Issue: "GoogleService-Info.plist not found"
**Solution:** The file is already committed in `ios/Runner/GoogleService-Info.plist`. If missing, re-add from Firebase Console.

### Issue: "google-services.json not found"
**Solution:** The file is already committed in `android/app/google-services.json`. If missing, re-add from Firebase Console.

### Issue: "Code signing failed"
**Solution:** 
- Ensure App Store Connect integration is properly configured
- Check that Bundle ID matches: `com.mealplanner.foodofdogs.petmeal`
- Verify certificates are valid and not expired

### Issue: "Pod install fails"
**Solution:** The workflow includes `pod repo update` which should fix this. If persists:
- Check Podfile syntax
- Ensure all pods are compatible with current iOS version

### Issue: "Build timeout"
**Solution:**
- Default timeout is 120 minutes (should be enough)
- Check logs for stuck processes
- Ensure no infinite loops in code

---

## 📱 Testing the Built App

### Download Built APK/IPA:
1. Go to **Builds** tab
2. Click on completed build
3. Scroll to **Artifacts** section
4. Download:
   - **APK**: `build/app/outputs/flutter-apk/app-release.apk`
   - **AAB**: `build/app/outputs/bundle/release/app-release.aab`
   - **IPA**: `build/ios/ipa/Runner.ipa`

### Install on Device:
- **Android**: Use `adb install app-release.apk` or upload to Play Console
- **iOS**: Install via TestFlight link (sent after publish)

---

## 🎯 Next Steps After Successful Build

### For Android:
1. **Internal Testing**: Build publishes to Google Play Internal Track automatically
2. **Closed Testing**: Promote from Internal to Closed Testing in Play Console
3. **Production**: After testing, promote to Production

### For iOS:
1. **TestFlight**: Build publishes to TestFlight automatically
2. **Beta Testing**: Invite testers via App Store Connect
3. **App Store**: Submit for review when ready

---

## 📊 Monitoring Builds

### View Build Logs:
- Click on any build to see real-time logs
- Each script step shows detailed output
- Download logs for debugging

### Build Status Badge:
Add this to your README (after first build):
```markdown
[![Codemagic build status](https://api.codemagic.io/apps/YOUR_APP_ID/YOUR_WORKFLOW_ID/status_badge.svg)](https://codemagic.io/apps/YOUR_APP_ID/YOUR_WORKFLOW_ID/latest_build)
```

Replace `YOUR_APP_ID` and `YOUR_WORKFLOW_ID` from Codemagic URL.

---

## 🔐 Security Checklist

- ✅ GitHub repo is private (recommended for production apps)
- ✅ Firebase config files committed (required for build)
- ✅ API keys in environment variables (not in code)
- ✅ Keystore uploaded to Codemagic (secure storage)
- ✅ Personal access token not exposed in logs

---

## 📧 Support

**Codemagic Documentation**: https://docs.codemagic.io/  
**Flutter on Codemagic**: https://docs.codemagic.io/flutter-configuration/flutter-projects/  

**Your Contact**: anaskay.13@gmail.com  
**GitHub Repo**: https://github.com/synysterkay/pup-shape

---

## ✅ Summary Checklist

- [x] Code pushed to GitHub
- [x] codemagic.yaml configured
- [x] Firebase config files committed
- [x] OneSignal integrated
- [ ] Codemagic repository connected
- [ ] Environment variables configured
- [ ] Code signing set up (iOS + Android)
- [ ] First build successful
- [ ] App tested on device

**You're ready to build! 🚀**
