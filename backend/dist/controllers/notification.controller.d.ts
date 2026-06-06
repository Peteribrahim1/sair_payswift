import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
export declare const getNotifications: (req: AuthRequest, res: Response) => Promise<void>;
export declare const markNotificationRead: (req: AuthRequest, res: Response) => Promise<void>;
