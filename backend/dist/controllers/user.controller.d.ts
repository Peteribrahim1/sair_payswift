import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
export declare const getProfile: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const updateProfile: (req: AuthRequest, res: Response) => Promise<void>;
export declare const submitKyc: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const uploadProfilePicture: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const uploadKycDocument: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const saveFcmToken: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
