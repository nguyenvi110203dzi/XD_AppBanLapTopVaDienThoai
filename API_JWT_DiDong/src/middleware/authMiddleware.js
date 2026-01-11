const jwt = require('jsonwebtoken');
const { User } = require('../models');

const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Get user from the token
      req.user = await User.findByPk(decoded.id, {
        attributes: { exclude: ['password'] }
      });

      if (!req.user) {
        // Nếu không tìm thấy user với ID trong token (dù token hợp lệ)
        return res.status(401).json({ message: 'Not authorized, không tìm thấy' });
        // Dùng return để không chạy xuống next()
      }

      next();
    } catch (error) {
      console.error(error);
      res.status(401).json({ message: 'Not authorized, không thể kết nối tới server' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, không có token' });
  }
};

module.exports = { protect };