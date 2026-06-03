import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../prisma';
import { AuthRequest } from './auth.middleware';

const JWT_SECRET = process.env.JWT_SECRET!;

/**
 * Admin middleware — verifies JWT token AND checks the user's isAdmin flag
 * in the database. A valid user token alone is NOT enough to access admin routes.
 */
export const authenticateAdmin = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;

    // Always do a live DB lookup — token alone is not enough
    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      select: { id: true, email: true, isAdmin: true },
    });

    if (!user) {
      return res.status(401).json({ error: 'User not found.' });
    }

    if (!user.isAdmin) {
      return res.status(403).json({ error: 'Forbidden. Admin access required.' });
    }

    req.user = { id: user.id, email: user.email };
    next();
  } catch (ex) {
    res.status(401).json({ error: 'Invalid or expired token.' });
  }
};
