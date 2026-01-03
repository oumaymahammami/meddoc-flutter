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
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendReminders = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
// Scheduled function: send pending reminders every 15 minutes.
exports.sendReminders = functions.pubsub
    .schedule('every 15 minutes')
    .timeZone('UTC')
    .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snap = await db
        .collection('notifications')
        .where('sent', '==', false)
        .where('sendAt', '<=', now)
        .limit(300)
        .get();
    const batch = db.batch();
    for (const doc of snap.docs) {
        const data = doc.data();
        const receiverId = data.receiverId;
        const userDoc = await db.collection('users').doc(receiverId).get();
        const token = userDoc.get('fcmToken');
        const enabled = userDoc.get('notificationsEnabled') !== false;
        if (token && enabled) {
            await admin.messaging().send({
                token,
                notification: {
                    title: data.title ?? 'Rappel',
                    body: data.body ?? '',
                },
                data: {
                    appointmentId: data.appointmentId ?? '',
                    receiverRole: data.receiverRole ?? '',
                },
            });
        }
        batch.update(doc.ref, {
            sent: true,
            updatedAt: admin.firestore.Timestamp.now(),
        });
    }
    if (!snap.empty) {
        await batch.commit();
    }
    return null;
});
//# sourceMappingURL=index.js.map