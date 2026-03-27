# 🏠 EzzeMessManage 🛠️

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![ObjectBox](https://img.shields.io/badge/ObjectBox-Fast_NoSQL_DB-green.svg?style=for-the-badge)

**EzzeMessManage** is a clean, local-first Flutter application designed to effortlessly manage shared living expenses, meal tracking, and monthly billing. It is the perfect tool for bachelor pads, hostels, or any shared "mess" setup to keep finances transparent and fair.

---

## ✨ Key Features

* **👥 Member Management:** Easily add, edit, or deactivate members.
* **🍽️ Daily Meal Tracking:** Log meals per member with a convenient counter or via a monthly calendar view.
* **🛒 Bazar (Grocery) Logs:** Record shared grocery expenses with categories and notes.
* **🧾 Other Shared Costs:** Distribute fixed costs like Rent, Trash, Wi-Fi, and Utilities.
* **💳 Payment Tracking:** Log who paid what (Cash, Bank, Mobile Banking) to keep the pool balanced.
* **📊 Automated Month-End Calculation:** Instantly calculates the meal rate, individual total costs, and who owes or is owed money.
* **💾 100% Local & Fast:** Powered by **ObjectBox**, meaning your data stays securely on your device with lightning-fast read/writes.
* **📤 Export & Backup:** Generate polished **PDF reports** for transparency, or export/import **JSON backups** to secure your data or share it with a new manager.
* **🌙 Dynamic Theming:** Full support for both Light and Dark modes.

---

## 🏗️ Project Architecture

This app follows a modular, feature-based **Layered Architecture** to ensure clean separation of concerns and future scalability.

```text
lib/
├── core/                           # App-wide utilities and business logic
│   ├── theme.dart                  # UI styling and color palettes
│   ├── helpers.dart                # Global helper functions
│   └── calculation_engine.dart     # Core math for meal rates and dues
├── data/                           # Data layer
│   ├── local/                      # Local database generated files
│   ├── models/                     # ObjectBox Entities (Member, MealEntry, etc.)
│   └── services/                   # App services (DbService, ExportService, etc.)
├── ui/                             # Presentation layer
│   ├── screens/                    # Individual feature screens
│   ├── shell/                      # Main app shell (Navigation & Drawer)
│   └── widgets/                    # Reusable UI components
└── main.dart                       # App entry point
```
## **🚀 Getting Started**
Follow these instructions to get a copy of the project up and running on your local machine.
### **Prerequisites**
* **Flutter SDK (Version 3.19.0 or higher recommended)**
* **Dart SDK**

### **Installation & Setup**

**1. Clone the repository:**
`git clone https://github.com/yourusername/MessManager.git`
`cd MessManager`

**2. Install dependencies:**
`flutter pub get`

**3. Generate ObjectBox Database Bindings:**
Because this app uses ObjectBox, you must generate the local database bindings before running the app. Run the following command in the root directory:

`dart run build_runner build --delete-conflicting-outputs`

**(This will create the required objectbox.g.dart file in the lib/ directory based on the objectbox-model.json schema).**

**4. Run the App:**
`flutter run`

---

## **🛠️ Tech Stack & Packages**

* **Framework:** Flutter
* **Local Database:** ObjectBox (objectbox, objectbox_flutter_libs)
* **PDF Generation:** pdf, printing
* **File Handling & Sharing:** file_picker, share_plus, path_provider
* **Preferences:** shared_preferences

---

## **👨🏻‍💻 Author**
**MD. Imran Hasan**
---

## **📝 License**

**Distributed under the MIT License. See LICENSE for more information.**

**Built using Flutter.**