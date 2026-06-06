import 'package:customer_app/screens/order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final String? tableId;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    this.tableId,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tableId != null) {
        context
            .read<CustomerMenuProvider>()
            .fetchMenu(widget.restaurantId, widget.tableId!);
      } else {
        context
            .read<CustomerMenuProvider>()
            .fetchTruckMenu(widget.restaurantId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String category) {
    final key = _categoryKeys[category];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Consumer<CustomerMenuProvider>(
        builder: (_, menuProv, __) {
          if (menuProv.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF0A0A14),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
              ),
            );
          }
          if (menuProv.errorMessage != null) {
            final isNotServiceable =
                menuProv.errorMessage!.toLowerCase().contains('serviceable');
            return Scaffold(
              backgroundColor: const Color(0xFF0A0A14),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNotServiceable
                            ? Icons.table_restaurant_rounded
                            : Icons.error_outline_rounded,
                        size: 48,
                        color: const Color(0xFFFF4757),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        menuProv.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isNotServiceable &&
                          menuProv.availableTables != null &&
                          menuProv.availableTables!.isNotEmpty) ...[
                        Text(
                          'Available Tables:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: menuProv.availableTables!.map<Widget>((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF06D6A0).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF06D6A0)
                                        .withOpacity(0.3)),
                              ),
                              child: Text(
                                '${t['tableName'] ?? 'Table ${t['tableNumber']}'}',
                                style: const TextStyle(
                                  color: Color(0xFF06D6A0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: () {
                            if (widget.tableId != null) {
                              menuProv.fetchMenu(widget.restaurantId, widget.tableId!);
                            } else {
                              menuProv.fetchTruckMenu(widget.restaurantId);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35)),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }

          final allCategories = ['All', ...menuProv.categories];

          // Build category keys
          for (final cat in menuProv.categories) {
            _categoryKeys.putIfAbsent(cat, () => GlobalKey());
          }

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // App bar with restaurant info
                  SliverAppBar(
                    backgroundColor: const Color(0xFF0A0A14),
                    floating: false,
                    pinned: true,
                    expandedHeight: 180,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: EdgeInsets.fromLTRB(20,
                            MediaQuery.of(context).padding.top + 40, 20, 52),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF12121F), Color(0xFF0A0A14)],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            children: [
                              if (menuProv.restaurantInfo?.logoUrl != null)
                                CachedNetworkImage(
                                  imageUrl: menuProv.restaurantInfo!.logoUrl!,
                                  width: 50,
                                  height: 50,
                                  imageBuilder: (_, img) => Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: img, fit: BoxFit.cover),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => _logoPlaceholder(
                                      menuProv.restaurantInfo?.name ?? ''),
                                )
                              else
                                _logoPlaceholder(
                                    menuProv.restaurantInfo?.name ?? ''),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      menuProv.restaurantInfo?.name ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if (menuProv.tableInfo != null)
                                      Text(
                                        'Table ${menuProv.tableInfo?.tableNumber ?? ''} — ${menuProv.tableInfo?.tableName ?? ''}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(52),
                      child: Container(
                        height: 52,
                        color: const Color(0xFF0A0A14),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: allCategories.length,
                          itemBuilder: (_, idx) {
                            final cat = allCategories[idx];
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCategory = cat);
                                  if (cat != 'All') _scrollToCategory(cat);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFF6B35)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white54,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (menuProv.isOfflineMode)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB020).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFB020).withOpacity(0.25),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              color: Color(0xFFFFB020),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Showing saved menu',
                                style: TextStyle(
                                  color: Color(0xFFFFB020),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Menu items
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, idx) {
                          final cats = menuProv.categories;
                          if (idx >= cats.length) return null;
                          final cat = cats[idx];
                          final items = menuProv.menuByCategory[cat] ?? [];
                          return _CategorySection(
                            key: _categoryKeys[cat],
                            category: cat,
                            items: items,
                          );
                        },
                        childCount: menuProv.categories.length,
                      ),
                    ),
                  ),
                ],
              ),
              // Persistent cart bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Consumer<CartProvider>(
                  builder: (_, cart, __) {
                    if (cart.totalItems == 0) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.all(16),
                      child: SafeArea(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartScreen(
                                restaurantId: widget.restaurantId,
                                tableId: widget.tableId,
                                restaurantInfo: menuProv.restaurantInfo!,
                                tableInfo: menuProv.tableInfo,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B35), Color(0xFFFF9A3C)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF6B35).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${cart.totalItems}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'View Cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '₹${cart.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Persistent Active Order Banner
              Positioned(
                bottom: 80, // Above the cart bar (if any) or just at the bottom
                left: 0,
                right: 0,
                child: Consumer<CustomerOrderProvider>(
                  builder: (context, provider, child) {
                    if (provider.placedOrderId != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderTrackingScreen(
                                    orderId: provider.placedOrderId!),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06D6A0).withOpacity(0.1),
                              border: Border.all(
                                  color:
                                      const Color(0xFF06D6A0).withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    color: Color(0xFF06D6A0)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Active Order Found',
                                          style: TextStyle(
                                              color: Color(0xFF06D6A0),
                                              fontWeight: FontWeight.w700)),
                                      Text('Tap to track your order or pay',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF06D6A0), size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _logoPlaceholder(String name) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFF6B35).withOpacity(0.15),
        ),
        child: Center(
          child: Text(
            name.isEmpty ? 'R' : name[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<MenuItemModel> items;

  const _CategorySection(
      {super.key, required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
          child: Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        ...items.map((item) => _MenuItemCard(item: item)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;

  const _MenuItemCard({required this.item});

  void _showItemDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showItemDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.isVeg
                                ? const Color(0xFF06D6A0)
                                : const Color(0xFFFF4757),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.isVeg
                                  ? const Color(0xFF06D6A0)
                                  : const Color(0xFFFF4757),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.white.withOpacity(0.06),
                            child: const Icon(Icons.fastfood_rounded,
                                color: Colors.white24, size: 28),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.white.withOpacity(0.06),
                            child: const Icon(Icons.fastfood_rounded,
                                color: Colors.white24, size: 28),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fastfood_rounded,
                              color: Colors.white24, size: 28),
                        ),
                ),
                const SizedBox(height: 8),
                Consumer<CartProvider>(
                  builder: (_, cart, __) {
                    final qty = cart.quantityOf(item.id);
                    if (qty == 0) {
                      return GestureDetector(
                        onTap: () => cart.addItem(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFF6B35)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADD',
                            style: TextStyle(
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => cart.decreaseQuantity(item.id),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.remove_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => cart.addItem(item),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.add_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemDetailSheet extends StatefulWidget {
  final MenuItemModel item;

  const _ItemDetailSheet({required this.item});

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  final _customizationCtrl = TextEditingController();

  @override
  void dispose() {
    _customizationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12121F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Image
            if (widget.item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: widget.item.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.item.isVeg
                          ? const Color(0xFF06D6A0)
                          : const Color(0xFFFF4757),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.item.isVeg
                            ? const Color(0xFF06D6A0)
                            : const Color(0xFFFF4757),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${widget.item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.item.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.item.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _customizationCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Special instructions (optional)',
                hintText: 'e.g., No sugar, Extra spicy...',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                prefixIcon: const Icon(Icons.edit_note_rounded,
                    color: Colors.white38, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<CartProvider>(
              builder: (_, cart, __) => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    cart.addItem(widget.item,
                        customization: _customizationCtrl.text.trim());
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Add to Cart',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
