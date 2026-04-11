# 💸 Expense Tracker App

A modern Flutter-based expense tracking application that helps users manage daily spending, categorize expenses, and gain insights through analytics.

---

## Features

- Authentication (Login / Logout) *(Firebase Auth ready)*
- Add and manage expenses
- Category-based tracking (Food, Travel, Bills, etc.)
- Filter and Sorting expenses (Today, Yesterday, Weekly, Monthly)
- Analytics with charts (category-wise insights)
- Expense detail view with document support
- Local storage using Hive (offline support)
- Firebase integration *(Auth, Storage, Firestore – scalable for sync)*
- Clean and modern UI  

###  Advanced Features
- Lazy loading & pagination for scalable expense listing  
- Voice-based expense entry using speech recognition  
- Smart receipt scanning with OCR for automatic data extraction  

##  Tech Stack

- Flutter  
- Riverpod (State Management)  
- Hive (Local Database)  
- Firebase (Auth / Storage / Firestore)  
- fl_chart (Analytics)  
- speech_to_text (Voice Input)  
- google_mlkit_text_recognition (OCR)  

---

## 📸 Screenshots

| Login | Dashboard | Add Expense | Analytics |
|------|----------|------------|----------|
| ![Login](screenshots/login.jpg) | ![Dashboard](screenshots/dashboard.jpg) | ![Add](screenshots/add.jpg) | ![Analytics](screenshots/analytics.jpg) |

---

## 🛠️ Setup Instructions

### 1. Clone the repository
```bash
git clone https://github.com/Cva-Murugan/Expense-Tracker.git

cd Expense-Tracker

flutter pub get

flutter run


