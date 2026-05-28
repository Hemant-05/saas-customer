import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerMenuProvider extends ChangeNotifier {
  RestaurantInfo? restaurantInfo;
  TableInfo? tableInfo;
  Map<String, List<MenuItemModel>> menuByCategory = {};
  List<String> categories = [];
  bool isLoading = false;
  String? errorMessage;
  List<dynamic>? availableTables;

  Future<void> fetchMenu(String restaurantId, String tableId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await CustomerApiService.get(
        CustomerApiConfig.publicMenu(restaurantId, tableId),
      );
      final data = response['data'];
      restaurantInfo = RestaurantInfo.fromJson(data['restaurantInfo']);
      tableInfo = TableInfo.fromJson(data['tableInfo']);

      menuByCategory = {};
      final menuData = data['menu'] as Map<String, dynamic>? ?? {};
      menuData.forEach((cat, items) {
        menuByCategory[cat] = (items as List)
            .map((i) => MenuItemModel.fromJson(i))
            .toList();
      });
      // Derive categories from the map keys (preserving order from API)
      categories = menuByCategory.keys.toList();
    } on CustomerApiException catch (e) {
      errorMessage = e.message;
      if (e.data != null && e.data['availableTables'] != null) {
        availableTables = e.data['availableTables'];
      }
    } catch (e) {
      errorMessage = 'Failed to load menu: ${e.toString()}';
    }
    isLoading = false;
    notifyListeners();
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);
  double get taxAmount => double.parse((subtotal * 0.05).toStringAsFixed(2));
  double get totalAmount => double.parse((subtotal + taxAmount).toStringAsFixed(2));

  bool hasItem(String itemId) => _items.any((i) => i.item.id == itemId);
  int quantityOf(String itemId) {
    final match = _items.where((i) => i.item.id == itemId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  void addItem(MenuItemModel item, {String customization = ''}) {
    final idx = _items.indexWhere((i) => i.item.id == item.id);
    if (idx != -1) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(item: item, customization: customization));
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((i) => i.item.id == itemId);
    notifyListeners();
  }

  void increaseQuantity(String itemId) {
    final idx = _items.indexWhere((i) => i.item.id == itemId);
    if (idx != -1) {
      _items[idx].quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(String itemId) {
    final idx = _items.indexWhere((i) => i.item.id == itemId);
    if (idx != -1) {
      if (_items[idx].quantity <= 1) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity--;
      }
      notifyListeners();
    }
  }

  void updateCustomization(String itemId, String customization) {
    final idx = _items.indexWhere((i) => i.item.id == itemId);
    if (idx != -1) {
      _items[idx].customization = customization;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class CustomerOrderProvider extends ChangeNotifier {
  String? placedOrderId;
  String? razorpayOrderId;
  String? razorpayKey;
  OrderBill? currentBill;
  bool isLoading = false;
  String? errorMessage;

  CustomerOrderProvider() {
    _loadPersistedOrder();
  }

  Future<void> _loadPersistedOrder() async {
    final prefs = await SharedPreferences.getInstance();
    placedOrderId = prefs.getString('activeOrderId');
    if (placedOrderId != null) {
      notifyListeners();
      // Optionally verify if it's still active
      pollBill(placedOrderId!);
    }
  }

  Future<void> clearActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeOrderId');
    placedOrderId = null;
    currentBill = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> placeOrder({
    required String restaurantId,
    required String tableId,
    required int tableNumber,
    required String tableName,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await CustomerApiService.post(
        CustomerApiConfig.placeOrder,
        {
          'restaurantId': restaurantId,
          'tableId': tableId,
          'tableNumber': tableNumber,
          'tableName': tableName,
          'items': items,
          'paymentMethod': paymentMethod,
        },
      );
      final data = response['data'];
      placedOrderId = data['order']['_id'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activeOrderId', placedOrderId!);
      // Non-blocking: register FCM token linked to this order
      CustomerNotificationService()
          .registerTokenForOrder(placedOrderId!)
          .catchError((_) {});
      isLoading = false;
      notifyListeners();
      return data;
    } on CustomerApiException catch (e) {
      errorMessage = e.message;
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<OrderBill?> createRazorpayOrder(String orderId, double amount) async {
    try {
      final response = await CustomerApiService.post(
        CustomerApiConfig.createRazorpayOrder,
        {
          'orderId': orderId,
          'amount': amount,
        },
      );
      final data = response['data'];
      razorpayOrderId = data['razorpayOrderId'];
      razorpayKey = data['key'];
      return null;
    } on CustomerApiException catch (e) {
      errorMessage = e.message;
      return null;
    }
  }

  Future<bool> verifyRazorpay({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    try {
      await CustomerApiService.post(CustomerApiConfig.verifyRazorpay, {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'orderId': orderId,
      });
      return true;
    } on CustomerApiException catch (e) {
      errorMessage = e.message;
      return false;
    }
  }

  Future<OrderBill?> pollBill(String orderId) async {
    try {
      final response = await CustomerApiService.get(CustomerApiConfig.bill(orderId));
      final data = response['data'];
      currentBill = OrderBill.fromJson(data['bill'], data['orderStatus']);
      notifyListeners();
      return currentBill;
    } catch (_) {
      return currentBill;
    }
  }
}
