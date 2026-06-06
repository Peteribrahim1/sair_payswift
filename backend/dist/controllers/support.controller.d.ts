import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
export declare const createTicket: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const aiChat: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
