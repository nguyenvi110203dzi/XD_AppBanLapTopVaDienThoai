const admin = (req, res, next) => {
    if (req.user && req.user.role === 1) {
      next();
    } else {
      res.status(403).json({ message: 'Not authorized không phải admin' });
    }
  };
  const warehouseStaff = (req, res, next) => {
  // req.user được lấy từ middleware 'protect'
  if (req.user && req.user.role === 3) { // Giả sử role 3 là Warehouse Staff
    next();
  } else if (req.user && req.user.role === 1) { // Cho phép Admin cũng có quyền này
    next();
  }
  else {
    res.status(403).json({ message: 'Không được phép. Chỉ người nhập kho hoặc Admin mới có quyền truy cập.' });
  }
};

  
  module.exports = { admin, warehouseStaff };