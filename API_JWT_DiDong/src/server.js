const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const jwt = require('jsonwebtoken');
const cron = require('node-cron');
const { Op } = require('sequelize');
const { addDays, formatISO, startOfDay, endOfDay } = require('date-fns');

// Import routes
const authRoutes = require('./routes/authRoutes');
const productRoutes = require('./routes/productRoutes');
const brandRoutes = require('./routes/brandRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const bannerRoutes = require('./routes/bannerRoutes');
const orderRoutes = require('./routes/orderRoutes');
const userRoutes = require('./routes/userRoutes');
const adminSpecRoutes = require('./routes/adminSpecRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const baoHanhRoutes = require('./routes/baoHanhRoutes');
const creditOrderRoutes = require('./routes/creditOrderRoutes');
const warehouseRoutes = require('./routes/warehouseRoutes');


// Import models
const { User, ChatMessage, CreditOrder } = require('./models'); // Đảm bảo ChatMessage được import nếu bạn lưu chat
const { sendPaymentReminder } = require('./services/notificationService');
const socketManager = require('./socketManager');
// Load environment variables
dotenv.config();

// Database connection
// Sử dụng biến sequelize nếu bạn đã đặt tên là sequelize trong db.js
// const sequelize = require('./config/db'); // Hoặc là db nếu export default là db
// sequelize.authenticate()
//   .then(() => console.log('Database connected...'))
//   .catch(err => console.log('Error connecting to database: ' + err));

// Dựa trên file bạn cung cấp, bạn dùng 'db'
const db = require('./config/db');
db.authenticate()
  .then(() => console.log('Database connected...'))
  .catch(err => console.log('Error connecting to database: ' + err));


// Initialize express app
const app = express();

// Middleware
app.use(cors()); // CORS cho Express requests
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static folder for uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Express Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/brands', brandRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/banners', bannerRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminSpecRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/baohanh', baoHanhRoutes);
app.use('/api/credit-orders', creditOrderRoutes);
app.use('/api/warehouse', warehouseRoutes);


// Default Express route
app.get('/', (req, res) => {
  res.send('Laptop Shop API is running...');
});

// Tạo HTTP server từ Express app
const httpServer = http.createServer(app);

// Khởi tạo Socket.IO server và gắn nó vào httpServer
const io = new Server(httpServer, {
  cors: {
    origin: "*", // Cho phép tất cả các origin khi test,
    // Thay bằng domain/IP của Flutter app trong production
    methods: ["GET", "POST"]
  }
});

socketManager.initializeSocketManager(io);
// --- Socket.IO Logic ---
// KHAI BÁO CÁC BIẾN NÀY Ở SCOPE NGOÀI ĐỂ io.on('connection') CÓ THỂ TRUY CẬP
const connectedUsers = {}; // Format: { userId: { socketId: string, role: number, name: string } }
const adminSockets = new Map(); // Format: { adminUserId: socketId }

io.on('connection', async (socket) => {
  console.log(`Socket connected: ${socket.id}`);

  let currentUserId = null;
  let currentUserRole = null;
  let currentUserName = null;

  // 1. Xác thực user qua token khi kết nối
  const token = socket.handshake.auth.token;
  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findByPk(decoded.id, { attributes: ['id', 'name', 'role'] });

      if (user) {
        currentUserId = user.id;
        currentUserRole = user.role;
        currentUserName = user.name;

        connectedUsers[currentUserId] = { // Gán vào biến đã khai báo ở ngoài
          socketId: socket.id,
          role: currentUserRole,
          name: currentUserName
        };
        console.log(`User ${currentUserName} (ID: ${currentUserId}, Role: ${currentUserRole === 1 ? 'Admin' : 'User'}) authenticated for chat. Socket ID: ${socket.id}`);

        if (currentUserRole === 1) { // Nếu là admin
          adminSockets.set(currentUserId, socket.id); // Gán vào biến đã khai báo ở ngoài
          console.log(`Admin ${currentUserName} (ID: ${currentUserId}) added to admin list.`);
        } else { // Nếu là user thường
          socket.emit('receive_message', {
            senderId: 'SYSTEM_ADMIN',
            senderName: 'Hỗ trợ viên',
            text: 'Xin chào! Shop Dzi có thể giúp gì cho bạn?</br>Thời gian lam việc: 8h - 17h từ thứ 2 đến thứ 7.</br>Chúng tôi sẽ phản hồi bạn trong thời gian sớm nhất.',
            timestamp: new Date().toISOString(),
            isMine: false
          });
          console.log(`Welcome message sent to user ${currentUserName} (ID: ${currentUserId})`);

          adminSockets.forEach(adminSocketId => { // Sử dụng biến đã khai báo ở ngoài
            io.to(adminSocketId).emit('user_connected_chat', {
              userId: currentUserId,
              userName: currentUserName,
              message: `${currentUserName} vừa kết nối để được hỗ trợ.`,
              timestamp: new Date().toISOString()
            });
          });
        }
      } else {
        console.log('Chat Auth: User not found with token ID.');
        socket.disconnect();
        return;
      }
    } catch (error) {
      console.error('Chat Auth Error:', error.message);
      socket.disconnect();
      return;
    }
  } else {
    console.log('Chat: Connection attempt without token. Disconnecting.');
    socket.disconnect();
    return;
  }

  // 2. Lắng nghe sự kiện 'send_message' từ client
  socket.on('send_message', async (data) => {
    if (!currentUserId) {
      console.log("Cannot send message, user not authenticated for this socket.");
      socket.emit('send_message_error', { message: 'Lỗi xác thực, không thể gửi tin nhắn.' });
      return;
    }

    const text = data.text;
    if (!text || text.trim() === "") {
      socket.emit('send_message_error', { message: 'Nội dung tin nhắn không được để trống.' });
      return;
    }

    console.log(`Message from ${currentUserName} (ID: ${currentUserId}): "${text}" to recipient: ${data.recipientId || 'Admins'}`);

    const messageTimestamp = new Date();
    let conversationId;
    let dbRecipientId = null;

    if (currentUserRole === 0) { // User (khách hàng) gửi tin nhắn
      conversationId = currentUserId.toString();
    } else if (currentUserRole === 1) { // Admin gửi tin nhắn
      if (!data.recipientId) {
        console.log(`Admin ${currentUserId} send_message event without recipientId.`);
        socket.emit('send_message_error', { message: 'Vui lòng chọn người nhận.' });
        return;
      }
      conversationId = data.recipientId.toString();
      dbRecipientId = parseInt(data.recipientId); // Đảm bảo là số nếu ID user là số
    } else {
      socket.emit('send_message_error', { message: 'Vai trò không hợp lệ để gửi tin nhắn.' });
      return;
    }

    try {
      const savedMessage = await ChatMessage.create({
        conversation_id: conversationId,
        sender_id: currentUserId,
        sender_role: currentUserRole,
        recipient_id: dbRecipientId,
        message_text: text,
        timestamp: messageTimestamp,
      });

      const messagePayload = {
        id: savedMessage.id,
        senderId: currentUserId.toString(),
        senderName: currentUserName,
        text: text,
        timestamp: messageTimestamp.toISOString(),
        conversationId: conversationId,
      };

      if (currentUserRole === 0) {
        if (adminSockets.size > 0) {
          adminSockets.forEach(adminSocketId => {
            io.to(adminSocketId).emit('receive_message', messagePayload);

            io.to(adminSocketId).emit('new_consultation_request_notification', {
              userId: currentUserId.toString(),
              userName: currentUserName,
              messageText: text, // Nội dung tin nhắn để hiển thị một phần
              timestamp: messageTimestamp.toISOString(),
              conversationId: conversationId, // Để admin có thể click vào thông báo và mở đúng cuộc trò chuyện
            });
          });
          console.log(`Message ID ${savedMessage.id} from user ${currentUserId} relayed to ${adminSockets.size} admin(s).`);
        } else {
          console.log('No admins online to receive message from user', currentUserId);
          socket.emit('system_message', {
            text: 'Hiện tại không có hỗ trợ viên nào trực tuyến. Chúng tôi đã ghi nhận tin nhắn của bạn và sẽ phản hồi sớm nhất có thể.',
            timestamp: new Date().toISOString(),
          });
        }
      } else if (currentUserRole === 1) {
        const recipientInfo = connectedUsers[data.recipientId]; // Sử dụng biến đã khai báo ở ngoài
        if (recipientInfo && recipientInfo.socketId) {
          io.to(recipientInfo.socketId).emit('receive_message', messagePayload);
          console.log(`Message ID ${savedMessage.id} from Admin ${currentUserId} sent to User ${data.recipientId}`);
        } else {
          console.log(`Admin ${currentUserId} trying to send message to offline or non-existent user: ${data.recipientId}. Message saved.`);
        }
      }
      socket.emit('message_saved_confirmation', {
        tempId: data.tempId, // Nếu client gửi ID tạm
        savedMessage: messagePayload
      });

    } catch (error) {
      console.error('Error saving or sending message:', error);
      socket.emit('send_message_error', { message: 'Lỗi khi gửi hoặc lưu tin nhắn.' });
    }
  });

  // 3. API/Event để client tải lịch sử chat cho một conversation
  socket.on('load_chat_history', async (data) => {
    if (!currentUserId) return;

    const conversationIdToLoad = data.conversationId;
    const limit = parseInt(data.limit) || 50;
    const offset = parseInt(data.offset) || 0;

    if (!conversationIdToLoad) {
      socket.emit('chat_history_error', { message: 'Thiếu thông tin cuộc trò chuyện.' });
      return;
    }

    if (currentUserRole === 0 && currentUserId.toString() !== conversationIdToLoad) {
      socket.emit('chat_history_error', { message: 'Không có quyền truy cập lịch sử chat này.' });
      return;
    }

    try {
      const messages = await ChatMessage.findAll({
        where: { conversation_id: conversationIdToLoad },
        include: [{ model: User, as: 'sender', attributes: ['id', 'name', 'role', 'avatar'] }],
        order: [['timestamp', 'DESC']],
        limit: limit,
        offset: offset,
      });

      const formattedMessages = messages.reverse().map(msg => ({
        id: msg.id,
        senderId: msg.sender_id.toString(),
        senderName: msg.sender ? msg.sender.name : 'Unknown',
        senderAvatar: msg.sender ? msg.sender.avatar : null,
        text: msg.message_text,
        timestamp: msg.timestamp.toISOString(),
        conversationId: msg.conversation_id,
      }));

      socket.emit('chat_history', {
        conversationId: conversationIdToLoad,
        messages: formattedMessages,
        hasMore: messages.length === limit,
      });
      console.log(`Loaded ${formattedMessages.length} messages for conversation ${conversationIdToLoad} for socket ${socket.id}`);
    } catch (error) {
      console.error('Error loading chat history:', error);
      socket.emit('chat_history_error', { message: 'Lỗi tải lịch sử trò chuyện.' });
    }
  });

  // 4. Xử lý khi client ngắt kết nối
  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}. User ID: ${currentUserId || 'Unknown'}`);
    if (currentUserId) {
      if (currentUserRole === 1) {
        adminSockets.delete(currentUserId); // Sử dụng biến đã khai báo ở ngoài
        console.log(`Admin ${currentUserName} (ID: ${currentUserId}) removed from admin list.`);
      } else {
        adminSockets.forEach(adminSocketId => { // Sử dụng biến đã khai báo ở ngoài
          io.to(adminSocketId).emit('user_disconnected_chat', {
            userId: currentUserId,
            userName: currentUserName,
            message: `${currentUserName} đã ngắt kết nối.`,
            timestamp: new Date().toISOString()
          });
        });
      }
      delete connectedUsers[currentUserId]; // Sử dụng biến đã khai báo ở ngoài
    }
  });

  // Xử lý lỗi chung của socket
  socket.on("error", (err) => {
    console.error(`Socket Error on ${socket.id}:`, err);
  });
});
// --- END Socket.IO Logic ---

// --- Cron Job cho Nhắc nhở Thanh toán Công Nợ ---
// Chạy vào 12:00 PM (trưa) mỗi ngày. ('0 12 * * *')
// Giờ Việt Nam (GMT+7). Nếu server chạy giờ UTC, cần điều chỉnh.
// Ví dụ, nếu server là UTC, 12h trưa VN là 5h sáng UTC. Cron sẽ là '0 5 * * *'
// Để đơn giản, giả sử server đang chạy giờ địa phương (GMT+7)
cron.schedule('0 12 * * *', async () => {
  console.log(`[CronJob] Running daily check for credit payment reminders at 12:00 PM - ${new Date()}`);
  try {
    const today = new Date();
    const reminderDate = addDays(today, 5); // Ngày record due_date sẽ là 5 ngày nữa

    // Tìm các đơn hàng có due_date chính xác là 5 ngày kể từ hôm nay
    // và status là "Chờ thanh toán" (0)
    const upcomingDueOrders = await CreditOrder.findAll({
      where: {
        status: 0, // 0: Chờ thanh toán
        due_date: {
          [Op.gte]: startOfDay(reminderDate), // Bắt đầu của ngày reminderDate
          [Op.lte]: endOfDay(reminderDate)    // Kết thúc của ngày reminderDate
        },
        payment_date: null // Chưa thanh toán
      }
    });

    if (upcomingDueOrders.length > 0) {
      console.log(`[CronJob] Found ${upcomingDueOrders.length} credit orders due in 5 days.`);
      for (const order of upcomingDueOrders) {
        console.log(`[CronJob] Processing reminder for order ID: ${order.id}, Due: ${order.due_date}`);
        await sendPaymentReminder(order);
      }
    } else {
      console.log('[CronJob] No credit orders due in 5 days found for reminder.');
    }
  } catch (error) {
    console.error('[CronJob] Error checking for credit payment reminders:', error);
  }
}, {
  scheduled: true,
  timezone: "Asia/Ho_Chi_Minh" // Quan trọng: Đặt múi giờ cho cron job
});
// --- END Cron Job ---

// Khởi động server HTTP (đã gắn Express app và Socket.IO server)
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Socket.IO is listening on port ${PORT}`);
});