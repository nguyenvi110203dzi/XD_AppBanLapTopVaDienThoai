# Laptop Shop API

A RESTful API for a laptop e-commerce website built with Node.js, Express, and MySQL.

## Features

- User authentication with JWT (JSON Web Tokens)
- Role-based authorization (Admin and User)
- Product management
- Brand and category management
- Order management with status tracking
- Feedback system
- Banner management
- File uploads for images

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user and get token
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update user profile

### Products

- `GET /api/products/new` - Get latest 8 products
- `GET /api/products/brand/:brandId/limit` - Get 8 products by brand
- `GET /api/products/brand/:brandId` - Get all products by brand
- `GET /api/products/category/:categoryId/limit` - Get 8 products by category
- `GET /api/products/category/:categoryId` - Get all products by category
- `GET /api/products/:id` - Get product details
- `GET /api/products` - Get all products
- `POST /api/products` - Create a product (Admin only)
- `PUT /api/products/:id` - Update a product (Admin only)
- `DELETE /api/products/:id` - Delete a product (Admin only)

### Brands

- `GET /api/brands` - Get all brands
- `GET /api/brands/:id` - Get brand details
- `POST /api/brands` - Create a brand (Admin only)
- `PUT /api/brands/:id` - Update a brand (Admin only)
- `DELETE /api/brands/:id` - Delete a brand (Admin only)

### Categories

- `GET /api/categories` - Get all categories
- `GET /api/categories/:id` - Get category details
- `POST /api/categories` - Create a category (Admin only)
- `PUT /api/categories/:id` - Update a category (Admin only)
- `DELETE /api/categories/:id` - Delete a category (Admin only)

### Feedbacks

- `GET /api/feedbacks/product/:productId` - Get feedbacks by product ID
- `POST /api/feedbacks` - Create a feedback (Authenticated users only)
- `PUT /api/feedbacks/:id` - Update a feedback (Owner only)
- `DELETE /api/feedbacks/:id` - Delete a feedback (Owner only)

### Orders

- `GET /api/orders` - Get all orders (Admin only)
- `GET /api/orders/:id` - Get order details (Admin only)
- `GET /api/orders/myorders` - Get user's orders (Authenticated users only)
- `POST /api/orders` - Create an order (Authenticated users only)
- `PUT /api/orders/:id/status` - Update order status (Admin only)
- `DELETE /api/orders/:id` - Delete an order (Admin only)
- `GET /api/orders/details/:orderId` - Get order details

### Banners

- `GET /api/banners` - Get all banners
- `GET /api/banners/:id` - Get banner details
- `POST /api/banners` - Create a banner (Admin only)
- `PUT /api/banners/:id` - Update a banner (Admin only)
- `DELETE /api/banners/:id` - Delete a banner (Admin only)

### Users

- `GET /api/users` - Get all users (Admin only)
- `GET /api/users/:id` - Get user details (Admin only)
- `PUT /api/users/:id` - Update a user (Admin only)
- `DELETE /api/users/:id` - Delete a user (Admin only)

## Order Status

- 0: Chưa xác nhận (Not confirmed)
- 1: Xác nhận (Confirmed)
- 2: Đang giao (In delivery)
- 3: Đã giao (Delivered)
- 4: Đã hủy (Cancelled)

## Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Create a `.env` file with the following variables:
   ```
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=
   DB_NAME=dbbanlaptop
   JWT_SECRET=your_jwt_secret
   PORT=3000
   ```
4. Import the database schema from `dbbanlaptop.sql`
5. Start the server: `npm start` or `npm run dev` for development

## Technologies Used

- Node.js
- Express
- MySQL
- Sequelize ORM
- JWT for authentication
- Multer for file uploads
