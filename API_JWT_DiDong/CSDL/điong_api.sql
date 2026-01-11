-- Tạo cơ sở dữ liệu
CREATE DATABASE IF NOT EXISTS didong_api;
USE didong_api;

-- Tạo bảng users
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role INT DEFAULT 0 -- 0: user, 1: admin
);

-- Thêm dữ liệu mẫu cho bảng users
INSERT INTO users (user_name, password, role) VALUES
('admin', '$2b$10$eBz1J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ', 1), -- password: admin123
('user1', '$2b$10$eBz1J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ', 0), -- password: user123
('user2', '$2b$10$eBz1J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ', 0),
('user3', '$2b$10$eBz1J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ', 0),
('user4', '$2b$10$eBz1J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ9J9m1FJ', 0);

-- Tạo bảng categories
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    hinhanh VARCHAR(255)
);

-- Thêm dữ liệu mẫu cho bảng categories
INSERT INTO categories (name, hinhanh) VALUES
('Electronics', '/images/categories/electronics.jpg'),
('Fashion', '/images/categories/fashion.jpg'),
('Home Appliances', '/images/categories/home_appliances.jpg'),
('Books', '/images/categories/books.jpg'),
('Toys', '/images/categories/toys.jpg');

-- Tạo bảng brands
CREATE TABLE brands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    hinhanh VARCHAR(255)
);

-- Thêm dữ liệu mẫu cho bảng brands
INSERT INTO brands (name, hinhanh) VALUES
('Apple', '/images/brands/apple.jpg'),
('Samsung', '/images/brands/samsung.jpg'),
('Sony', '/images/brands/sony.jpg'),
('LG', '/images/brands/lg.jpg'),
('Nike', '/images/brands/nike.jpg');

-- Tạo bảng products
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price FLOAT NOT NULL,
    hinhanh VARCHAR(255),
    mota TEXT,
    soluong INT NOT NULL,
    id_brand INT,
    id_category INT,
    FOREIGN KEY (id_brand) REFERENCES brands(id),
    FOREIGN KEY (id_category) REFERENCES categories(id)
);

-- Thêm dữ liệu mẫu cho bảng products
INSERT INTO products (name, price, hinhanh, mota, soluong, id_brand, id_category) VALUES
('iPhone 13', 999.99, '/images/products/iphone13.jpg', '<p>Latest iPhone model</p>', 50, 1, 1),
('Galaxy S21', 799.99, '/images/products/galaxy_s21.jpg', '<p>Flagship Samsung phone</p>', 30, 2, 1),
('Sony Headphones', 199.99, '/images/products/sony_headphones.jpg', '<p>Noise-cancelling headphones</p>', 100, 3, 1),
('LG TV', 499.99, '/images/products/lg_tv.jpg', '<p>4K Ultra HD TV</p>', 20, 4, 1),
('Nike Shoes', 149.99, '/images/products/nike_shoes.jpg', '<p>Comfortable running shoes</p>', 200, 5, 2);

-- Tạo bảng orders
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT,
    trangthai INT DEFAULT 0, -- 0: chưa xác nhận, 1: đã xác nhận, 2: đã giao, 3: đã nhận
    price FLOAT NOT NULL,
    ghichu TEXT,
    FOREIGN KEY (id_user) REFERENCES users(id)
);

-- Thêm dữ liệu mẫu cho bảng orders
INSERT INTO orders (id_user, trangthai, price, ghichu) VALUES
(2, 1, 999.99, 'Deliver to home'),
(3, 2, 799.99, 'Deliver to office'),
(4, 3, 199.99, 'Gift for friend'),
(5, 0, 499.99, 'Pending confirmation'),
(2, 1, 149.99, 'Urgent delivery');

-- Tạo bảng orders_detail
CREATE TABLE orders_detail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_order INT NOT NULL,
    id_products INT NOT NULL,
    soluong INT NOT NULL,
    price FLOAT NOT NULL,
    FOREIGN KEY (id_order) REFERENCES orders(id),
    FOREIGN KEY (id_products) REFERENCES products(id)
);

-- Thêm dữ liệu mẫu cho bảng orders_detail
INSERT INTO orders_detail (id_order, id_products, soluong, price) VALUES
(1, 1, 1, 999.99),
(2, 2, 1, 799.99),
(3, 3, 2, 399.98),
(4, 4, 1, 499.99),
(5, 5, 3, 449.97);