

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

## 📂 Project Structure

```
lib/
├── screens/           # UI Screens (Login, Dashboard, etc.)
├── services/          # Supabase service integration
├── providers/         # Auth, Expense, and Group state management
├── theme/             # Light and Dark themes
├── main.dart          # App entry point
```

## 🤝 Contributing

Pull requests are welcome! If you have suggestions for improvements or new features, feel free to open an issue.

## 📄 License

MIT License. See `LICENSE` for details.


