"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.markNotificationRead = exports.getNotifications = void 0;
const prisma_1 = require("../prisma");
const getNotifications = async (req, res) => {
    try {
        const notifications = await prisma_1.prisma.notification.findMany({
            where: { userId: req.user.id },
            orderBy: { createdAt: 'desc' },
        });
        res.json(notifications);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.getNotifications = getNotifications;
const markNotificationRead = async (req, res) => {
    try {
        const id = req.params.id;
        const notification = await prisma_1.prisma.notification.updateMany({
            where: { id, userId: req.user.id },
            data: { read: true },
        });
        res.json({ success: true });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.markNotificationRead = markNotificationRead;
//# sourceMappingURL=notification.controller.js.map