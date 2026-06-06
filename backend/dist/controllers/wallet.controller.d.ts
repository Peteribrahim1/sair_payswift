import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
export declare const getVirtualAccount: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const handleWebhook: (req: Request, res: Response) => Promise<void>;
