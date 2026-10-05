# SyncUp — real-time collaboration app

SyncUp is a mobile-first Flutter chat client and a horizontally scalable Node/Express + Socket.IO backend. It supports email/password auth, workspace join codes, channels, direct conversations, persisted message history, replies, soft-delete/edit, presence, typing and Cloudinary attachments.

## Run locally

1. Start infrastructure: `docker compose up -d`.
2. Copy `backend/.env.example` to `backend/.env` and set `JWT_SECRET`, `JWT_REFRESH_SECRET`, and Cloudinary credentials for uploads.
3. Install and start the API: `cd backend && npm install && npm run dev`.
4. In another terminal run Flutter: `flutter pub get && flutter run`.

Android emulators use the default API URL `http://10.0.2.2:4000/api/v1`. For a physical device, run Flutter with `--dart-define=API_URL=http://YOUR_LAN_IP:4000/api/v1`.

To seed local demo accounts, run `cd backend && npx tsx src/seed.ts`; both accounts use `password123`. Create a workspace with one account and share the returned join code with the other.

## Layout

`lib/` contains Flutter models, services, Riverpod providers, theme, routing, and screens. `backend/src/server.ts` contains the API, persistence models, middleware, upload handling, and Socket.IO event handlers; Docker supplies MongoDB and Redis for local development.

## Project submission

- [SyncUp project report](docs/SyncUp_Project_Report.pdf) - implementation details, technology stack, architecture, project structure, API and realtime flow, persistence, security, testing, and deployment verification.
- [SyncUp working demonstration](docs/SyncUp_demo.mp4) - recorded walkthrough of the implemented application.
- [Watch the demo online on Cap.so](https://cap.so/s/nkwg7frs67sbsrq) - browser playback link for teachers and reviewers.

The deployed backend is available at `https://syncup-api-production.up.railway.app`. Its health endpoint is `GET /api/v1/health` and returns `{"status":"ok"}` when the service is reachable.

## Realtime contract

Connect Socket.IO with `{auth: {token: accessToken}}`, join a room with `conversation:join`, send messages with `message:send` and a unique `clientId`, and listen for `message:new`, `message:updated`, `message:deleted`, `typing:update`, `presence:update`, and `receipt:update`.
