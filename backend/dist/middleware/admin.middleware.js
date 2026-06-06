"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticateAdmin = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const prisma_1 = require("../prisma");
const JWT_SECRET = process.env.JWT_SECRET;
/**
 * Admin middleware — verifies JWT token AND checks the user's isAdmin flag
 * in the database. A valid user token alone is NOT enough to access admin routes.
 */
const authenticateAdmin = async (req, res, next) => {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) {
        return res.status(401).json({ error: 'Access denied. No token provided.' });
    }
    try {
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
        // Always do a live DB lookup — token alone is not enough
        const user = await prisma_1.prisma.user.findUnique({
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
    }
    catch (ex) {
        res.status(401).json({ error: 'Invalid or expired token.' });
    }
};
exports.authenticateAdmin = authenticateAdmin;
//# sourceMappingURL=admin.middleware.js.map