import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final String restaurantId;
  final String? tableId;
  final RestaurantInfo restaurantInfo;
  final TableInfo? tableInfo;

  const CartScreen({
    super.key,
    required this.restaurantId,
    this.tableId,
    required this.restaurantInfo,
    this.tableInfo,
  });

  @override
  Widget build(BuildContext context) {
    final latestRestaurantInfo =
        context.watch<CustomerMenuProvider>().restaurantInfo ?? restaurantInfo;
    final isAcceptingOrders = latestRestaurantInfo.isAcceptingOrders;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(
              color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700),
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
                          backgroundColor: AppColors.surfaceLight,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Clear Cart',
                              style: TextStyle(
                                  color: AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w700)),
                          content: const Text('Remove all items from cart?',
                              style: TextStyle(
                                  color: AppColors.textSecondaryLight)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      color: AppColors.textSecondaryLight)),
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
                  const Icon(Icons.shopping_cart_outlined,
                      size: 64, color: AppColors.textMutedLight),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(color: AppColors.textSecondaryLight),
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
                  color: AppColors.surfaceLight,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (!isAcceptingOrders) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFB020).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFFFFB020).withValues(alpha: 0.32),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.pause_circle_filled_rounded,
                                color: Color(0xFFFFB020), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ordering is paused right now.',
                                style: TextStyle(
                                  color: AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _summaryRow(
                        'Subtotal', '₹${cart.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _summaryRow(
                        'Tax (5%)', '₹${cart.taxAmount.toStringAsFixed(2)}'),
                    const Divider(color: AppColors.borderLight, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: AppColors.textPrimaryLight,
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
                          onPressed: isAcceptingOrders
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(
                                        restaurantId: restaurantId,
                                        tableId: tableId,
                                        restaurantInfo: latestRestaurantInfo,
                                        tableInfo: tableInfo,
                                      ),
                                    ),
                                  )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAcceptingOrders
                                ? const Color(0xFFFF6B35)
                                : const Color(0xFF94A3B8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isAcceptingOrders
                                ? 'Place Order'
                                : 'Ordering Paused',
                            style: const TextStyle(
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
          Text(label,
              style: const TextStyle(color: AppColors.textSecondaryLight)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600)),
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
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
                    color: AppColors.textPrimaryLight,
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
                  style: const TextStyle(
                    color: AppColors.textMutedLight,
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
                style: const TextStyle(
                    color: AppColors.textSecondaryLight, fontSize: 12),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Icon(Icons.add_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${cartItem.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
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
