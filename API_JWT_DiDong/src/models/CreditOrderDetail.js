const { DataTypes } = require('sequelize');
const sequelize = require('../config/db'); // Đảm bảo đường dẫn này đúng

const CreditOrderDetail = sequelize.define('credit_order_detail', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    credit_order_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { // Khai báo khóa ngoại
            model: 'credit_orders', // Tên bảng mà nó tham chiếu đến
            key: 'id'
        }
    },
    product_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { // Khai báo khóa ngoại
            model: 'products', // Tên bảng mà nó tham chiếu đến
            key: 'id'
        }
    },
    price: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: 'Giá sản phẩm tại thời điểm mua công nợ'
    },
    quantity: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 1
    }
    // createdAt và updatedAt sẽ được Sequelize tự động quản lý
}, {
    tableName: 'credit_order_details', // Quan trọng: Đảm bảo tên bảng khớp với CSDL
    timestamps: true // Bật timestamps (createdAt, updatedAt)
});

module.exports = CreditOrderDetail;