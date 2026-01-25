💇‍♀️ The Glamour House
Where Style Meets Technology

The Glamour House is a premium, cross-platform mobile application built to modernize the salon experience. Developed using Flutter and Firebase, the app allows customers to book salon services in real time while providing salon owners with a powerful digital platform to showcase their work and manage appointments seamlessly.

✨ Key Features
📅 Smart Scheduling

Easy Appointment Booking – Choose from services such as Haircuts, Facials, Waxing, and more

Specialist Selection – Book your preferred stylist based on skills and expertise

Real-Time Availability – Live time slots prevent double bookings

🖼️ Interactive Style Gallery

Categorized Styles – Hair Coloring, Skin Care, Manicure, and more

Customer Reviews & Ratings – View genuine feedback on specific styles

🔐 Role-Based Dashboards

Customer Dashboard

View & manage appointments

Save favorite styles

Admin Dashboard

Upload and manage gallery images

Monitor appointments and salon performance

🌗 Theme Support

Smooth switching between Light Mode and Dark Mode

🛠️ Technology Stack
Layer	Technology
Frontend	Flutter (Dart)
Database	Firebase Cloud Firestore (NoSQL)
Authentication	Firebase Auth (Email & Password)
Storage	Firebase Storage (Image Hosting)
State Management	Provider
🚀 Getting Started
📋 Prerequisites

Flutter SDK ^3.0.0

IDE: Android Studio or VS Code

Firebase Project (via Firebase Console)

🔧 Installation & Setup
1️⃣ Clone the Repository
git clone https://github.com/yourusername/glamour_salon.git
cd glamour_salon
flutter pub get

2️⃣ Firebase Configuration

Register the app in Firebase Console

Add configuration files:

google-services.json → android/app/

GoogleService-Info.plist → ios/Runner/

Enable Firestore, Authentication, and Storage

Set Firestore & Storage rules for development

3️⃣ Run the App
flutter run

📂 Project Structure
lib/
 ├── models/       # Data models (UserModel, Appointment, Review)
 ├── services/     # Firebase services (AuthService, DatabaseService)
 ├── screens/      # UI screens
 │   ├── home/     # Home banners & testimonials
 │   ├── gallery/  # Style gallery & details
 │   ├── booking/  # Appointment booking flow
 │   └── admin/    # Admin management tools
 └── main.dart     # App entry point & theme setup

🧪 Testing Strategy

Unit Tests – Validate Firestore model parsing

Integration Tests – End-to-end booking workflow

UI/UX Tests – Responsiveness and Dark Mode contrast

🔮 Roadmap

✅ Phase 1 – Core Booking & Gallery

🚧 Phase 2 – Payment Integration (PayHere / Stripe)

📅 Phase 3 – Push Notifications for reminders

💎 Phase 4 – AI-based Style Recommendation Engine
