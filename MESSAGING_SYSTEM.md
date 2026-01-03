# 💬 Messaging System - Complete Documentation

## Overview
A real-time messaging system allowing doctors and patients to communicate directly through the app.

## 🏗️ Architecture

### Firestore Collections
```
conversations/
├── {conversationId}
│   ├── doctorId: string
│   ├── patientId: string
│   ├── doctorName: string
│   ├── patientName: string
│   ├── lastMessage: string
│   ├── lastMessageTime: timestamp
│   ├── doctorUnreadCount: number
│   ├── patientUnreadCount: number
│   ├── createdAt: timestamp
│   └── messages/ (subcollection)
│       └── {messageId}
│           ├── senderId: string
│           ├── text: string
│           ├── createdAt: timestamp
│           └── read: boolean
```

### Security Rules
- Users can only read conversations where they are a participant
- Messages can only be read/written by conversation participants
- Each message validates that the sender is part of the conversation

## 📱 User Interface

### 1. Patient Dashboard
**Location:** Patient Home Page → Quick Actions → "Messages" button
- Pink gradient card with chat bubble icon
- Opens conversations list for the patient

### 2. Doctor Dashboard
**Location:** Doctor Dashboard → Quick Actions Grid → "Messages" button
- Pink gradient card with chat bubble icon
- Opens conversations list for the doctor

### 3. Doctor Profile Page
**Location:** Doctor Detail Page → Message button (next to Book Appointment)
- Blue button with chat icon
- Starts a new conversation or opens existing one

## 🔄 User Flow

### Starting a Conversation (Patient → Doctor)
1. Patient visits doctor's profile page
2. Clicks "Message" button
3. System checks for existing conversation:
   - If exists: Opens ChatPage with existing conversation
   - If new: Creates conversation document and opens ChatPage
4. Patient can send messages immediately

### Viewing Conversations
1. User clicks "Messages" from dashboard
2. ConversationsPage shows all conversations:
   - Sorted by most recent message
   - Shows last message preview
   - Displays unread count badge
   - Shows time/date of last message

### Chatting
1. User selects a conversation
2. ChatPage opens with real-time message stream
3. Messages appear in bubbles:
   - Sender (current user): Blue gradient, right-aligned
   - Receiver (other user): White, left-aligned
4. When page opens:
   - Marks all messages as read
   - Clears unread count for current user
5. User can type and send messages

## 🎨 UI Features

### ConversationsPage
- **Time Formatting:**
  - Today: "HH:mm" (e.g., "14:30")
  - Yesterday: "Hier"
  - This week: Day name (e.g., "Lundi")
  - Older: "dd/MM" (e.g., "15/03")
- **Unread Badge:** Red circular badge with count
- **Avatar:** Circular colored avatar with first letter
- **Empty State:** "Aucune conversation" message

### ChatPage
- **Header:**
  - Back button
  - Participant name
  - Avatar
- **Messages:**
  - Sender: Blue gradient (#2E63D9 to #2D9CDB), right side
  - Receiver: White with border, left side
  - Timestamp below each message
- **Input:**
  - TextField with hint "Tapez un message..."
  - Blue circular send button with arrow icon
  - Auto-scrolls to bottom when sending

## 🔧 Technical Implementation

### Key Files
1. **lib/shared/pages/conversations_page.dart** (219 lines)
   - Lists all conversations for a user
   - Real-time updates with StreamBuilder
   - Navigation to ChatPage

2. **lib/shared/pages/chat_page.dart** (359 lines)
   - Real-time chat interface
   - Message sending and reading
   - Unread count management

3. **lib/features/patient/pages/doctor_detail_page.dart**
   - `_startConversation()` method (lines 738-811)
   - Creates conversation or opens existing one

4. **firestore.rules**
   - Conversations collection rules (lines ~165-195)
   - Messages subcollection rules

### Real-time Updates
- Uses Firestore `StreamBuilder` for live data
- Messages ordered by `createdAt` descending
- Conversations ordered by `lastMessageTime` descending

### Unread Count Management
- Separate counters for doctor and patient
- Incremented when sending message
- Reset to 0 when recipient opens chat
- Displayed as red badge in conversations list

## 🚀 Testing the System

### Test Scenario 1: Patient messages Doctor
1. Log in as patient
2. Go to "Trouver un médecin"
3. Select a doctor
4. Click "Message" button
5. Send a message
6. Verify message appears in chat
7. Log in as that doctor
8. Check "Messages" has unread badge
9. Open conversation
10. Verify message received
11. Reply to patient
12. Verify real-time update

### Test Scenario 2: Conversation List
1. Create multiple conversations
2. Send messages with different timestamps
3. Verify conversations sorted by most recent
4. Verify time formatting is correct
5. Verify unread badges show correct counts

## 📋 Features Summary

✅ **Completed:**
- Real-time messaging between doctors and patients
- Conversation list with last message preview
- Unread message counters
- Message read status tracking
- Time/date formatting
- Integration in patient dashboard
- Integration in doctor dashboard
- Message button on doctor profile
- Conversation creation logic
- Firestore security rules
- Auto-scroll in chat
- Premium UI design

## 🎯 Future Enhancements (Optional)

- 📎 File/image attachments
- 🔔 Push notifications for new messages
- ✏️ Typing indicators
- ✅ Message read receipts (double checkmark)
- 🔍 Search conversations
- 🗑️ Delete conversations
- 🚫 Block/report users
- 🟢 Online status indicators
- ⭐ Message reactions
- 📤 Export conversation history

## 🐛 Troubleshooting

### Messages not appearing
- Check Firestore rules are deployed: `firebase deploy --only firestore:rules`
- Verify user is authenticated
- Check console for errors

### Unread count not updating
- Verify `_markMessagesAsRead()` is called in ChatPage
- Check that conversation document has correct participant IDs

### Conversation not created
- Verify `_startConversation()` has patient name
- Check that both doctor and patient IDs are valid
- Ensure Firestore write permissions are correct

---

**System Status:** ✅ Fully operational and integrated
**Last Updated:** January 2025
