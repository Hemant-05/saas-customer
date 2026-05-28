/// Customer app API config — must match backend URL
class CustomerApiConfig {
  // Change this to your backend URL
  // Android emulator: http://10.0.2.2:5000
  // Chrome (Web): http://localhost:5000
  // Physical device on network: http://192.168.29.174:5000
  static const String baseUrl = 'http://10.11.53.2:5000/api';

  // Public menu
  static String publicMenu(String restaurantId, String tableId) =>
      '$baseUrl/public/menu/$restaurantId/$tableId';

  // Order endpoints (public)
  static const String placeOrder = '$baseUrl/orders/place';
  static String bill(String orderId) => '$baseUrl/orders/bill/$orderId';

  // Payment
  static const String createRazorpayOrder = '$baseUrl/payment/create-razorpay-order';
  static const String verifyRazorpay = '$baseUrl/payment/verify-razorpay';

  // Notifications
  static const String registerCustomerToken = '$baseUrl/notifications/register-customer-token';
}
