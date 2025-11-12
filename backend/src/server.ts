import { Hono } from 'hono';
import { logger } from './logger';
import auth from './routes/auth';

const app = new Hono();

// Health check endpoint
app.get('/health', (c) => {
  return c.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Mount auth routes
app.route('/api/auth', auth);

const PORT = process.env.PORT || 3000;

logger.info({ port: PORT }, 'Starting Phantom Ping Backend server');

export default {
  port: PORT,
  fetch: app.fetch,
};
