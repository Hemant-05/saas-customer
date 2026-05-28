import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final String restaurantId;
  final String tableId;
  final RestaurantInfo restaurantInfo;
  final TableInfo tableInfo;

  const CartScreen({
    super.key,
    required this.restaurantId,
    required this.tableId,
    required this.restaurantInfo,
    required this.tableInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Clear Cart',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          content: const Text('Remove all items from cart?',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.white54)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                cart.clearCart();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4757)),
                              child: const Text('Clear',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Clear',
                        style: TextStyle(color: Color(0xFFFF4757))),
                  ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (_, cart, __) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Browse Menu',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (_, idx) {
                    final cartItem = cart.items[idx];
                    return _CartItemRow(cartItem: cartItem, cart: cart);
                  },
                ),
              ),
              // Order summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF12121F),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _summaryRow('Tax (5%)', '₹${cart.taxAmount.toStringAsFixed(2)}'),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '₹${cart.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                restaurantId: restaurantId,
                                tableId: tableId,
                                restaurantInfo: restaurantInfo,
                                tableInfo: tableInfo,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Place Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      );
}

class _CartItemRow extends StatelessWidget {
  final CartItem cartItem;
  final CartProvider cart;

  const _CartItemRow({required this.cartItem, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cartItem.item.isVeg
                      ? const Color(0xFF06D6A0)
                      : const Color(0xFFFF4757),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cartItem.item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => cart.removeItem(cartItem.item.id),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFFF4757), size: 20),
              ),
            ],
          ),
          if (cartItem.customization.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '📝 ${cartItem.customization}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '₹${cartItem.item.price.toStringAsFixed(2)} each',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const Spacer(),
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => cart.decreaseQuantity(cartItem.item.id),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Icon(Icons.remove_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => cart.addItem(cartItem.item),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child:
                            Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${cartItem.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
