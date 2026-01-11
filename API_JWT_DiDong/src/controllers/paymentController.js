const crypto = require('crypto');
const qs = require('qs');
const moment = require('moment'); 
const { Order } = require('../models'); // Giả sử bạn có model Order
const sequelize = require('../config/db'); // Để dùng transaction nếu cần

// @desc    Create VNPAY Payment URL
// @route   POST /api/payment/vnpay/create_url
// @access  Private
const createVnpayPaymentUrl = async (req, res) => {
  try {
    const { orderId, amount, orderDescription, bankCode, locale } = req.body;
    const userId = req.user.id; // Lấy từ middleware protect

    // Kiểm tra xem đơn hàng có tồn tại và thuộc về user không
    const order = await Order.findOne({ where: { id: orderId, user_id: userId } });
    if (!order) {
      return res.status(404).json({ message: 'Đơn hàng không tồn tại hoặc không thuộc về bạn.' });
    }

    // Kiểm tra trạng thái đơn hàng, chỉ cho phép tạo URL thanh toán cho đơn hàng mới hoặc chờ thanh toán
    if (order.status !== 0 ) { // Giả sử 0 là "chờ thanh toán"
        // hoặc các trạng thái khác cho phép thanh toán lại
      return res.status(400).json({ message: 'Đơn hàng không hợp lệ để thanh toán.' });
    }
    if (order.paymentMethod !== 1) { // Giả sử 1 là VNPAY
        return res.status(400).json({ message: 'Phương thức thanh toán của đơn hàng không phải VNPAY.' });
    }


    const date = new Date();
    const createDate = moment(date).format('YYYYMMDDHHmmss');
    const ipAddr = req.headers['x-forwarded-for'] ||
      req.connection.remoteAddress ||
      req.socket.remoteAddress ||
      (req.connection.socket ? req.connection.socket.remoteAddress : null);

    const tmnCode = process.env.VNP_TMNCODE;
    const secretKey = process.env.VNP_HASHSECRET;
    let vnpUrl = process.env.VNP_URL;
    const returnUrl = process.env.VNP_RETURN_URL; // URL client của bạn để redirect sau thanh toán

    // Thông tin đơn hàng từ DB, đảm bảo amount là chính xác
    const vnpAmount = order.total * 100; // VNPay yêu cầu amount * 100

    let vnp_Params = {};
    vnp_Params['vnp_Version'] = '2.1.0';
    vnp_Params['vnp_Command'] = 'pay';
    vnp_Params['vnp_TmnCode'] = tmnCode;
    vnp_Params['vnp_Locale'] = locale || 'vn';
    vnp_Params['vnp_CurrCode'] = 'VND';
    vnp_Params['vnp_TxnRef'] = `${orderId}_${moment(date).format('HHmmss')}`; // Mã tham chiếu giao dịch, nên duy nhất
    vnp_Params['vnp_OrderInfo'] = orderDescription || `Thanh toan cho don hang ${orderId}`;
    vnp_Params['vnp_OrderType'] = 'other'; // Hoặc 'billpayment', 'fashion'
    vnp_Params['vnp_Amount'] = vnpAmount;
    vnp_Params['vnp_ReturnUrl'] = returnUrl;
    vnp_Params['vnp_IpAddr'] = ipAddr;
    vnp_Params['vnp_CreateDate'] = createDate;

    if (bankCode && bankCode !== '') {
      vnp_Params['vnp_BankCode'] = bankCode;
    }

    vnp_Params = sortObject(vnp_Params);

    const signData = qs.stringify(vnp_Params, { encode: false });
    const hmac = crypto.createHmac("sha512", secretKey);
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");
    vnp_Params['vnp_SecureHash'] = signed;

    vnpUrl += '?' + qs.stringify(vnp_Params, { encode: false });

    console.log('Generated VNPAY URL:', vnpUrl);
    res.status(200).json({ paymentUrl: vnpUrl });

  } catch (error) {
    console.error('Error creating VNPAY payment URL:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi tạo URL thanh toán.' });
  }
};

