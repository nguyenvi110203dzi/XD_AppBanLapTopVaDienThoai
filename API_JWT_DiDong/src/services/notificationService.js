// src/services/notificationService.js
const { User, CreditOrder } = require('../models'); // Giả định models đã được setup đúng
const { connectedUsers, adminSockets, ioInstance } = require('../socketManager'); // Sẽ tạo file này

const sendPaymentReminder = async (creditOrder) => {
  try {
    const user = await User.findByPk(creditOrder.user_id);
    if (!user) {
      console.error(`[NotificationService] User not found for credit order ID: ${creditOrder.id}`);
      return;
    }

    const messageToUser = `Đơn hàng công nợ #${creditOrder.id} trị giá ${creditOrder.total.toLocaleString('vi-VN')} VNĐ của bạn sẽ đến hạn thanh toán vào ngày ${new Date(creditOrder.due_date).toLocaleDateString('vi-VN')}. Vui lòng thanh toán đúng hạn.`;
    const messageToAdmin = `Khách hàng ${user.name} (ID: ${user.id}) có đơn hàng công nợ #${creditOrder.id} sắp đến hạn thanh toán vào ngày ${new Date(creditOrder.due_date).toLocaleDateString('vi-VN')}.`;

    // 1. Gửi qua Socket.IO cho User nếu họ online
    if (connectedUsers[user.id] && connectedUsers[user.id].socketId && ioInstance) {
      ioInstance.to(connectedUsers[user.id].socketId).emit('payment_reminder', {
        orderId: creditOrder.id,
        message: messageToUser,
        dueDate: creditOrder.due_date
      });
      console.log(`[NotificationService] Sent payment reminder via Socket.IO to user ${user.name} for order #${creditOrder.id}`);
    } else {
      console.log(`[NotificationService] User ${user.name} (ID: ${user.id}) is offline. Socket.IO reminder for order #${creditOrder.id} not sent.`);
      // TODO: Ở đây có thể thêm logic gửi Email hoặc SMS nếu user offline
    }

    // 2. Gửi qua Socket.IO cho tất cả Admin đang online
    if (ioInstance) {
        adminSockets.forEach(adminSocketId => {
            ioInstance.to(adminSocketId).emit('admin_payment_reminder_alert', {
                orderId: creditOrder.id,
                userName: user.name,
                userId: user.id,
                message: messageToAdmin,
                dueDate: creditOrder.due_date
            });
        });
        console.log(`[NotificationService] Sent payment reminder alert via Socket.IO to admins for order #${creditOrder.id}`);
    }


    // TODO: 3. Gửi Email cho User (Cần tích hợp Nodemailer hoặc dịch vụ tương tự)
    // Ví dụ: await emailService.sendEmail(user.email, 'Nhắc nhở thanh toán đơn hàng công nợ', messageToUser);
    //console.log(`[NotificationService] TODO: Send email reminder to ${user.email} for order #${creditOrder.id}`);


    // TODO: 4. Gửi SMS/Zalo ZNS cho User (Cần tích hợp dịch vụ của bên thứ ba)
    // Ví dụ: await smsService.sendSMS(user.phone, messageToUser);
    //console.log(`[NotificationService] TODO: Send SMS/ZNS reminder to ${user.phone} for order #${creditOrder.id}`);


  } catch (error) {
    console.error(`[NotificationService] Error sending reminder for credit order ID ${creditOrder.id}:`, error);
  }
};

module.exports = {
  sendPaymentReminder
};