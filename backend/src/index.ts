import express from 'express';
import cors from 'cors';
import { register, login } from './controllers/auth.controller';
import { getProfile } from './controllers/user.controller';
import { transact } from './controllers/services.controller';
import { authenticate } from './middleware/auth.middleware';

const app = express();
app.use(cors());
app.use(express.json());

// Auth Routes
app.post('/api/auth/register', register);
app.post('/api/auth/login', login);

// User Routes
app.get('/api/user/profile', authenticate, getProfile);

// Service Routes
app.post('/api/services/transact', authenticate, transact);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
