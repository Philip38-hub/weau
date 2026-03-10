# weau

`weau` is a Flutter mobile app with a Node.js/Express backend and PostgreSQL database for real-time friend location sharing.

## Project structure

- `frontend/` — Flutter mobile app
- `server.js` — Express API server
- `database.js` — PostgreSQL connection and schema initialization

## Tech stack

- Flutter
- Google Maps / Geolocator
- Provider state management
- Node.js + Express
- PostgreSQL
- Google Sign-In / Google ID token auth

## Prerequisites

### Frontend

- Flutter SDK
- Android Studio or connected Android device
- Google Maps and Google Sign-In configuration

### Backend

- Node.js 18+
- npm
- PostgreSQL

## Running the server locally

### 1. Install backend dependencies

```bash
npm install
```

### 2. Start PostgreSQL

Create a local PostgreSQL database named `weau`, or provide a `DATABASE_URL`.

Default local fallback used by the server:

```text
postgresql://localhost:5432/weau
```

### 3. Create a root `.env` file

Recommended environment variables:

```env
PORT=3000
DATABASE_URL=postgresql://localhost:5432/weau
JWT_SECRET=replace_me
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
NODE_ENV=development
```

Notes:

- `JWT_SECRET` falls back to a default in code, but set your own for local/dev parity.
- `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_CLIENT_ID` are recommended so the backend can verify Google ID tokens properly.
- The database schema is initialized automatically on server startup.

### 4. Run the backend

Development mode with auto-restart:

```bash
npm run dev
```

Normal mode:

```bash
npm start
```

The server binds to `0.0.0.0` and starts on:

- `http://localhost:3000`
- your LAN IP, when available

## Running the Flutter app against a local server

### 1. Set the app API base URL

Edit `frontend/lib/core/constants.dart` and point `baseUrl` to the development URL.

For local desktop/emulator testing, use the dev constant:

```dart
static const String _devBaseUrl = 'http://localhost:3000/api';
static const String _prodBaseUrl = 'https://weau-production.up.railway.app/api';
static const String baseUrl = _devBaseUrl;
```

### 2. Important note for physical phones

If you run the Flutter app on a real phone, `localhost` points to the phone itself, not your computer.

In that case, change `_devBaseUrl` to your computer's LAN IP, for example:

```dart
static const String _devBaseUrl = 'http://192.168.1.10:3000/api';
```

Make sure:

- phone and computer are on the same network
- backend is running locally
- port `3000` is reachable from the phone

### 3. Add frontend environment config

The login flow reads `GOOGLE_WEB_CLIENT_ID` from `frontend/.env`.

Example:

```env
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
```

### 4. Run the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

## Using the deployed Railway server

The current deployed API URL is:

```dart
static const String _prodBaseUrl = 'https://weau-production.up.railway.app/api';
```

To use the deployed backend from the Flutter app, set:

```dart
static const String baseUrl = _prodBaseUrl;
```

Then run the app normally:

```bash
cd frontend
flutter run
```

## Railway notes

- Railway starts the backend with `npm start`
- `NODE_ENV=production` is configured in `railway.json`
- PostgreSQL is provisioned as a Railway service
- In production, PostgreSQL SSL is enabled automatically by the app when `NODE_ENV=production`

Recommended Railway environment variables:

- `JWT_SECRET`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_CLIENT_ID`
- `DATABASE_URL` (usually injected by Railway Postgres)

## Helpful commands

### Backend

```bash
npm install
npm run dev
npm start
node --check server.js
```

### Frontend

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter run
```

## Troubleshooting

### Google sign-in works locally but API auth fails

Check that:

- `frontend/.env` contains the correct `GOOGLE_WEB_CLIENT_ID`
- backend `.env` contains `GOOGLE_WEB_CLIENT_ID` and/or `GOOGLE_CLIENT_ID`
- the app is pointed at the intended backend (`_devBaseUrl` vs `_prodBaseUrl`)

### App cannot reach local backend from a phone

Use your computer's LAN IP instead of `localhost` in `_devBaseUrl`.

### Invite/friend/location sync issues on deployed backend

After backend redeploys, sign out and sign back in so user records refresh with the correct Google email/profile data.
