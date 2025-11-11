# Phantom Ping - Frontend

The Flutter mobile application for Phantom Ping, a real-time group pager system that enables organizations to broadcast important messages to users with severity-based notifications.

## Overview

Phantom Ping is a group pager application that allows administrators to broadcast messages to users within their organization. The system supports hierarchical role management (Owner, Admin, Supervisor, Normal User) and topic-based messaging with three severity levels that trigger different notification patterns.

## Features

### For Normal Users

- Secure login using PIN and Organization ID
- Receive real-time broadcast messages via WebSocket
- Severity-based notifications:
  - **Low**: Vibration only
  - **Medium**: Vibration + screen pulse
  - **High**: Vibration + screen pulse + sound
- Acknowledge messages to stop notifications
- View message history
- Toggle notification preferences

### For Supervisors

- All Normal User features
- Broadcast messages to assigned topic
- Topic-specific messaging dashboard

### For Admins

- All Normal User features
- Register new users and generate PINs
- Promote/demote users to Supervisor role
- Kick users from organization
- Create and manage topics
- Assign users to topics
- Broadcast messages organization-wide or to specific topics

### For Owners

- All Admin features
- Promote/demote Admins
- Transfer ownership to another Admin
- Full organization management control

## Architecture

The frontend is built with Flutter and communicates with the Bun backend via:

- REST API for CRUD operations (authentication, user management, organization management)
- WebSocket for real-time message delivery and acknowledgements

### Key Components

- **Authentication Module**: Handles login, token management, and session persistence
- **WebSocket Client**: Maintains persistent connection for real-time messaging
- **Notification Service**: Triggers platform-specific notifications based on message severity
- **Role-Based UI**: Different screens and capabilities based on user role

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider/Riverpod
- **HTTP Client**: http package
- **WebSocket**: web_socket_channel
- **Secure Storage**: flutter_secure_storage
- **Notifications**: flutter_local_notifications
- **Haptics**: vibration package
- **Audio**: audioplayers package

## Getting Started

### Prerequisites

- Flutter SDK (3.35.7 or higher)
- Android Studio or Xcode for platform-specific builds
- Backend server running (see ../backend/README.md)

### Installation

1. Install dependencies:

```bash
flutter pub get
```

2. Configure backend endpoint:

   - Update API base URL in configuration file (to be created)

3. Run the app:

```bash
flutter run
```

### Development

Run tests:

```bash
flutter test
```

Run with hot reload:

```bash
flutter run --hot
```

Generate code (if using code generation):

```bash
flutter pub run build_runner build
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── services/                 # Business logic (auth, websocket, notifications)
├── screens/                  # UI screens
│   ├── auth/                # Login and registration screens
│   ├── admin/               # Admin-specific screens
│   ├── supervisor/          # Supervisor-specific screens
│   └── user/                # Normal user screens
├── widgets/                  # Reusable UI components
└── utils/                    # Helper functions and constants
```

## Configuration

Environment-specific configuration will be managed through:

- Development: Local backend (localhost)
- Production: Production backend URL

## Security

- JWT tokens stored securely using flutter_secure_storage
- Automatic token refresh on expiration
- Secure WebSocket connections (WSS)
- PIN-based authentication

## Contributing

This is part of a monorepo structure. See the root README.md for contribution guidelines.

## License

[To be determined]
