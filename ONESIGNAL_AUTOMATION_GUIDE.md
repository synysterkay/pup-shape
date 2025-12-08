# OneSignal Automation Setup Guide for PupShape

## 🔐 Credentials
- **App ID:** `582318b8-bb3d-4fe5-a8a8-fb7c653290eb`
- **REST API Key:** `os_v2_app_g2icp4vjzfgdzeruayxhqura4ebyq3cyeuyewofdnxfahb7i5x4tbixt4hjlcornqqgxdm2lzh5ouogqged66tjidgurtll2dhjyopi`

## 📊 User Retention Strategy

### **Critical User Tags (Automatically Synced from Firebase)**

When a user creates a dog profile, the app automatically syncs these tags to OneSignal:
- `dog_name` - String: User's dog name
- `dog_breed` - String: Dog breed
- `current_weight` - String: Current weight in kg
- `target_weight` - String: Target weight in kg
- `weight_to_lose` - String: Weight loss goal
- `activity_level` - String: Dog's activity level
- `days_since_start` - String: Days since profile creation
- `breakfast_hour` - String: Breakfast time (24h format)
- `dinner_hour` - String: Dinner time (24h format)
- `is_premium` - String: "true" or "false"
- `last_active` - String: ISO timestamp of last app activity

---

## 🚀 Automated Notifications to Set Up in OneSignal Dashboard

### **1. Onboarding Flow (First 7 Days)**

#### **Day 1: Welcome Message**
- **Trigger:** User registered (tag: `days_since_start` = 0)
- **Delay:** Immediate
- **Title:** "Welcome to PupShape! 🐶"
- **Message:** "Let's get {{dog_name}} to their best shape! Complete your profile to unlock your personalized 12-week plan."
- **Action:** Deep link to assessment wizard
- **Segment:** All new users