// @desc    VNPay IPN (Instant Payment Notification)
// @route   GET /api/payment/vnpay_ipn
// @access  Public (VNPay server calls this)
const vnpayIpn = async (req, res) => {
  let vnp_Params = req.query;
  const secureHash = vnp_Params['vnp_SecureHash'];

  const orderIdParts = vnp_Params['vnp_TxnRef'].split('_');
  const orderId = parseInt(orderIdParts[0], 10);


  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];

  vnp_Params = sortObject(vnp_Params);
  const secretKey = process.env.VNP_HASHSECRET;
  const signData = qs.stringify(vnp_Params, { encode: false });
  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");

  const vnp_ResponseCode = vnp_Params['vnp_ResponseCode'];
  const vnp_TransactionStatus = vnp_Params['vnp_TransactionStatus']; // Thêm tham số này

  if (secureHash === signed) {
    try {
        const order = await Order.findByPk(orderId);
        if (!order) {
            console.log(`[VNPAY_IPN] Order not found: ${orderId}`);
            return res.status(200).json({ RspCode: '01', Message: 'Order not found' });
        }

        // Chỉ xử lý nếu đơn hàng đang chờ thanh toán (status: 0)
        if (order.status === 0) {
            if (vnp_ResponseCode === '00' && vnp_TransactionStatus === '00') {
                // Giao dịch thành công
                order.status = 1; // Trạng thái "đã xác nhận" hoặc "đã thanh toán"
                // Lưu ý: Không giảm số lượng sản phẩm ở đây nữa vì đã giảm khi tạo đơn hàng.
                // Nếu logic của bạn khác, hãy điều chỉnh.
                await order.save();
                console.log(`[VNPAY_IPN] Order ${orderId} payment success.`);
                res.status(200).json({ RspCode: '00', Message: 'Confirm Success' });
            } else {
                // Giao dịch thất bại
                order.status = 4; // Trạng thái "đã hủy" hoặc "thanh toán thất bại"
                // CÂN NHẮC: Khôi phục số lượng sản phẩm nếu thanh toán thất bại
                // Đoạn này cần transaction để đảm bảo tính toàn vẹn
                const transaction = await sequelize.transaction();
                try {
                    await order.save({ transaction });
                    const orderDetails = await order.getOrder_details({ transaction }); // Giả sử có association tên là getOrder_details

                    for (const detail of orderDetails) {
                        const product = await detail.getProduct({ transaction }); // Giả sử có association tên là getProduct
                        if (product) {
                            product.quantity += detail.quantity;
                            product.buyturn -= detail.quantity; // Giảm lượt mua nếu đã cộng trước đó
                            await product.save({ transaction });
                        }
                    }
                    await transaction.commit();
                    console.log(`[VNPAY_IPN] Order ${orderId} payment failed. Products quantity restored.`);
                } catch (err) {
                    await transaction.rollback();
                    console.error(`[VNPAY_IPN] Error restoring product quantity for order ${orderId}:`, err);
                    // Dù có lỗi khôi phục sản phẩm, vẫn báo cho VNPAY là đã xử lý (tránh VNPAY gửi IPN lại)
                }
                res.status(200).json({ RspCode: '00', Message: 'Confirm Success' }); // Vẫn trả về 00 cho VNPAY
            }
        } else {
            // Đơn hàng đã được xử lý trước đó (ví dụ: đã thành công hoặc đã hủy)
            console.log(`[VNPAY_IPN] Order ${orderId} already processed. Status: ${order.status}`);
            res.status(200).json({ RspCode: '02', Message: 'Order already confirmed' });
        }
    } catch (dbError) {
        console.error('[VNPAY_IPN] Database error:', dbError);
        res.status(200).json({ RspCode: '97', Message: 'Internal Server Error on our side' }); // Lỗi từ phía server của bạn
    }
  } else {
    console.log('[VNPAY_IPN] Invalid signature.');
    res.status(200).json({ RspCode: '97', Message: 'Invalid Signature' });
  }
};

