# AgriSense - Farmer Loss Prevention App

![AgriSense Logo](agrisense_ui/assets/images/AGRISENSEWLOGO.png)

A comprehensive mobile and backend application designed to help farmers prevent crop losses through intelligent weather monitoring, AI-powered chatbot assistance, and real-time notifications.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [API Endpoints](#api-endpoints)
- [Project Structure Details](#project-structure-details)
- [Technologies Used](#technologies-used)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## Overview

**AgriSense** is an innovative solution designed as a university group project to address the challenges faced by farmers in preventing crop losses. The application combines real-time weather data, AI-powered guidance, and intelligent notifications to help farmers make informed decisions about their crops.

The project consists of:
- **Flutter Mobile App** - Cross-platform mobile application for farmers
- **Node.js Backend API** - RESTful API for data management and processing
- **MongoDB Database** - NoSQL database for storing user and notification data

---

## Features

### 🌾 Core Features

- **User Authentication**
  - Email/Password registration and login
  - Google Sign-In integration
  - Facebook authentication
  - JWT-based session management

- **Weather Monitoring**
  - Real-time weather data integration
  - Location-based weather updates
  - Weather alerts and predictions

- **AI Chatbot Assistant**
  - Powered by Google Gemini AI
  - Agricultural guidance and advice
  - Crop disease identification
  - Loss prevention recommendations

- **Notifications**
  - Real-time alerts for weather events
  - Crop health warnings
  - Personalized farmer recommendations

- **User Profile Management**
  - Profile creation and customization
  - Preferences and settings
  - Account security

- **Chat Interface**
  - Message history
  - Markdown support for formatted responses
  - Real-time chat with AI assistant

---

## Project Structure

```
AgriSense-Farmer-Loss-Prevention-App/
│
├── agrisense_ui/                    # Flutter Frontend Application
│   ├── lib/
│   │   ├── main.dart               # App entry point
│   │   ├── screens/                # UI screens
│   │   │   ├── auth_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── chatbot_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   ├── models/                 # Data models
│   │   │   └── chat_message.dart
│   │   └── services/               # API services
│   ├── android/                    # Android configuration
│   ├── ios/                        # iOS configuration
│   ├── web/                        # Web support
│   ├── pubspec.yaml               # Flutter dependencies
│   └── assets/                    # Images and fonts
│
├── backend/                         # Node.js Backend
│   ├── config/
│   │   ├── db.js                  # MongoDB connection
│   │   └── env.js                 # Environment configuration
│   ├── controllers/               # Request handlers
│   │   ├── authController.js
│   │   ├── userController.js
│   │   ├── weatherController.js
│   │   ├── chatbotController.js
│   │   └── notificationController.js
│   ├── models/                    # MongoDB schemas
│   │   ├── User.js
│   │   ├── ChatMessage.js
│   │   └── Notification.js
│   ├── routes/                    # API route definitions
│   │   ├── authRoutes.js
│   │   ├── userRoutes.js
│   │   ├── weatherRoutes.js
│   │   ├── chatbotRoutes.js
│   │   └── notificationRoutes.js
│   ├── middleware/                # Custom middleware
│   │   ├── authMiddleware.js
│   │   ├── errorMiddleware.js
│   │   └── roleMiddleware.js
│   ├── utils/                     # Utility functions
│   │   ├── geminiClient.js
│   │   └── generateToken.js
│   ├── server.js                  # Express server entry point
│   ├── package.json               # Node.js dependencies
│   └── .env.example               # Environment template
│
└── README.md                        # This file
```

---

## Prerequisites

### For Backend

- **Node.js** (v14 or higher)
- **npm** (v6 or higher)
- **MongoDB** (v4.4 or higher) - Local instance or MongoDB Atlas account
- **Google Gemini API Key** - For chatbot functionality

### For Frontend

- **Flutter SDK** (v3.10.7 or higher)
- **Dart SDK** (v3.10.7 or higher)
- **Android Studio** (for Android development) or **Xcode** (for iOS development)
- **Google Sign-In credentials**
- **Facebook App credentials**

---

## Installation

### Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd AgriSense-Farmer-Loss-Prevention-App
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create environment configuration:**
   ```bash
   # Copy the example environment file
   cp .env.example .env
   ```

4. **Configure the `.env` file with your settings:**
   ```env
   PORT=5000
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/agrisense
   JWT_SECRET=your_jwt_secret_key_here
   GEMINI_API_KEY=your_gemini_api_key_here
   WEATHER_API_KEY=your_weather_api_key_here
   NODE_ENV=development
   ```

5. **Verify MongoDB connection:**
   - Ensure your MongoDB instance is running
   - Test the connection string in your `.env` file

### Frontend Setup

1. **Navigate to the Flutter app directory:**
   ```bash
   cd agrisense_ui
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint:**
   - Update the API base URL in your services to point to your backend server
   - Typically in `lib/services/` files

4. **Set up authentication providers:**
   - **Google Sign-In**: Add your `google-services.json` (Android) and configure iOS
   - **Facebook Auth**: Configure your Facebook App ID in the app

---

## Configuration

### Backend Configuration Details

**Database (`config/db.js`):**
- Uses Mongoose to connect to MongoDB
- Automatically creates collections on first use

**Environment Variables (`config/env.js`):**
```env
# Server Configuration
PORT=5000
NODE_ENV=development

# Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/dbname

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRE=7d

# APIs
GEMINI_API_KEY=your-api-key
WEATHER_API_KEY=your-api-key

# CORS
CORS_ORIGIN=*
```

### Frontend Configuration Details

**API Base URL (`lib/services/`):**
- Update to your backend server URL (e.g., `http://localhost:5000` or production URL)

**Authentication:**
- Configure `google_sign_in` package with your Google Cloud credentials
- Configure `flutter_facebook_auth` with your Facebook App ID

---

## Running the Application

### Backend

**Development mode (with auto-restart):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:5000` (or your configured PORT)

### Frontend

**Run on Android emulator:**
```bash
flutter run -d android
```

**Run on iOS simulator:**
```bash
flutter run -d ios
```

**Run on Web:**
```bash
flutter run -d web
```

**Build for release:**
```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release

# Web
flutter build web --release
```

---

## API Endpoints

### Authentication Routes (`/api/auth`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/register` | Register new user |
| POST | `/login` | User login |
| POST | `/logout` | User logout |
| POST | `/refresh-token` | Refresh JWT token |

### User Routes (`/api/users`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/profile` | Get user profile |
| PUT | `/profile` | Update user profile |
| GET | `/:id` | Get user by ID |
| DELETE | `/:id` | Delete user account |

### Weather Routes (`/api/weather`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/current` | Get current weather |
| GET | `/forecast` | Get weather forecast |
| GET | `/:location` | Get weather by location |

### Chatbot Routes (`/api/chatbot`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/message` | Send message to chatbot |
| GET | `/history` | Get chat history |
| DELETE | `/history` | Clear chat history |

### Notification Routes (`/api/notifications`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get all notifications |
| GET | `/:id` | Get notification by ID |
| POST | `/` | Create new notification |
| PUT | `/:id` | Update notification |
| DELETE | `/:id` | Delete notification |

---

## Project Structure Details

### Backend Architecture

**Models:**
- **User.js** - User schema with authentication fields
- **ChatMessage.js** - Chat message storage and history
- **Notification.js** - Notification data structure

**Controllers:**
- Handle business logic for each feature
- Process requests and responses
- Interact with database models

**Middleware:**
- **authMiddleware.js** - JWT token validation
- **errorMiddleware.js** - Global error handling
- **roleMiddleware.js** - Role-based access control

**Utilities:**
- **geminiClient.js** - Integration with Google Gemini AI
- **generateToken.js** - JWT token generation

### Frontend Architecture

**Screens:**
- **auth_screen.dart** - Login and registration UI
- **home_screen.dart** - Main dashboard
- **chatbot_screen.dart** - AI assistant interface
- **profile_screen.dart** - User profile management
- **onboarding_screen.dart** - App onboarding flow

**Models:**
- **chat_message.dart** - Message data structure

**Services:**
- API communication layer
- Authentication service
- Weather data service
- Notification service

---

## Technologies Used

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider/Riverpod** - State management
- **HTTP** - API communication
- **Google Sign-In** - Authentication
- **Facebook Auth** - Social login
- **Shared Preferences** - Local storage

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM library
- **JWT** - Authentication
- **Google Gemini API** - AI chatbot
- **bcryptjs** - Password hashing
- **CORS** - Cross-origin support
- **Morgan** - HTTP logging

### Tools & Services
- **Git** - Version control
- **MongoDB Atlas** - Cloud database hosting
- **Google Cloud** - Gemini API and authentication
- **Facebook Developers** - Social authentication

---

## Contributing

This is a university group project. To contribute:

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Commit your changes:**
   ```bash
   git commit -m 'Add your feature'
   ```
4. **Push to the branch:**
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Submit a Pull Request**

### Guidelines
- Follow existing code style and conventions
- Write clear commit messages
- Test your changes before submitting
- Update documentation if needed

---

## License

This project is created as a university group project. Please check with your institution for licensing terms and usage rights.

---

## Support

### Getting Help

- **Documentation** - Check this README and inline code comments
- **Issues** - Create an issue on GitHub for bug reports
- **Discussions** - Start a discussion for questions and feature requests

### Common Issues

**MongoDB Connection Error:**
- Verify your connection string in `.env`
- Ensure MongoDB service is running
- Check network connectivity for MongoDB Atlas

**Authentication Fails:**
- Verify JWT_SECRET is set correctly
- Check token expiration settings
- Ensure credentials are correct

**API Request Errors:**
- Verify backend is running on correct port
- Check CORS settings
- Validate request headers and body

**Flutter Build Issues:**
- Run `flutter clean` to clear build cache
- Run `flutter pub get` to update dependencies
- Check that all platform requirements are met

---

## Project Team

This project is developed as a university group project for agricultural loss prevention research and education.

---

**Last Updated:** May 2026  
**Version:** 1.0.0

For more information, visit the project repository on GitHub.
