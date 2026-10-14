# Tel Khata – Google Play Store Listing

## 1. Main store listing

**App name** (max 30)
Tel Khata: Fuel & Mileage Log

**Short description** (max 80)
Track fuel, mileage, expenses and oil changes for your car, bike or CNG.

**Full description** (max 4000)

Tel Khata is a simple, beautiful fuel log for every vehicle you own. Log each fill-up, see your real mileage and keep every vehicle cost in one place. It works fully offline.

KNOW YOUR REAL MILEAGE
• Accurate mileage using the full-tank method
• Average, last and best mileage on your dashboard
• Mileage trend chart over time
• Each fill-up shows green when better than your average and red when worse

LOG FUEL IN SECONDS
• Enter the odometer reading or just the trip meter. Tel Khata works out the total odometer for you
• Enter fuel and price and the total cost fills in automatically
• Mark partial fill-ups or a missed fill-up so your mileage stays correct

NEVER MISS AN ENGINE OIL CHANGE
• Save the oil brand, grade and run capacity at every oil change
• A ring gauge shows how many km are left before the next change
• The dashboard turns amber when it is due soon and red when overdue

TRACK EVERY EXPENSE
• Service, repairs, tyres, insurance, tax and fitness, parking, tolls, wash and more
• See where your money goes with clear spending bars
• Monthly spend chart for fuel and other costs
• Cost per km for fuel and total running cost

ALL YOUR VEHICLES IN ONE APP
• Cars, bikes, CNG, pickups and more
• Octane, petrol, diesel, CNG, LPG and electric
• Switch vehicles with one tap

YOUR UNITS, YOUR CURRENCY
• Kilometres or miles
• Liters or gallons
• Taka (৳) and many other currencies

PRIVATE AND OFFLINE
• No account or sign-up needed
• Your data stays on your phone
• No ads

Fill up, log it, and know exactly what your vehicle costs you. Download Tel Khata today.

---

## 2. Graphics (files included)

| Asset | File | Size |
|---|---|---|
| App icon | `app_icon_512.png` | 512 x 512 PNG |
| Feature graphic | `feature_graphic_1024x500.png` | 1024 x 500 PNG |
| Phone screenshots (upload in this order) | `screenshot_01_dashboard.png` to `screenshot_06_vehicles.png` | 1080 x 1920 PNG |

Screenshot captions used:
1. Know your real mileage
2. Spot good and bad fill-ups
3. Log fuel in seconds
4. Never miss an oil change
5. Track every taka
6. All your vehicles in one app

Note: the screenshots show the app's real screens and features with sample data. Google requires screenshots to reflect the actual app, so swap in real captures if the app UI changes.

---

## 3. Store settings

- **App or game:** App
- **Category:** Auto & Vehicles
- **Tags:** Fuel tracker, Mileage, Car maintenance, Expense tracker, Vehicle log
- **Free or paid:** Free
- **Contains ads:** No
- **In-app purchases:** No
- **Developer name:** Appinion BD Ltd.
- **Contact email:** [Appinion BD Ltd. support email]
- **Website:** (optional) https://appinionbd.com
- **Privacy policy URL:** https://appinionrahul-boop.github.io/tel-khata/privacy-policy.html

---

## 4. App content (Policy section in Play Console)

**App access:** All functionality is available without special access (no login).

**Ads:** No, the app does not contain ads.

**Content rating questionnaire:** Category "Utility, Productivity, Communication or Other". Answer "No" to violence, sexual content, language, controlled substances, gambling, user interaction, sharing location and personal info. Expected rating: Everyone / PEGI 3.

**Target audience:** 18 and over. Keeps the app outside the Families policy.

**News app:** No.

**Data safety form:**
- Does your app collect or share any of the required user data types? **No**
- All data (vehicles, fill-ups, expenses, settings) is stored only on the device.
- No data is sent off the device, so nothing is collected or shared.

If you turn on cloud sync later (Firebase), update this form: mark vehicle and expense data as collected for App functionality, encrypted in transit, and deletable on request.

**Government app / Financial features / Health:** No.

---

## 5. Privacy policy

Live page: https://appinionrahul-boop.github.io/tel-khata/privacy-policy.html (source: `docs/privacy-policy.html`)

**Privacy Policy for Tel Khata**
Last updated: [date]

Tel Khata ("the app") is developed by Appinion BD Ltd. This policy explains how the app handles your information.

**Information we collect**
We do not collect any personal information. The data you enter in the app, such as vehicles, fuel fill-ups, expenses, engine oil records and settings, is stored only on your device.

**How your data is used**
Your data is used only inside the app to calculate mileage, show statistics and send in-app reminders. It is not sent to us or to any third party.

**Sharing**
We do not sell, trade or share your data with anyone.

**Third-party services**
The app does not include advertising, analytics or tracking services.

**Data deletion**
You can delete any entry or vehicle inside the app. Uninstalling the app removes all of its data from your device.

**Children**
The app is not directed at children under 13 and does not knowingly collect information from them.

**Changes**
If we change this policy, we will update this page and the "Last updated" date.

**Contact**
Appinion BD Ltd.
Gulshan 1, Dhaka, Bangladesh
Website: https://appinionbd.com

---

## 6. Release notes (version 1.0.0)

First release of Tel Khata:
• Fuel log with mileage, using the full-tank method
• Odometer or trip meter entry
• Engine oil change reminders
• Expense tracking with spending charts
• Multiple vehicles, units and currencies
• Works fully offline

---

## 7. Before you upload (checklist)

1. **Package name** is `com.appinion.fuel_log`. It can never be changed after the first upload.
2. **Set the version** in `pubspec.yaml`, for example `version: 1.0.0+1`.
3. **Create an upload keystore** and set up signing in `android/app/build.gradle` with a `key.properties` file. Do not commit the keystore or `key.properties` to GitHub.
4. **Build the bundle:** `flutter build appbundle --release`, then upload `build/app/outputs/bundle/release/app-release.aab`.
5. **Run a closed test first.** New personal developer accounts must run a closed test with at least 12 testers for 14 days before production access.
