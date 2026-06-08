import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String restaurantId;
  final String? tableId;
  final RestaurantInfo restaurantInfo;
  final TableInfo? tableInfo;

  const CheckoutScreen({
    super.key,
    required this.restaurantId,
    this.tableId,
    required this.restaurantInfo,
    this.tableInfo,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'pay_later';
  bool _isLoading = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderProv = context.read<CustomerOrderProvider>();
    final success = await orderProv.verifyRazorpay(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
      orderId: orderProv.placedOrderId ?? '',
    );
    if (!mounted) return;
    if (success) {
      _navigateToTracking();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed'),
          backgroundColor: Color(0xFFFF4757),
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: const Color(0xFFFF4757),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  Future<void> _confirmOrder() async {
    final cart = context.read<CartProvider>();
    final orderProv = context.read<CustomerOrderProvider>();

    setState(() => _isLoading = true);

    final orderData = await orderProv.placeOrder(
      restaurantId: widget.restaurantId,
      tableId: widget.tableId,
      tableNumber: widget.tableInfo?.tableNumber,
      tableName: widget.tableInfo?.tableName,
      items: cart.items.map((ci) => ci.toOrderItem()).toList(),
      paymentMethod: _selectedPaymentMethod,
    );

    if (!mounted) return;

    if (orderData == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProv.errorMessage ?? 'Failed to place order'),
          backgroundColor: const Color(0xFFFF4757),
        ),
      );
      return;
    }

    // Handle Razorpay online payment
    if (_selectedPaymentMethod == 'online') {
      final orderId = orderData['order']['_id'];
      final totalAmount = (orderData['order']['totalAmount'] as num).toDouble();

      await orderProv.createRazorpayOrder(orderId, totalAmount);
      if (orderProv.razorpayOrderId != null) {
        setState(() => _isLoading = false);
        final options = {
          'key': orderProv.razorpayKey ?? 'rzp_test_your_key_here',
          'amount': (totalAmount * 100).toInt(),
          'name': widget.restaurantInfo.name,
          'description': 'Order ${orderData['order']['orderNumber']}',
          'order_id': orderProv.razorpayOrderId,
          'prefill': {'contact': '', 'email': ''},
          'theme': {'color': '#FF6B35'},
        };
        _razorpay.open(options);
        return;
      }
    }

    // Non-Razorpay payment — navigate to tracking
    cart.clearCart();
    setState(() => _isLoading = false);
    _navigateToTracking();
  }

  void _navigateToTracking() {
    final orderProv = context.read<CustomerOrderProvider>();
    context.read<CartProvider>().clearCart();
    if (orderProv.placedOrderId != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderProv.placedOrderId!),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

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
          'Checkout',
          style: TextStyle(
              color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...cart.items.map((ci) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text('${ci.quantity}×',
                                style: const TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(ci.item.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimaryLight,
                                      fontSize: 13)),
                            ),
                            Text(
                              '₹${ci.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                  const Divider(color: AppColors.borderLight, height: 20),
                  _row('Subtotal', '₹${cart.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _row('Tax (5%)', '₹${cart.taxAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _row('Total', '₹${cart.totalAmount.toStringAsFixed(2)}',
                      highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Payment Method',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            // Payment options
            ..._buildPaymentOptions(),
            const SizedBox(height: 32),
            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text(
                        'Confirm Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPaymentOptions() {
    final options = [
      (
        'online',
        'Pay Now — Online',
        'UPI / Cards / Wallets',
        Icons.phone_android_rounded,
        const Color(0xFF6C63FF),
      ),
      (
        'cash',
        'Pay Now — Cash',
        'Pay cash to the waiter',
        Icons.money_rounded,
        const Color(0xFF06D6A0),
      ),
      (
        'card',
        'Pay Now — Card',
        'Swipe card at the counter',
        Icons.credit_card_rounded,
        const Color(0xFF3A86FF),
      ),
      (
        'pay_later',
        'Pay After Eating',
        'Pay when you\'re done with your meal',
        Icons.schedule_rounded,
        const Color(0xFFFFBE0B),
      ),
    ];

    return options
        .map(
          (opt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedPaymentMethod == opt.$1
                      ? opt.$5.withOpacity(0.12)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedPaymentMethod == opt.$1
                        ? opt.$5
                        : AppColors.borderLight,
                    width: _selectedPaymentMethod == opt.$1 ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: opt.$5.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(opt.$4, color: opt.$5, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.$2,
                            style: const TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            opt.$3,
                            style: const TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: opt.$1,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (v) =>
                          setState(() => _selectedPaymentMethod = v!),
                      activeColor: opt.$5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _row(String label, String value, {bool highlight = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: highlight
                    ? AppColors.textPrimaryLight
                    : AppColors.textSecondaryLight,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                fontSize: highlight ? 16 : 14,
              )),
          Text(value,
              style: TextStyle(
                color: highlight
                    ? const Color(0xFFFF6B35)
                    : AppColors.textPrimaryLight,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                fontSize: highlight ? 18 : 14,
              )),
        ],
      );
}
