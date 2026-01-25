
The Glamour House ✨
A Premium Salon Management & Appointment Booking System

The Glamour House is a cross-platform mobile application built with Flutter and Firebase. It provides a seamless digital experience for salon customers to browse trendy styles, read authentic reviews, and book appointments with specialists in real-time.

🌟 Key Features
Smart Appointment Booking: Customers can select services (Hair Cut, Facial, etc.), choose their preferred specialist, and pick an available date and time slot.

Dynamic Style Gallery: A categorized gallery (Skin Care, Coloring, Manicure) allowing users to view high-quality images of salon work.

Customer Testimonials: A horizontal review section on the home screen and service-specific reviews in the gallery to build trust.

Admin Dashboard: A secure area for salon owners to manage the gallery, add new services, and monitor appointment logs.

Role-Based Access: Specialized interfaces for Customers, Specialists, and Administrators.

Theme Support: Fully optimized for both Light and Dark mode user preferences.

🛠️ Tech Stack
Frontend: Flutter (Dart)

Backend: Firebase Cloud Firestore (NoSQL Database)

Authentication: Firebase Auth (Email & Password)

Storage: Firebase Storage (Image hosting)

State Management: Provider

🚀 Getting Started
Prerequisites
Flutter SDK: ^3.0.0

Android Studio / VS Code

A Firebase Project (Google)

Installation
Clone the repository:

Bash
git clone https://github.com/yourusername/glamour_salon.git
Install dependencies:

Bash
flutter pub get
Firebase Setup:

Create a project in Firebase Console.

Register your Android/iOS app.

Download google-services.json and place it in android/app/.

Run the app:

Bash
flutter run
📂 Project Structure
Plaintext
lib/
├── models/           # Data models (UserModel, Appointment, Review)
├── services/         # Firebase Authentication & Firestore logic
├── screens/
│   ├── home_page.dart         # Banners & Customer Testimonials
│   ├── gallery_page.dart      # Filtered Style Grid
│   ├── booking_page.dart      # Appointment logic
│   └── admin_add_photo.dart   # Admin gallery management
└── main.dart         # App entry point & Theme config
🧪 Testing
Unit Testing: Validating data mapping and model logic.

Integration Testing: Checking the flow from user booking to Firestore update.

UI Testing: Ensuring responsive layouts across different screen sizes.

📝 Future Enhancements
Payment Gateway: Integration of PayHere/Stripe for online deposits.

Push Notifications: Automated reminders for upcoming appointments.

Loyalty Program: Points-based system for frequent customers.
