# SafeGuardSG 🚨

# 📲 Flutter Mobile App Project

## 🌟 Getting Started

### Prerequisites
- **Flutter SDK** ([Install Guide](https://flutter.dev/docs/get-started/install)) (v3.19.5 or newer)
- **Android Studio** ([Download](https://developer.android.com/studio)) (for emulator)
- **VS Code** (Recommended) ([Download](https://code.visualstudio.com/))
- **Git** ([Download](https://git-scm.com/))

---

## 🛠 Installation Guide

### 1. Install Flutter
```bash
# Clone Flutter repository
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (Windows)
setx PATH "%PATH%;C:\src\flutter\bin"

# Add to PATH (Mac/Linux)
cd flutter
export PATH="$PWD/bin:$PATH"
echo 'export PATH="$HOME/safe_guard_sg/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
flutter doctor
```

---

### 2. Clone the SafeGuardSG Repository
```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/safe_guard_sg.git
cd safe_guard_sg
```

### 3. Install Dependencies
```bash
flutter pub get
```

---

## 🌟 Running the Project


### Run on Connected Device
```bash
flutter run --release
```

### Setting Up an Emulator
#### Using Android Studio Emulator
1. Open **Android Studio** → **Device Manager**.
2. Click **Create Device** and select a phone model.
3. Download and install a **system image** (preferably API 30 or higher).
4. Click **Finish**, then start the emulator.

#### Using Flutter Emulators (CLI)
```bash
# List available emulators
flutter emulators

# Launch a specific emulator
flutter emulators --launch <emulator_id>

# Run on the active emulator
flutter run
```

#### Run on Web or Desktop (If Supported)
```bash
flutter run -d chrome   # For Web
flutter run -d windows  # For Windows
flutter run -d macos    # For macOS
```



---

## 🚀 Features
✅ **Real-Time Alerts** – Location-based emergency notifications 📢  
✅ **Predictive Analytics** – AI-powered risk prediction 🧠  
✅ **Gamified Reporting** – Verify incidents to earn points 🎮  
✅ **Multi-Language Support** – Accessible for all communities 🌍  
✅ **Cloud-Connected** – Hosted on Huawei Cloud ☁️  

---

## 👨‍💻 Contributors
- **Kong Tian Yu**  
- **Chiam Xun Yin**  
- **Low King Whey**  
- **Tan Yan Tat**  

---

## 📜 License
This project is licensed under the **MIT License**.
