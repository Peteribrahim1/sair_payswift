"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.resetPassword = exports.verifyResetOtp = exports.forgotPassword = exports.login = exports.register = void 0;
const bcrypt_1 = __importDefault(require("bcrypt"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const prisma_1 = require("../prisma");
const JWT_SECRET = process.env.JWT_SECRET || 'super-secret-key';
const register = async (req, res) => {
    const { email, password, fullName, phone } = req.body;
    try {
        const existingUser = await prisma_1.prisma.user.findUnique({ where: { email } });
        if (existingUser)
            return res.status(400).json({ error: 'User already exists.' });
        const hashedPassword = await bcrypt_1.default.hash(password, 10);
        const user = await prisma_1.prisma.user.create({
            data: {
                email,
                password: hashedPassword,
                fullName,
                phone,
                balance: 0.0, // Initial balance
            },
        });
        const token = jsonwebtoken_1.default.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
        res.status(201).json({ token, user: { id: user.id, email: user.email, fullName: user.fullName, phone: user.phone, balance: user.balance } });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.register = register;
const login = async (req, res) => {
    const { email, password } = req.body;
    try {
        const user = await prisma_1.prisma.user.findUnique({ where: { email } });
        if (!user)
            return res.status(400).json({ error: 'Invalid email or password.' });
        const validPassword = await bcrypt_1.default.compare(password, user.password);
        if (!validPassword)
            return res.status(400).json({ error: 'Invalid email or password.' });
        const token = jsonwebtoken_1.default.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
        res.json({ token, user: { id: user.id, email: user.email, balance: user.balance } });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.login = login;
const forgotPassword = async (req, res) => {
    const { email } = req.body;
    try {
        const user = await prisma_1.prisma.user.findUnique({ where: { email } });
        if (!user)
            return res.status(404).json({ error: 'User with this email does not exist.' });
        // Generate a 4-digit OTP
        const otp = Math.floor(1000 + Math.random() * 9000).toString();
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins
        await prisma_1.prisma.user.update({
            where: { id: user.id },
            data: { resetOtp: otp, resetOtpExpiresAt: expiresAt },
        });
        const { sendPasswordResetEmail } = await Promise.resolve().then(() => __importStar(require('../services/email.service')));
        await sendPasswordResetEmail(user.email, otp);
        res.json({ success: true, message: 'Password reset OTP sent to email.' });
    }
    catch (error) {
        console.error('forgotPassword error:', error);
        res.status(500).json({ error: 'Failed to send reset email.' });
    }
};
exports.forgotPassword = forgotPassword;
const verifyResetOtp = async (req, res) => {
    const { email, otp } = req.body;
    try {
        const user = await prisma_1.prisma.user.findUnique({ where: { email } });
        if (!user)
            return res.status(404).json({ error: 'User not found.' });
        if (user.resetOtp !== otp) {
            return res.status(400).json({ error: 'Invalid OTP.' });
        }
        if (!user.resetOtpExpiresAt || user.resetOtpExpiresAt < new Date()) {
            return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
        }
        res.json({ success: true, message: 'OTP verified successfully.' });
    }
    catch (error) {
        console.error('verifyResetOtp error:', error);
        res.status(500).json({ error: 'Failed to verify OTP.' });
    }
};
exports.verifyResetOtp = verifyResetOtp;
const resetPassword = async (req, res) => {
    const { email, otp, newPassword } = req.body;
    try {
        const user = await prisma_1.prisma.user.findUnique({ where: { email } });
        if (!user)
            return res.status(404).json({ error: 'User not found.' });
        if (user.resetOtp !== otp || !user.resetOtpExpiresAt || user.resetOtpExpiresAt < new Date()) {
            return res.status(400).json({ error: 'Invalid or expired OTP.' });
        }
        const hashedPassword = await bcrypt_1.default.hash(newPassword, 10);
        await prisma_1.prisma.user.update({
            where: { id: user.id },
            data: {
                password: hashedPassword,
                resetOtp: null,
                resetOtpExpiresAt: null,
            },
        });
        res.json({ success: true, message: 'Password reset successfully. You can now login.' });
    }
    catch (error) {
        console.error('resetPassword error:', error);
        res.status(500).json({ error: 'Failed to reset password.' });
    }
};
exports.resetPassword = resetPassword;
//# sourceMappingURL=auth.controller.js.map