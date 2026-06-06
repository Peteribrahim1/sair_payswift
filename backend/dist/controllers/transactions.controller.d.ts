import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
export declare const withdrawFunds: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
