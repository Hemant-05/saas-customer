class RestaurantInfo {
  final String restaurantId;
  final String name;
  final String? logoUrl;

  const RestaurantInfo({
    required this.restaurantId,
    required this.name,
    this.logoUrl,
  });

  factory RestaurantInfo.fromJson(Map<String, dynamic> json) {
    return RestaurantInfo(
      restaurantId: json['restaurantId'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'restaurantId': restaurantId,
        'name': name,
        'logoUrl': logoUrl,
      };
}

class TableInfo {
  final String tableId;
  final int tableNumber;
  final String tableName;

  const TableInfo({
    required this.tableId,
    required this.tableNumber,
    required this.tableName,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      tableId: json['tableId'] ?? '',
      tableNumber: (json['tableNumber'] as num?)?.toInt() ?? 0,
      tableName: json['tableName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'tableNumber': tableNumber,
        'tableName': tableName,
      };
}

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVeg;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.isVeg,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      isVeg: json['isVeg'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
        'isVeg': isVeg,
      };
}

class CartItem {
  final MenuItemModel item;
  int quantity;
  String customization;

  CartItem({
    required this.item,
    this.quantity = 1,
    this.customization = '',
  });

  double get subtotal => item.price * quantity;

  Map<String, dynamic> toOrderItem() => {
        'menuItemId': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': quantity,
        'customization': customization,
      };
}

class BillItem {
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String customization;

  const BillItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.customization,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      customization: json['customization'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
        'customization': customization,
      };
}

class OrderBill {
  final String id;
  final String orderId;
  final String restaurantName;
  final String? restaurantLogoUrl;
  final String? restaurantPhone;
  final String? restaurantGstNumber;
  final int tableNumber;
  final String tableName;
  final String orderNumber;
  final List<BillItem> items;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? orderStatus;
  final String? businessType;
  final int? orderPickupNumber;

  const OrderBill({
    required this.id,
    required this.orderId,
    required this.restaurantName,
    this.restaurantLogoUrl,
    this.restaurantPhone,
    this.restaurantGstNumber,
    required this.tableNumber,
    required this.tableName,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.orderStatus,
    this.businessType,
    this.orderPickupNumber,
  });

  factory OrderBill.fromJson(
      Map<String, dynamic> billJson, String? orderStatus) {
    return OrderBill(
      id: billJson['_id'] ?? '',
      orderId: billJson['orderId'] ?? '',
      restaurantName: billJson['restaurantName'] ?? '',
      restaurantLogoUrl: billJson['restaurantLogoUrl'],
      restaurantPhone: billJson['restaurantPhone'],
      restaurantGstNumber: billJson['restaurantGstNumber'],
      tableNumber: (billJson['tableNumber'] as num?)?.toInt() ?? 0,
      tableName: billJson['tableName'] ?? '',
      orderNumber: billJson['orderNumber'] ?? '',
      items: (billJson['items'] as List<dynamic>?)
              ?.map((i) => BillItem.fromJson(i))
              .toList() ??
          [],
      subtotal: (billJson['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (billJson['taxPercent'] as num?)?.toDouble() ?? 5.0,
      taxAmount: (billJson['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (billJson['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: billJson['paymentMethod'] ?? 'cash',
      paymentStatus: billJson['paymentStatus'] ?? 'pending',
      orderStatus: orderStatus,
      businessType: billJson['businessType'],
      orderPickupNumber: (billJson['orderPickupNumber'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'orderId': orderId,
        'restaurantName': restaurantName,
        'restaurantLogoUrl': restaurantLogoUrl,
        'tableNumber': tableNumber,
        'tableName': tableName,
        'orderNumber': orderNumber,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxPercent': taxPercent,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
      };
}