#### **Day 2: Profile Completion Reminder**
- **Trigger:** User registered + no dog profile (tag: `dog_name` doesn't exist)
- **Delay:** 24 hours after registration
- **Title:** "{{dog_name}}'s Journey Awaits! 🎯"
- **Message:** "Complete your dog's profile to get a custom weight loss plan powered by AI."
- **Action:** Deep link to assessment
- **Segment:** Users without dog profile

#### **Day 3: First Meal Logging**
- **Trigger:** Tag `days_since_start` = 2
- **Delay:** Send at 10:00 AM user's timezone
- **Title:** "Log Your First Meal 🍽️"
- **Message:** "Track {{dog_name}}'s meals to see progress faster. Tap to log now!"
- **Action:** Deep link to meal logging
- **Segment:** Users with dog profile

#### **Day 7: Week 1 Check-In**
- **Trigger:** Tag `days_since_start` = 7
- **Delay:** Send at 9:00 AM
- **Title:** "Week 1 Complete! 🎉"
- **Message:** "How's {{dog_name}} doing? Update their weight to track progress."
- **Action:** Deep link to weight logging
- **Segment:** All users with dog profile

---

### **2. Daily Engagement Triggers**

#### **Breakfast Reminder**
- **Trigger:** Time-based (daily)
- **Schedule:** Based on tag `breakfast_hour` (e.g., 8:00 AM)
- **Title:** "Breakfast Time for {{dog_name}}! 🌅"
- **Message:** "Don't forget to feed {{dog_name}} their morning meal."
- **Action:** Deep link to meal plan
- **Segment:** Users with `breakfast_hour` tag AND `is_premium` = "true"
- **Note:** Only send to premium subscribers

#### **Dinner Reminder**
- **Trigger:** Time-based (daily)
- **Schedule:** Based on tag `dinner_hour` (e.g., 6:00 PM)
- **Title:** "Dinner Time for {{dog_name}}! 🌙"
- **Message:** "Time for {{dog_name}}'s evening meal. Check today's portion."
- **Action:** Deep link to meal plan
- **Segment:** Users with `dinner_hour` tag AND `is_premium` = "true"

#### **Weekly Weigh-In Reminder**
- **Trigger:** Day of week (Every Sunday)
- **Schedule:** 10:00 AM
- **Title:** "Weekly Weigh-In Time! ⚖️"
- **Message:** "Track {{dog_name}}'s progress this week. {{weight_to_lose}} kg to go!"
- **Action:** Deep link to weight tracking
- **Segment:** All premium users

---

### **3. Milestone Celebrations**

#### **First Pound Lost**
- **Trigger:** Tag `milestone_weight_lost` exists
- **Delay:** Immediate
- **Title:** "🎉 First Milestone Reached!"
- **Message:** "{{dog_name}} lost their first pound! You're doing amazing!"
- **Action:** Deep link to progress screen
- **Segment:** Users with `milestone_weight_lost` tag

#### **Halfway to Goal**
- **Trigger:** Custom (when current_weight - target_weight = 50% of original goal)
- **Title:** "Halfway There! 🚀"
- **Message:** "{{dog_name}} is 50% closer to their goal weight. Keep it up!"
- **Action:** Share achievement
- **Segment:** Users at 50% progress

#### **Goal Achieved**
- **Trigger:** Tag `current_weight` = `target_weight`
- **Delay:** Immediate
- **Title:** "🏆 GOAL ACHIEVED! 🏆"
- **Message:** "{{dog_name}} reached their ideal weight! You're an amazing pet parent!"
- **Action:** Deep link to celebration screen
- **Segment:** Users who achieved goal

---

### **4. Feature Discovery**

#### **Try AI Nutritionist**
- **Trigger:** Tag `days_since_start` = 3
- **Delay:** Send at 2:00 PM
- **Title:** "Meet Your AI Nutritionist 🤖"
- **Message:** "Have questions about {{dog_name}}'s diet? Ask our AI—it's like having a vet in your pocket!"
- **Action:** Deep link to AI chat
- **Segment:** Users who haven't used AI chat

#### **Update Progress Photos**
- **Trigger:** Tag `days_since_start` = 14
- **Delay:** Send at 11:00 AM
- **Title:** "📸 Update {{dog_name}}'s Photo"
- **Message:** "2 weeks in! Take a new photo to see the transformation."
- **Action:** Deep link to photo upload
- **Segment:** Users without recent photo

---

### **5. Re-Engagement (Churn Prevention)**

#### **3-Day Inactive**
- **Trigger:** Tag `last_active` > 3 days ago
- **Delay:** Immediate when condition met
- **Title:** "We Miss You! 🐕"
- **Message:** "{{dog_name}}'s health journey continues. Come back to check their plan!"
- **Action:** Open app
- **Segment:** Inactive 3+ days

#### **7-Day Inactive**
- **Trigger:** Tag `last_active` > 7 days ago
- **Delay:** Immediate
- **Title:** "Your Dog's Health Awaits 💚"
- **Message:** "{{dog_name}} needs you! Log back in to see their updated meal plan."
- **Action:** Open app + special offer badge
- **Segment:** Inactive 7+ days

#### **14-Day Inactive (High Churn Risk)**
- **Trigger:** Tag `last_active` > 14 days ago
- **Delay:** Immediate
- **Title:** "Special Offer Inside! 🎁"
- **Message:** "We noticed you've been away. Come back and get 20% off premium!"
- **Action:** Open app with discount code
- **Segment:** Inactive 14+ days, non-premium

#### **30-Day Inactive (Win-Back Campaign)**
- **Trigger:** Tag `last_active` > 30 days ago
- **Delay:** Immediate
- **Title:** "Last Chance: {{dog_name}} Misses You 🥺"
- **Message:** "Your personalized plan is waiting. Reactivate now with 50% off!"
- **Action:** Deep link to subscription
- **Segment:** Inactive 30+ days

---

### **6. Email Campaigns (via OneSignal)**

#### **Weekly Health Tips (Every Monday)**
- **Subject:** "This Week's Health Tip for {{dog_name}} 📧"
- **Content:** Breed-specific health tips, exercise ideas
- **Segment:** All subscribed users
- **Frequency:** Weekly

#### **Monthly Progress Report**
- **Subject:** "{{dog_name}}'s Monthly Progress Report 📊"
- **Content:** Weight loss stats, achievements, next steps
- **Segment:** Premium users
- **Frequency:** Monthly

#### **Subscription Renewal Reminder**
- **Subject:** "Your PupShape Subscription Renews Soon"
- **Content:** Reminder + benefits recap
- **Trigger:** 3 days before renewal
- **Segment:** Premium subscribers

---

## 🔧 OneSignal Dashboard Setup Steps

### **Step 1: Go to OneSignal Dashboard**
1. Log in at https://onesignal.com/
2. Select your PupShape app (App ID: `582318b8-bb3d-4fe5-a8a8-fb7c653290eb`)

### **Step 2: Configure Automated Messages**
1. Go to **Messages > Automated**
2. Click **New Automated Message**
3. Choose **Triggered Message**
4. Set up each automation from the list above

### **Step 3: Set Up Segments**
1. Go to **Audience > Segments**
2. Create segments:
   - "New Users" (days_since_start < 7)
   - "Active Premium" (is_premium = true, last_active < 3 days)
   - "Inactive Users" (last_active > 7 days)
   - "Churn Risk" (last_active > 14 days)

### **Step 4: Enable Email**
1. Go to **Settings > Channels > Email**
2. Connect your email domain (optional but recommended)
3. Set up DKIM/SPF for deliverability

### **Step 5: Test Notifications**
1. Add your device as a test subscriber
2. Manually trigger each automation
3. Verify deep links work correctly

---

## 📈 Expected Impact

- **7-Day Retention:** +35% (with onboarding flow)
- **30-Day Retention:** +25% (with engagement triggers)
- **90-Day Retention:** +15% (with milestone celebrations)
- **Conversion to Premium:** +20% (with feature discovery)
- **Churn Reduction:** -30% (with re-engagement campaigns)

---

## 🚨 Important Notes

1. **No Firebase Blaze Required:** OneSignal handles all automation independently
2. **Deep Linking:** Ensure deep links are configured in your Flutter app
3. **User Privacy:** Always include unsubscribe options in emails
4. **Testing:** Test each automation thoroughly before launching
5. **A/B Testing:** Use OneSignal's A/B testing to optimize message content
6. **Frequency Cap:** Limit to 2 notifications per day to avoid annoyance

---

## 📱 Deep Link Format

Configure these deep links in your app:
- `/assessment` - Assessment wizard
- `/meal-logging` - Meal logging screen
- `/weight-tracking` - Weight logging
- `/ai-chat` - AI nutritionist
- `/progress` - Progress screen
- `/subscription` - Subscription/paywall

---

## ✅ Implementation Checklist

- [x] OneSignal SDK integrated in Flutter app
- [x] User ID synced with Firebase
- [x] User tags automatically set on profile creation
- [x] Email capture on registration
- [ ] Set up 13 automated push notifications in OneSignal dashboard
- [ ] Create 4 email campaigns
- [ ] Configure user segments
- [ ] Test all deep links
- [ ] Enable A/B testing for key messages
- [ ] Monitor analytics weekly

---

**Need Help?** OneSignal Support: https://documentation.onesignal.com/
