"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.aiChat = exports.createTicket = void 0;
const prisma_1 = require("../prisma");
const axios_1 = __importDefault(require("axios"));
const createTicket = async (req, res) => {
    try {
        const { subject, message } = req.body;
        if (!subject || !message) {
            return res.status(400).json({ error: 'Subject and message are required.' });
        }
        const userId = req.user.id;
        const ticket = await prisma_1.prisma.ticket.create({
            data: {
                userId,
                subject,
                message,
                status: 'PENDING'
            }
        });
        res.status(201).json({ success: true, ticket });
    }
    catch (error) {
        console.error('createTicket error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.createTicket = createTicket;
const aiChat = async (req, res) => {
    try {
        const { message } = req.body;
        if (!message) {
            return res.status(400).json({ error: 'Message is required.' });
        }
        const userId = req.user.id;
        const user = await prisma_1.prisma.user.findUnique({ where: { id: userId } });
        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }
        const geminiKey = process.env.GEMINI_API_KEY;
        if (geminiKey) {
            try {
                const prompt = `You are "PaySwift AI", a premium, helpful financial AI assistant for the Sair PaySwift mobile app.
The user you are talking to is named "${user.fullName}".
Their current wallet balance is ₦${user.balance.toFixed(2)}.
Their email is ${user.email} and phone number is ${user.phone}.

Provide helpful answers regarding their requests. You can direct them to perform operations in the app by returning an action payload in JSON.
The supported actions are:
- "NAVIGATE_BUY_AIRTIME": to buy airtime.
- "NAVIGATE_BUY_DATA": to buy mobile data.
- "NAVIGATE_CONVERT_AIRTIME": to convert airtime to cash.
- "NAVIGATE_WITHDRAW": to withdraw wallet funds to a bank account.
- "NAVIGATE_HISTORY": to see transaction history.
- "NONE": for general inquiries.

User message: "${message}"

You must respond STRICTLY with a single JSON object in this format:
{
  "reply": "your natural language response here",
  "action": {
    "type": "NONE" | "NAVIGATE_BUY_AIRTIME" | "NAVIGATE_BUY_DATA" | "NAVIGATE_CONVERT_AIRTIME" | "NAVIGATE_WITHDRAW" | "NAVIGATE_HISTORY",
    "payload": {
       "amount": number (optional, if they mention an amount to recharge/withdraw),
       "network": "MTN" | "AIRTEL" | "GLO" | "9MOBILE" (optional, if they mention a network)
    }
  }
}`;
                const response = await axios_1.default.post(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiKey}`, {
                    contents: [{ parts: [{ text: prompt }] }],
                    generationConfig: {
                        responseMimeType: "application/json"
                    }
                });
                const replyJsonText = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
                if (replyJsonText) {
                    const parsed = JSON.parse(replyJsonText);
                    return res.json({ success: true, ...parsed });
                }
            }
            catch (geminiError) {
                console.error('Gemini API call failed, falling back to local assistant:', geminiError);
            }
        }
        // Local rule-based fallback assistant
        const text = message.toLowerCase();
        let reply = `Hi ${user.fullName}! I'm PaySwift AI. I can help you check your balance, buy airtime/data, convert airtime to cash, or withdraw funds. How can I assist you today?`;
        let actionType = 'NONE';
        let payload = {};
        // Check keywords
        if (text.includes('balance') || text.includes('wallet') || text.includes('money') || text.includes('funds')) {
            reply = `Hi ${user.fullName}, your current wallet balance is ₦${user.balance.toFixed(2)}.`;
            actionType = 'NONE';
        }
        else if (text.includes('convert') && (text.includes('airtime') || text.includes('cash') || text.includes('change'))) {
            reply = `I can help you convert airtime to cash. Tap the shortcut button below to open the conversion screen.`;
            actionType = 'NAVIGATE_CONVERT_AIRTIME';
        }
        else if (text.includes('airtime') || text.includes('recharge') || text.includes('credit')) {
            reply = `Sure! Let me guide you to the airtime purchase page.`;
            actionType = 'NAVIGATE_BUY_AIRTIME';
            // Detect network
            if (text.includes('mtn'))
                payload.network = 'MTN';
            else if (text.includes('airtel'))
                payload.network = 'AIRTEL';
            else if (text.includes('glo'))
                payload.network = 'GLO';
            else if (text.includes('9mobile'))
                payload.network = '9MOBILE';
            // Detect amount
            const matches = text.match(/\d+/);
            if (matches) {
                payload.amount = parseInt(matches[0]);
            }
        }
        else if (text.includes('data') || text.includes('bundle') || text.includes('internet')) {
            reply = `I can help you top up your mobile data. Let's open the data plans page.`;
            actionType = 'NAVIGATE_BUY_DATA';
            if (text.includes('mtn'))
                payload.network = 'MTN';
            else if (text.includes('airtel'))
                payload.network = 'AIRTEL';
            else if (text.includes('glo'))
                payload.network = 'GLO';
            else if (text.includes('9mobile'))
                payload.network = '9MOBILE';
        }
        else if (text.includes('withdraw') || text.includes('bank') || text.includes('transfer')) {
            reply = `Let me open the withdrawal screen to help you withdraw funds to your bank account.`;
            actionType = 'NAVIGATE_WITHDRAW';
        }
        else if (text.includes('history') || text.includes('transactions') || text.includes('records')) {
            reply = `Here is your transaction history page. Let me open it for you.`;
            actionType = 'NAVIGATE_HISTORY';
        }
        return res.json({
            success: true,
            reply,
            action: {
                type: actionType,
                payload
            }
        });
    }
    catch (error) {
        console.error('aiChat error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.aiChat = aiChat;
//# sourceMappingURL=support.controller.js.map