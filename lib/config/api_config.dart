/// Customer app API config — must match backend URL
class CustomerApiConfig {
  // Change this to your backend URL
  // Android emulator: http://10.0.2.2:5000
  // Chrome (Web): http://localhost:5000
  // Physical device on network: http://192.168.29.174:5000
  // static const String localBaseUrl = 'http://192.168.29.174:5000/api';
  static const String baseUrl = 'https://saas-backend-oroj.onrender.com/api';
  static const String socketUrl = 'https://saas-backend-oroj.onrender.com';

  // Public menu
  static String publicMenu(String restaurantId, String tableId) =>
      '$baseUrl/public/menu/$restaurantId/$tableId';
  static String publicTruckMenu(String restaurantId) =>
      '$baseUrl/public/truck/$restaurantId';

  // Order endpoints (public)
  static const String placeOrder = '$baseUrl/orders/place';
  static String bill(String orderId) => '$baseUrl/orders/bill/$orderId';
  static String orderHistory(String sessionId) =>
      '$baseUrl/public/orders/history/$sessionId';
  static String orderReceipt(String orderId) =>
      '$baseUrl/public/orders/receipt/$orderId';

  // Payment
  static const String createRazorpayOrder =
      '$baseUrl/payment/create-razorpay-order';
  static const String verifyRazorpay = '$baseUrl/payment/verify-razorpay';

  // Notifications
  static const String registerCustomerToken =
      '$baseUrl/notifications/register-customer-token';
}
