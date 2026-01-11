const User = require('./user');
const Product = require('./product');
const Brand = require('./Brand');
const Category = require('./category');
const Order = require('./order');
const OrderDetail = require('./orderDetail');
const Banner = require('./banner');
const Cauhinh_bonho = require('./cauhinh_bonho');
const Camera_manhinh = require('./camera_manhinh');
const Pin_sac = require('./Pin_sac');
const ChatMessage = require('./ChatMessage');
const BaoHanh = require('./BaoHanh');
const CreditOrder = require('./CreditOrder');
const CreditOrderDetail = require('./CreditOrderDetail');
const InventoryTransaction = require('./InventoryTransaction');


// Brand - Product association
Brand.hasMany(Product, { foreignKey: 'brand_id' });
Product.belongsTo(Brand, { foreignKey: 'brand_id' });

// Category - Product association
Category.hasMany(Product, { foreignKey: 'category_id' });
Product.belongsTo(Category, { foreignKey: 'category_id' });


// User - Order association
User.hasMany(Order, { foreignKey: 'user_id' });
Order.belongsTo(User, { foreignKey: 'user_id' });


// Product - OrderDetail 
Order.hasMany(OrderDetail, { foreignKey: 'order_id' });
OrderDetail.belongsTo(Order, { foreignKey: 'order_id' });
// Product - OrderDetail 


// Product - camera_manhinh 
Product.hasOne(Camera_manhinh, { foreignKey: 'id_product' });
Camera_manhinh.belongsTo(Product, { foreignKey: 'id_product' });

// Product - cauhinh_bonho 
Product.hasOne(Cauhinh_bonho, { foreignKey: 'id_product' });
Cauhinh_bonho.belongsTo(Product, { foreignKey: 'id_product' });

// Product - Pin_sac 
Product.hasOne(Pin_sac, { foreignKey: 'id_product' });
Pin_sac.belongsTo(Product, { foreignKey: 'id_product' });

User.hasMany(ChatMessage, { foreignKey: 'sender_id' });
ChatMessage.belongsTo(User, { foreignKey: 'sender_id' });

User.hasMany(ChatMessage, { foreignKey: 'recipient_id' });
ChatMessage.belongsTo(User, { foreignKey: 'recipient_id' });

// OrderDetail - BaoHanh 
OrderDetail.hasMany(BaoHanh, { foreignKey: 'id_chi_tiet_don_hang', as: 'baoHanhs' });
BaoHanh.belongsTo(OrderDetail, { foreignKey: 'id_chi_tiet_don_hang', as: 'order_details' });
// Một OrderDetail thuộc về một Product
OrderDetail.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
// Một Product có thể có nhiều OrderDetail
Product.hasMany(OrderDetail, { foreignKey: 'product_id', as: 'order_details' });

// User - CreditOrder association
User.hasMany(CreditOrder, { foreignKey: 'user_id', as: 'creditOrders' });
CreditOrder.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// CreditOrder - CreditOrderDetail association
CreditOrder.hasMany(CreditOrderDetail, { foreignKey: 'credit_order_id', as: 'creditOrderDetails' });
CreditOrderDetail.belongsTo(CreditOrder, { foreignKey: 'credit_order_id', as: 'creditOrder' });

// Product - CreditOrderDetail association
// Một CreditOrderDetail thuộc về một Product
CreditOrderDetail.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
// Một Product có thể có trong nhiều CreditOrderDetail
Product.hasMany(CreditOrderDetail, { foreignKey: 'product_id', as: 'creditOrderDetails' });

InventoryTransaction.belongsTo(Product, { foreignKey: 'product_id' });
Product.hasMany(InventoryTransaction, { foreignKey: 'product_id' });

InventoryTransaction.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(InventoryTransaction, { foreignKey: 'user_id' });

InventoryTransaction.belongsTo(Order, { foreignKey: 'order_id' });
Order.hasMany(InventoryTransaction, { foreignKey: 'order_id' });


module.exports = {
  User,
  Product,
  Brand,
  Category,
  Order,
  OrderDetail,
  Banner,
  Cauhinh_bonho,
  Camera_manhinh,
  Pin_sac,
  ChatMessage,
  BaoHanh,
  CreditOrder,
  CreditOrderDetail,
  InventoryTransaction,
};