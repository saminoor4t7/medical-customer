import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../address/provider.dart';
import '../address/screen.dart';
import '../orders/place_order_screen.dart';
import 'model.dart';
import 'provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({required this.token, super.key});

  final String token;

  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color cardColor2 = Color(0xFF0B2942);
  static const Color teal = Color(0xFF00C9A7);
  static const Color tealDark = Color(0xFF087F79);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider(token));

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: cart.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: teal)),
          error: (error, _) => _refreshable(
            context,
            _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(cartProvider(token));
              },
            ),
            ref,
          ),
          data: (value) {
            if (value.items.isEmpty) {
              return _refreshable(context, const _EmptyCart(), ref);
            }

            return RefreshIndicator(
              color: teal,
              backgroundColor: cardColor,
              onRefresh: () async {
                ref.invalidate(cartProvider(token));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      onBack: () {
                        Navigator.of(context).pop();
                      },
                      onClear: () {
                        _clear(context, ref);
                      },
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 10),

                        // Delivery
                        _DeliveryCard(token: token),

                        const SizedBox(height: 22),

                        // Cart title
                        _SectionHeader(
                          title: 'Cart Items (${value.items.length})',
                          trailing: 'Add more items',
                          onTap: () {
                            Navigator.of(context).maybePop();
                          },
                        ),

                        const SizedBox(height: 10),

                        // Items
                        for (final item in value.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: _CartItemTile(token: token, item: item),
                          ),

                        const SizedBox(height: 16),

                        // Savings
                        _SavingsCard(cart: value),

                        const SizedBox(height: 22),

                        // Price summary
                        _PriceSummary(cart: value),

                        const SizedBox(height: 18),

                        // Checkout
                        _CheckoutButton(
                          cart: value,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PlaceOrderScreen(token: token, cart: value),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        const _SecureCheckout(),

                        const SizedBox(height: 10),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _refreshable(BuildContext context, Widget child, WidgetRef ref) {
    return RefreshIndicator(
      color: teal,
      backgroundColor: cardColor,
      onRefresh: () async {
        ref.invalidate(cartProvider(token));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: child,
        ),
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Clear cart?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'All items will be removed from your cart.',
            style: TextStyle(color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel', style: TextStyle(color: muted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: navy,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(cartControllerProvider).clear(token);

      ref.invalidate(cartProvider(token));
    } catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB3261E),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onClear});

  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Back',
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review your items and place your order',
                  style: TextStyle(color: Color(0xFF9AAEC3), fontSize: 15),
                ),
              ],
            ),
          ),

          _CircleButton(icon: Icons.delete_outline, onTap: onClear),
        ],
      ),
    );
  }
}

// ============================================================
// CIRCLE BUTTON
// ============================================================

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF09243D),
            border: Border.all(color: const Color(0xFF00A99A).withOpacity(.45)),
          ),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
      ),
    );
  }
}

// ============================================================
// DELIVERY CARD
// ============================================================

