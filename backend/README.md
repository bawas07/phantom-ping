# Phantom Ping Backend

Real-time group pager system backend built with Bun, TypeScript, and Hono.

## Prerequisites

- [Bun](https://bun.sh) v1.0 or higher

## Getting Started

1. Install dependencies:
```bash
bun install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Run database migrations:
```bash
bun run migrate
```

4. Start the development server:
```bash
bun run dev
```

The server will start on `http://localhost:3000` (or the port specified in `.env`).

## Available Scripts

- `bun run dev` - Start development server with hot reload
- `bun run start` - Start production server
- `bun run test` - Run tests

## Project Structure

```
backend/
├── src/
│   ├── server.ts              # Main server entry point
│   ├── logger.ts              # Pino logger configuration
│   ├── config/                # Configuration and environment
│   ├── db/                    # Database connection and migrations
│   ├── middleware/            # Auth, validation, error handling, logging
│   ├── services/              # Business logic (auth, org, topic, broadcast)
│   ├── routes/                # API route handlers
│   ├── websocket/             # WebSocket server and handlers
│   └── utils/                 # Utilities (ID generation, validation)
├── tests/                     # Unit and integration tests
└── migrations/                # Database migration files
```

## API Documentation

See the design document for detailed API specifications.

## Technology Stack

- **Runtime**: Bun
- **Web Framework**: Hono
- **Database**: SQLite (bun:sqlite)
- **WebSocket**: Bun native WebSocket API
- **Authentication**: JWT
- **Logging**: Pino
