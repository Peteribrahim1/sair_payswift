import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
export declare const addBankAccount: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const getBankAccounts: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteBankAccount: (req: AuthRequest, res: Response) => Promise<void>;
