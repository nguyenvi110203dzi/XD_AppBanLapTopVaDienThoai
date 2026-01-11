// src/models/ChatMessage.js
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db'); // Đảm bảo đường dẫn này đúng

const ChatMessage = sequelize.define('chat_message', {
  id: {
    type: DataTypes.INTEGER, // KHỚP VỚI users.id (int(11))
    primaryKey: true,
    autoIncrement: true,
  },
  conversation_id: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  sender_id: {
    type: DataTypes.INTEGER, // KHỚP VỚI users.id (int(11))
    allowNull: false,
    references: {
      model: 'users', // Tên bảng users
      key: 'id',
    }
  },
  sender_role: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  recipient_id: {
    type: DataTypes.INTEGER, // KHỚP VỚI users.id (int(11))
    allowNull: true,
    references: {
      model: 'users', // Tên bảng users
      key: 'id',
    },
    defaultValue: null
  },
  message_text: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  timestamp: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'chat_messages',
  timestamps: true,
});

module.exports = ChatMessage;