// @desc    VNPay Return URL Handler (sau khi khách hàng thanh toán xong)
// @route   GET /api/payment/vnpay_return
// @access  Public
const vnpayReturn = async (req, res) => {
  let vnp_Params = req.query;
  const secureHash = vnp_Params['vnp_SecureHash'];

  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];

  vnp_Params = sortObject(vnp_Params);
  const secretKey = process.env.VNP_HASHSECRET;
  const signData = qs.stringify(vnp_Params, { encode: false });
  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");

  const orderIdParts = vnp_Params['vnp_TxnRef'].split('_');
  const orderId = orderIdParts[0];
  const responseCode = vnp_Params['vnp_ResponseCode'];

  if (secureHash === signed) {
    // Tại đây, bạn KHÔNG nên cập nhật trạng thái đơn hàng dựa vào returnUrl.
    // Việc cập nhật trạng thái chính thức nên dựa vào IPN.
    // Return URL chủ yếu để redirect người dùng và hiển thị thông báo.

    // Bạn có thể redirect về một trang cụ thể trên frontend kèm theo các tham số
    // Ví dụ: http://your-flutter-app.com/payment-result?orderId=...&status=...
    // Frontend sẽ dựa vào các tham số này để hiển thị thông báo phù hợp.
    if (responseCode === '00') {
        // Thanh toán thành công
        console.log(`[VNPAY_RETURN] Order ${orderId} paid successfully (pending IPN confirmation).`);
        // Redirect người dùng về trang thành công trên frontend
        // res.redirect(`http://your-frontend-url/order-success?orderId=${orderId}&status=success&message=Giao dịch thành công`);
         res.send(`
            <html>
            <head><title>Kết quả thanh toán</title></head>
            <body>
                <h1>Giao dịch thành công cho đơn hàng ${orderId}!</h1>
                <p>Cảm ơn bạn đã mua hàng. Chúng tôi sẽ xử lý đơn hàng của bạn sớm nhất.</p>
                <p><a href="your_app_schema://payment_success?orderId=${orderId}&status=00">Quay lại ứng dụng</a></p>
            </body>
            </html>
        `);
    } else {
        // Thanh toán thất bại hoặc bị hủy
        console.log(`[VNPAY_RETURN] Order ${orderId} payment failed or cancelled. Code: ${responseCode}`);
        // Redirect người dùng về trang thất bại trên frontend
        // res.redirect(`http://your-frontend-url/order-failed?orderId=${orderId}&status=failed&message=Giao dịch không thành công. Mã lỗi: ${responseCode}`);
         res.send(`
            <html>
            <head><title>Kết quả thanh toán</title></head>
            <body>
                <h1>Giao dịch không thành công cho đơn hàng ${orderId}.</h1>
                <p>Lý do: ${mapVnpayResponseCodeToMessage(responseCode)} (Mã: ${responseCode})</p>
                <p>Vui lòng thử lại hoặc chọn phương thức thanh toán khác.</p>
                 <p><a href="your_app_schema://payment_failed?orderId=${orderId}&status=${responseCode}">Quay lại ứng dụng</a></p>
            </body>
            </html>
        `);
    }
  } else {
    console.log('[VNPAY_RETURN] Invalid signature.');
    // res.redirect(`http://your-frontend-url/order-failed?message=Chữ ký không hợp lệ`);
     res.send(`
        <html>
        <head><title>Lỗi thanh toán</title></head>
        <body>
            <h1>Giao dịch không hợp lệ.</h1>
            <p>Chữ ký không hợp lệ. Vui lòng liên hệ hỗ trợ.</p>
            <p><a href="your_app_schema://payment_error?message=invalid_signature">Quay lại ứng dụng</a></p>
        </body>
        </html>
    `);
  }
};


// Helper function to sort object properties for VNPAY hashing
function sortObject(obj) {
  let sorted = {};
  let str = [];
  let key;
  for (key in obj) {
    if (obj.hasOwnProperty(key)) {
      str.push(encodeURIComponent(key));
    }
  }
  str.sort();
  for (key = 0; key < str.length; key++) {
    sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, "+");
  }
  return sorted;
}

// Helper function to map VNPAY response codes to messages (optional)
function mapVnpayResponseCodeToMessage(code) {
    const messages = {
        '00': 'Giao dịch thành công',
        '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ (có dấu hiệu gian lận).',
        '09': 'Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking tại ngân hàng.',
        '10': 'Thẻ/Tài khoản xác thực không đúng quá 3 lần.',
        '11': 'Đã hết hạn chờ thanh toán. Xin vui lòng thực hiện lại giao dịch.',
        '12': 'Thẻ/Tài khoản bị khoá.',
        '13': 'Quý khách nhập sai mật khẩu xác thực giao dịch (OTP). Xin vui lòng thực hiện lại giao dịch.',
        '24': 'Giao dịch không thành công do: Khách hàng hủy giao dịch.',
        '51': 'Tài khoản không đủ số dư để thực hiện giao dịch.',
        '65': 'Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày.',
        '75': 'Ngân hàng thanh toán đang bảo trì.',
        '79': 'KH nhập sai mật khẩu thanh toán quá số lần quy định. Xin vui lòng thực hiện lại giao dịch',
        '99': 'Các lỗi khác (lỗi còn lại, không có trong danh sách mã lỗi đã liệt kê)',
    };
    return messages[code] || 'Giao dịch không thành công.';
}


module.exports = {
  createVnpayPaymentUrl,
  vnpayIpn,
  vnpayReturn
};