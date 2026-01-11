#  Hệ Thống Bán Laptop và Thiết Bị Điện Tử

## 📋 Giới Thiệu
 một giải pháp thương mại điện tử toàn diện chuyên kinh doanh các sản phẩm công nghệ (Laptop, Điện thoại, Phụ kiện). Hệ thống bao gồm ứng dụng Mobile đa nền tảng (Android/iOS) dành cho khách hàng/quản trị viên và Backend API mạnh mẽ hỗ trợ các nghiệp vụ phức tạp như bán trả góp, quản lý kho vận và chat trực tuyến.

## Công Nghệ Sử Dụng
| Hạng mục | Công nghệ / Thư viện |
| :--- | :--- |
| **Mobile App** | Flutter (Dart), Clean Architecture, BLoC Pattern |
| **Backend API** | Node.js, Express.js, Socket.io (Real-time) |
| **Database** | MySQL|
| **Quản lý kho** | Logic nhập/xuất tồn |
| **Thanh toán** | Tích hợp VNPay |

---

## 🚀 Tính Năng Nổi Bật
### 1. 📱 Dành Cho Khách Hàng (Client App)
* **Mua sắm thông minh:** Tìm kiếm, lọc sản phẩm theo cấu hình (RAM, CPU, Màn hình...), Thêm vào giỏ hàng.
* **Mua Trả Góp (Credit):** Tính năng duyệt hồ sơ tín dụng và mua hàng trả góp trực tuyến.
* **Chat Support:** Nhắn tin trực tiếp với nhân viên tư vấn qua Socket.io.
* **Quản lý tài khoản:** Theo dõi lịch sử đơn hàng, thông tin bảo hành.
### 2. 🛡️ Dành Cho Quản Trị Viên (Admin Dashboard)
* **Quản lý sản phẩm:** Thêm/sửa/xóa sản phẩm với thông số kỹ thuật chi tiết.
* **Dashboard:** Biểu đồ thống kê doanh thu, lợi nhuận, số lượng đơn hàng.
* **Duyệt đơn hàng:** Xử lý đơn hàng online và đơn hàng trả góp.
* **Quản lý Banner:** Cấu hình các chương trình khuyến mãi hiển thị trên App.
### 3. 📦 Dành Cho Thủ Kho (Warehouse)
* **Nhập/Xuất kho:** Tạo phiếu nhập hàng, xuất hàng chuyển đi.
* **Kiểm soát tồn kho:** Theo dõi số lượng thực tế trong kho theo thời gian thực.
---
⚙️ Hướng Dẫn Cài Đặt (Local Development)
#### Bước 1: Chuẩn bị Database
Cài đặt MySQL.
Tạo database mới tên là dbbanlaptop.
Import file API_JWT_DiDong/dbbanlaptop.sql vào database vừa tạo.
#### Bước 2: Chạy Backend (Server)
Mở terminal tại thư mục API_JWT_DiDong:
cd API_JWT_DiDong
###### Cài đặt thư viện
npm install
###### Tạo file .env và cấu hình DB (DB_HOST, DB_USER, DB_PASS...)
###### Chạy server
npm start
Server sẽ chạy tại: http://localhost:3000
#### Bước 3: Chạy Mobile App
Mở terminal tại thư mục laptop_flutter:
cd laptop_flutter
###### Tải các gói phụ thuộc
flutter pub get
###### Chạy ứng dụng (Chọn máy ảo hoặc thiết bị thật)
flutter run
## 📸 Screenshots (Giao diện ứng dụng)

### 1. App Khách Hàng
| Trang Chủ | Chi Tiết Sản Phẩm | Giỏ Hàng |Thanh Toán|
| :---: | :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/a39f3fa5-0a44-4d86-b5a7-1e6a62303587" width="200"> | <img src="https://github.com/user-attachments/assets/3f3e9886-17fb-4ed7-b073-e302c16fcf8a" width="200"> | <img src="https://github.com/user-attachments/assets/33f58d21-6e7f-4c6f-8abd-3ea36bbad9c0" width="200"> | <img src="https://github.com/user-attachments/assets/b5eb4b60-2956-4980-a440-dbad5d7d0746" width="200"> |

### 2. Hệ Thống Quản Trị
| Quản Lý Sản Phẩm | Quản Lý Tài Khoản |
| :---: | :---: |
| <img src="https://github.com/user-attachments/assets/8b57aa02-5317-4b60-9bc6-21b353e064bb" width="200"> | <img src="https://github.com/user-attachments/assets/d2053c4e-bee8-4f2e-a035-a02fa3c9317e" width="200"> |

---


## 👤 Author
*Nguyễn Thị Tử Vi*

**Role**: FullStack Developer

#### Contact:

**Email**: tuvi0304.gl@gmail.com

**LinkedIn**: linkedin.com/in/nguyễn-thị-tử-vi-8b4895399
