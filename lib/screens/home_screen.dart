import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import 'menu_screen.dart';
import 'order_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  bool _scannerOpen = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _navigateToMenu(String url) {
    final parsed = _parseQrUrl(url.trim());
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR URL format'),
          backgroundColor: Color(0xFFFF4757),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          restaurantId: parsed['restaurantId']!,
          tableId: parsed['tableId']!,
        ),
      ),
    );
  }

  Map<String, String>? _parseQrUrl(String url) {
    // Expected: https://domain.com/menu/{restaurantId}/{tableId}
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final menuIdx = segments.indexOf('menu');
    if (menuIdx == -1 || segments.length < menuIdx + 3) return null;
    return {
      'restaurantId': segments[menuIdx + 1],
      'tableId': segments[menuIdx + 2],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF9A3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    size: 46, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'QR Cafe',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan the QR code on your table\nto browse the menu and order',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              // Scan button
              if (!_scannerOpen) ...[
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _scannerOpen = true),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                    label: const Text(
                      'Scan QR Code',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ] else ...[
                // QR Scanner
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        setState(() => _scannerOpen = false);
                        _navigateToMenu(barcode!.rawValue!);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _scannerOpen = false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
              ],
              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or paste URL',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
                ],
              ),
              const SizedBox(height: 20),
              // Manual URL input (for prototype testing)
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste table URL here...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFFFF6B35)),
                    onPressed: () => _navigateToMenu(_urlController.text),
                  ),
                ),
                onSubmitted: _navigateToMenu,
              ),
              const Spacer(),
              // Active Order Banner
              Consumer<CustomerOrderProvider>(
                builder: (context, provider, child) {
                  if (provider.placedOrderId != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderTrackingScreen(orderId: provider.placedOrderId!),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0).withOpacity(0.1),
                            border: Border.all(color: const Color(0xFF06D6A0).withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, color: Color(0xFF06D6A0)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Active Order Found', style: TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.w700)),
                                    Text('Tap to track your order or pay', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF06D6A0), size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