class _DeliveryCard extends ConsumerWidget {
  const _DeliveryCard({required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider(token));

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: CartScreen.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF087F79).withOpacity(.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CartScreen.teal.withOpacity(.10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: CartScreen.teal,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: addresses.when(
              loading: () => const Text(
                'Loading address...',
                style: TextStyle(color: CartScreen.muted, fontSize: 13),
              ),
              error: (_, _) => const Text(
                'Unable to load address',
                style: TextStyle(color: CartScreen.muted, fontSize: 13),
              ),
              data: (items) {
                final address = items.isEmpty
                    ? null
                    : items.firstWhere(
                        (item) => item.isDefault,
                        orElse: () => items.first,
                      );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deliver to',
                      style: TextStyle(color: CartScreen.muted, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      address == null
                          ? 'No delivery address'
                          : '${address.label} - ${address.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (address != null && address.addressLine.isNotEmpty)
                      Text(
                        address.addressLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CartScreen.muted,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Estimated delivery: ',
                            style: TextStyle(
                              color: CartScreen.muted,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: 'Today, 10:00 PM - 10:30 PM',
                            style: TextStyle(
                              color: CartScreen.teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddressScreen(token: token),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: CartScreen.teal,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Add more items',
            style: TextStyle(
              color: CartScreen.teal,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CART ITEM
// ============================================================

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.token, required this.item});

  final String token;
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CartScreen.cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF0B5061).withOpacity(.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFF102F45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: item.imageUrl == null || item.imageUrl!.isEmpty
                ? const Icon(
                    Icons.medication_outlined,
                    color: CartScreen.teal,
                    size: 34,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.medication_outlined,
                          color: CartScreen.teal,
                          size: 34,
                        );
                      },
                    ),
                  ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => _remove(context, ref),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.delete_outline,
                          color: Color(0xFF8EA2B5),
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'PKR ${item.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: CartScreen.teal,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: item.quantity > 1
                          ? () => _update(context, ref, item.quantity - 1)
                          : null,
                    ),

                    SizedBox(
                      width: 38,
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    _QuantityButton(
                      icon: Icons.add,
                      onTap: () => _update(context, ref, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    int quantity,
  ) async {
    try {
      await ref.read(cartControllerProvider).update(token, item.id, quantity);

      ref.invalidate(cartProvider(token));
    } catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(cartControllerProvider).remove(token, item.id);

      ref.invalidate(cartProvider(token));
    } catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// QUANTITY BUTTON
// ============================================================

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10354A),
          border: Border.all(color: const Color(0xFF176074)),
        ),
        child: Icon(
          icon,
          size: 17,
          color: onTap == null ? const Color(0xFF526779) : Colors.white,
        ),
      ),
    );
  }
}

// ============================================================
// SAVINGS
// ============================================================

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF079B83), Color(0xFF0877A0)],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.percent, color: Colors.white),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yay! You saved PKR ${cart.discountTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'on this order',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.card_giftcard_outlined,
            color: Colors.white54,
            size: 34,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRICE SUMMARY
// ============================================================

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotal == 0 ? cart.calculatedTotal : cart.subtotal;
    final total = cart.grandTotal == 0
        ? subtotal - cart.discountTotal + cart.deliveryFee
        : cart.grandTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Summary',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 15),

        _SummaryRow(
          icon: Icons.receipt_long_outlined,
          title: 'Subtotal (${cart.items.length} items)',
          value: 'PKR ${subtotal.toStringAsFixed(2)}',
        ),

        const SizedBox(height: 12),

        _SummaryRow(
          icon: Icons.local_shipping_outlined,
          title: 'Delivery Charges',
          value: 'PKR ${cart.deliveryFee.toStringAsFixed(2)}',
          valueColor: CartScreen.teal,
        ),

        const SizedBox(height: 12),

        _SummaryRow(
          icon: Icons.local_offer_outlined,
          title: 'Discount',
          value: '- PKR ${cart.discountTotal.toStringAsFixed(2)}',
          valueColor: CartScreen.teal,
        ),

        const SizedBox(height: 16),

        Container(height: 1, color: const Color(0xFF274055)),

        const SizedBox(height: 15),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Total Amount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'PKR ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: CartScreen.teal,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// SUMMARY ROW
// ============================================================

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: CartScreen.muted, size: 20),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: CartScreen.muted, fontSize: 14),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CHECKOUT BUTTON
// ============================================================

class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton({required this.cart, required this.onPressed});

  final Cart cart;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final total = cart.grandTotal == 0
        ? cart.subtotal - cart.discountTotal
        : cart.grandTotal;

    return SizedBox(
      height: 58,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: CartScreen.teal,
          foregroundColor: CartScreen.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Proceed to Place Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),

            Text(
              'PKR ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),

            const SizedBox(width: 10),

            const Icon(Icons.arrow_forward, size: 21),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECURE CHECKOUT
// ============================================================

class _SecureCheckout extends StatelessWidget {
  const _SecureCheckout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, color: CartScreen.muted, size: 16),
        SizedBox(width: 7),
        Text(
          'Secure Checkout',
          style: TextStyle(color: CartScreen.muted, fontSize: 13),
        ),
      ],
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

// ============================================================
// EMPTY CART
// ============================================================

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CartScreen.navy,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 78,
              color: CartScreen.teal,
            ),

            SizedBox(height: 18),

            Text(
              'Your cart is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Add medicines and health products\nto your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CartScreen.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR VIEW
// ============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CartScreen.navy,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 55,
              ),

              const SizedBox(height: 14),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CartScreen.muted),
              ),

              const SizedBox(height: 18),

              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: CartScreen.teal,
                  foregroundColor: CartScreen.navy,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
