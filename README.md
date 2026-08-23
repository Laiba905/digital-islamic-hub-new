# 🌙 Digital Islamic Hub

A professional and feature-rich Islamic application built with Flutter, designed to provide a seamless spiritual experience. This app integrates real-time prayer calculations, an offline Quran database, and a comprehensive Hadith library.

## 🚀 Completely Implemented Features

### 📖 Al-Quran (Full Offline Access)
- **Surah Index**: Complete list of all 114 Surahs with Makki/Madni classification.
- **Advanced Reader**: High-quality Arabic text with Urdu and English translations.
- **Tafseer**: Integrated Urdu and English commentary for every Ayah.
- **Smart Search**: Quickly find Surahs by their name or number.

### 🕋 Prayer Times & Azan Alerts
- **Real-time Calculation**: Precise timings for all 5 prayers + Sunrise using the `adhan` package.
- **Location Integration**: Automatically fetches user coordinates for accurate local timings.
- **Azan Notifications**: Fully functional notification system that plays Azan at prayer times.
- **Customizable Alerts**: Enable or disable notifications for specific prayer times.

### 📚 Hadith Library
- **Multiple Collections**: Browse authentic Hadith collections like Sunan Abu Dawud and Jami at-Tirmidhi.
- **Categorized View**: Hadiths organized by chapters and books for easy navigation.
- **Dynamic Loading**: Efficiently loads Hadiths from the local SQLite database.

### 📿 Digital Tasbeeh Counter
- **Custom Zikars**: Users can add, edit, and manage their own Zikar list with target goals.
- **Haptic Feedback**: Vibration on each tap and a distinct long vibration upon reaching the target goal.
- **Persistence**: Counts and Zikars are saved locally and persist even after the app is closed.

### 🏠 Smart Dashboard
- **Ayah of the Day**: Automatically fetches and displays a new Ayah (Arabic + Urdu) every day from the local database.
- **Hijri Calendar**: Real-time Islamic date display using the `hijri` calendar system.
- **Prayer Overview**: High-level view of the current and upcoming prayer times with intuitive UI.

### 🛡️ Authentication & Profile
- **Firebase Auth**: Secure Login and Signup system.
- **User Profile**: Personalized dashboard with user-specific greetings and profile image support via Cloud Firestore.

### 📜 Safar Dua
- **Travel Supplications**: Quick access to essential Duas for traveling.

## 🛠️ Technology Stack

- **Framework**: Flutter (Dart)
- **Local Database**: SQLite (`sqflite`) for lightning-fast offline access to Quran & Hadith data.
- **Backend**: Firebase Authentication & Cloud Firestore.
- **APIs & Libraries**:
  - `adhan`: For precise prayer time algorithms.
  - `flutter_local_notifications`: For scheduling Azan alerts.
  - `geolocator`: GPS-based prayer accuracy.
  - `vibration`: Haptic feedback for Tasbeeh.
  - `intl`: Date and time formatting.
  - `animate_do`: Professional UI animations.

## 📦 Installation & Setup

1. **Clone the project**:
   ```bash
   git clone https://github.com/Laiba905/digital-islamic-hub-new.git
   ```

2. **Install Packages**:
   ```bash
   flutter pub get
   ```

3. **Database Setup**:
   Ensure `quran_final_authentic_v2.db` and `hadith_database.db` are present in `assets/database/`.

4. **Notification Sound**:
   Place your `azan.mp3` in `android/app/src/main/res/raw/` for the alerts to work.

5. **Run the App**:
   ```bash
   flutter run
   ```

---
Developed with ❤️ by **Laiba**
