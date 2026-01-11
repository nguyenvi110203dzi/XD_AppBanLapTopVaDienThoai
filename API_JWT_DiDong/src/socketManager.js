// src/socketManager.js
let ioInstance = null;
const connectedUsers = {}; // Format: { userId: { socketId: string, role: number, name: string } }
const adminSockets = new Map(); // Format: { adminUserId: socketId }

const initializeSocketManager = (io) => {
  ioInstance = io;
  // Logic io.on('connection') nên được chuyển một phần hoặc hoàn toàn vào đây
  // hoặc server.js sẽ cập nhật connectedUsers và adminSockets trong module này.
  // For simplicity, server.js can continue to manage these and we export them.
};

module.exports = {
  initializeSocketManager,
  get ioInstance() { return ioInstance; }, // Getter để đảm bảo luôn lấy instance mới nhất
  connectedUsers,
  adminSockets,
};