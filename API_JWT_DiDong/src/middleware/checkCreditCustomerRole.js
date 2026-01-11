const checkCreditCustomerRole = (req, res, next) => {
    // Giả định rằng middleware 'protect' đã chạy trước và gán req.user
    if (req.user && req.user.role === 2) {
        next(); // Cho phép tiếp tục nếu là role 2
    } else {
        res.status(403).json({ message: 'Not authorized. Only credit customers (role 2) can perform this action.' });
    }
};

module.exports = { checkCreditCustomerRole };