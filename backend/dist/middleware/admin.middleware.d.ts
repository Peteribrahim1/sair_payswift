import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware';
/**
 * Admin middleware — verifies JWT token AND checks the user's isAdmin flag
 * in the database. A valid user token alone is NOT enough to access admin routes.
 */
export declare const authenticateAdmin: (req: AuthRequest, res: Response, next: NextFunction) => Promise<Response<any, Record<string, any>> | undefined>;
