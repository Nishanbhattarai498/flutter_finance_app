

# 💸 Flutter Finance App

A personal finance management app built with **Flutter** that helps users **track expenses**, **manage budgets**, and **split bills** with friends or groups. Currently a work in progress — contributions and feedback are welcome!

## ✨ Features

* 🔐 User Authentication (Supabase)
* 📊 Dashboard for tracking income and expenses
* 👥 Expense splitting among groups and friends
* 📁 Category-wise transaction management
* ☁️ Supabase backend integration



## 🛠️ Tech Stack

* **Flutter**
* **Supabase** – for authentication and backend services
* **Provider** – for state management
* **Material Design** – for UI

## 🚀 Getting Started

### Prerequisites

* Flutter SDK
* Supabase project (get your `supabaseUrl` and `supabaseAnonKey`)
* An IDE like VSCode or Android Studio

### Installation

```bash
git clone https://github.com/Nishanbhattarai498/flutter-finance-app.git
cd flutter-finance-app
flutter pub get
```

### Setup

In `main.dart`, replace:

```dart
supabaseUrl: 'YOUR_SUPABASE_URL',
supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
```

with your actual Supabase credentials.

### Run the App

```bash
flutter run
```



## 📁 File Structure

This project is structured to support a modular Flutter application. Here's a brief description of the main files:

### 🔹 `main.dart`

* Entry point of the application.

### 🔹 `lib/models/`

* *(No individual files listed)*: Contains model classes used across the app.

### 🔹 `lib/providers/`

* `auth_provider.dart`: Manages authentication logic and state.
* `expense_provider.dart`: Handles state and logic related to expenses.
* `group_provider.dart`: Manages group-related operations and state.

### 🔹 `lib/screens/`

* Contains subfolders (`auth`, `dashboard`, `expenses`, `groups`, `profile`, `settlements`) with UI screens organized by feature. *(Specific files not listed here.)*

### 🔹 `lib/services/`

* `supabase_service.dart`: Handles backend communication via Supabase.

### 🔹 `lib/theme/`

* `app_theme.dart`: Manages global theming for the app (colors, fonts, etc.).

### 🔹 `lib/widgets/`

* `custom_button.dart`: A reusable button widget.
* `custom_text_field.dart`: A customizable text field widget.

---




## 🤝 Contributing

Pull requests are welcome! If you have suggestions for improvements or new features, feel free to open an issue.

## 📄 License

MIT License. See `LICENSE` for details.


