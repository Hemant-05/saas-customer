import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class OrderReceiptScreen extends StatefulWidget {
  final String orderId;
  const OrderReceiptScreen({super.key, required this.orderId});

  @override
  State<OrderReceiptScreen> createState() => _OrderReceiptScreenState();
}

class _OrderReceiptScreenState extends State<OrderReceiptScreen> {
  bool _isLoading = true;
  OrderBill? _bill;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReceipt();
  }

  Future<void> _fetchReceipt() async {
    try {
      final response = await CustomerApiService.get(CustomerApiConfig.orderReceipt(widget.orderId));
      final data = response['data'];
      setState(() {
        _bill = OrderBill.fromJson(data['bill'], data['orderStatus']);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

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
          'Digital Receipt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white54)))
              : _bill == null
                  ? const Center(child: Text('Receipt not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                _bill!.restaurantName,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (_bill!.restaurantPhone != null) ...[
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  'Ph: ${_bill!.restaurantPhone}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              ),
                            ],
                            if (_bill!.restaurantGstNumber != null && _bill!.restaurantGstNumber!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Center(
                                child: Text(
                                  'GST: ${_bill!.restaurantGstNumber}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Order #${_bill!.orderNumber}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.black12, thickness: 2),
                            const SizedBox(height: 16),
                            if (_bill!.businessType == 'food_truck') ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Pickup No:', style: TextStyle(color: Colors.black54)),
                                  Text(
                                    '${_bill!.orderPickupNumber ?? '--'}',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Table:', style: TextStyle(color: Colors.black54)),
                                  Text(
                                    '${_bill!.tableNumber} (${_bill!.tableName})',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Text('Items:', style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 8),
                            ..._bill!.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.name}',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                      ),
                                      Text(
                                        '₹${item.subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.black12, thickness: 2),
                            const SizedBox(height: 16),
                            _receiptRow('Subtotal', _bill!.subtotal),
                            const SizedBox(height: 8),
                            _receiptRow('Tax (${_bill!.taxPercent}%)', _bill!.taxAmount),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.black12, thickness: 2),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18),
                                ),
                                Text(
                                  '₹${_bill!.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: Text(
                                _bill!.paymentStatus == 'paid' ? 'PAID via ${_bill!.paymentMethod}' : 'PENDING PAYMENT',
                                style: TextStyle(
                                  color: _bill!.paymentStatus == 'paid' ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Center(
                              child: Text(
                                'Thank you for dining with us!',
                                style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _receiptRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}
