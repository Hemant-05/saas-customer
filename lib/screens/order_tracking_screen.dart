import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _pollingTimer;
  OrderBill? _bill;
  late Razorpay _razorpay;

  final _statusSteps = ['placed', 'preparing', 'ready', 'delivered'];
  final _statusLabels = ['Order Placed', 'Preparing', 'Ready', 'Delivered'];
  final _statusIcons = [
    Icons.receipt_long_rounded,
    Icons.local_fire_department_rounded,
    Icons.check_circle_rounded,
    Icons.delivery_dining_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _fetchBill();
    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchBill());
  }

  @override
  void dispose() {
    _razorpay.clear();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final res = await CustomerApiService.post(CustomerApiConfig.verifyRazorpay, {
        'razorpayOrderId': response.orderId,
        'razorpayPaymentId': response.paymentId,
        'razorpaySignature': response.signature,
        'orderId': widget.orderId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful!'), backgroundColor: Color(0xFF06D6A0)),
        );
        _fetchBill();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Verification Failed: $e'), backgroundColor: const Color(0xFFFF4757)),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: const Color(0xFFFF4757)),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> _startRazorpayPayment() async {
    if (_bill == null) return;
    try {
      // 1. Create Razorpay order on backend
      final orderRes = await CustomerApiService.post(CustomerApiConfig.createRazorpayOrder, {
        'amount': _bill!.totalAmount,
        'orderId': widget.orderId,
      });
      
      final data = orderRes['data'];
      final options = {
        'key': data['key'],
        'amount': data['amount'],
        'name': _bill!.restaurantName,
        'order_id': data['razorpayOrderId'],
        'description': 'Order #${_bill!.orderNumber}',
        'timeout': 120, // in seconds
        'prefill': {
          'contact': '',
          'email': ''
        }
      };

      // 2. Open Razorpay Checkout
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate payment: $e'), backgroundColor: const Color(0xFFFF4757)),
        );
      }
    }
  }

  Future<void> _fetchBill() async {
    final provider = context.read<CustomerOrderProvider>();
    final bill = await provider.pollBill(widget.orderId);
    if (mounted && bill != null) {
      setState(() => _bill = bill);
      
      if (bill.orderStatus == 'delivered' && bill.paymentStatus == 'paid') {
        provider.clearActiveOrder();
      }
    }
  }

  int _currentStep() {
    final status = _bill?.orderStatus ?? 'placed';
    final idx = _statusSteps.indexOf(status);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStep();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Order Tracking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done', style: TextStyle(color: Color(0xFFFF6B35))),
          ),
        ],
      ),
      body: _bill == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  SizedBox(height: 16),
                  Text('Loading order...',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchBill,
              color: const Color(0xFFFF6B35),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Order number and table
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF12121F)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFF6B35).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.restaurant_rounded,
                              color: Color(0xFFFF6B35), size: 32),
                          const SizedBox(height: 8),
                          Text(
                            _bill!.orderNumber,
                            style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Table ${_bill!.tableNumber} — ${_bill!.tableName}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Step progress indicator
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...List.generate(_statusSteps.length, (idx) {
                            final isDone = idx <= currentStep;
                            final isActive = idx == currentStep;
                            final isLast = idx == _statusSteps.length - 1;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFF06D6A0)
                                            : Colors.white.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF06D6A0)
                                                      .withOpacity(0.4),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        _statusIcons[idx],
                                        color: isDone
                                            ? Colors.white
                                            : Colors.white24,
                                        size: 20,
                                      ),
                                    ),
                                    if (!isLast)
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 400),
                                        width: 2,
                                        height: 32,
                                        color: idx < currentStep
                                            ? const Color(0xFF06D6A0)
                                            : Colors.white12,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    _statusLabels[idx],
                                    style: TextStyle(
                                      color: isDone
                                          ? Colors.white
                                          : Colors.white38,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (!isLast) const SizedBox(height: 32),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Payment status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_bill!.paymentStatus == 'paid'
                                ? const Color(0xFF06D6A0)
                                : const Color(0xFFFFBE0B))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _bill!.paymentStatus == 'paid'
                              ? const Color(0xFF06D6A0).withOpacity(0.4)
                              : const Color(0xFFFFBE0B).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _bill!.paymentStatus == 'paid'
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            color: _bill!.paymentStatus == 'paid'
                                ? const Color(0xFF06D6A0)
                                : const Color(0xFFFFBE0B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _bill!.paymentStatus == 'paid'
                                      ? '✅ Payment Received'
                                      : 'Payment Pending',
                                  style: TextStyle(
                                    color: _bill!.paymentStatus == 'paid'
                                        ? const Color(0xFF06D6A0)
                                        : const Color(0xFFFFBE0B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_bill!.paymentStatus == 'pending')
                                  Text(
                                    'Please pay at the counter when your meal is complete.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_bill!.paymentStatus == 'pending') ...[
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _startRazorpayPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFBE0B),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Pay Online', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Bill
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bill!.restaurantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),
                          ..._bill!.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Text('${item.quantity}×',
                                        style: const TextStyle(
                                            color: Colors.white54, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(item.name,
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 13)),
                                    ),
                                    Text(
                                      '₹${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(color: Colors.white10, height: 20),
                          _billRow('Subtotal',
                              '₹${_bill!.subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 6),
                          _billRow('Tax (${_bill!.taxPercent.toInt()}%)',
                              '₹${_bill!.taxAmount.toStringAsFixed(2)}'),
                          const Divider(color: Colors.white10, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                              Text(
                                '₹${_bill!.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Auto-refreshes every 3 seconds • Pull to refresh',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _billRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      );
}
