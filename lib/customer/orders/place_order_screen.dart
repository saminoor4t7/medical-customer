import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../address/provider.dart';
import '../address/screen.dart';
import '../cart/model.dart';
import '../cart/provider.dart';
import 'provider.dart';
import 'model.dart';

class PlaceOrderScreen extends ConsumerStatefulWidget {
  const PlaceOrderScreen({required this.token, required this.cart, super.key});

  final String token;
  final Cart cart;

  @override
  ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
  static const navy = Color(0xFF061A33);
  static const card = Color(0xFF09243D);
  static const teal = Color(0xFF00C9A7);
  static const muted = Color(0xFF9AAEC3);
  bool _isPlacing = false;

  double get _total => widget.cart.grandTotal == 0
      ? widget.cart.subtotal - widget.cart.discountTotal
      : widget.cart.grandTotal;

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressProvider(widget.token));
    final loadedAddresses = addresses.asData?.value;
    final address = loadedAddresses?.isNotEmpty == true
        ? loadedAddresses!.firstWhere(
            (item) => item.isDefault,
            orElse: () => loadedAddresses.first,
          )
        : null;

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Place Order'),
      ),
      body: addresses.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: teal)),
        error: (error, _) => _Message(
          text: 'Unable to load delivery address\n$error',
          onRetry: () => ref.invalidate(addressProvider(widget.token)),
        ),
        data: (_) => address == null
            ? _Message(
                text: 'Please add a delivery address first.',
                actionLabel: 'Add Address',
                onRetry: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => AddressScreen(token: widget.token),
                    ),
                  );
                  ref.invalidate(addressProvider(widget.token));
                },
              )
            : _content(address),
      ),
    );
  }

  Widget _content(dynamic address) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _section(
          title: 'Delivery address',
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${address.label} - ${address.city}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.addressLine,
                      style: const TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => AddressScreen(token: widget.token),
                    ),
                  );
                  if (mounted) setState(() {});
                  ref.invalidate(addressProvider(widget.token));
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _section(
          title: 'Payment method',
          child: const Row(
            children: [
              Icon(Icons.payments_outlined, color: teal),
              SizedBox(width: 12),
              Text(
                'Cash on delivery',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _section(
          title: 'Order summary',
          child: Column(
            children: [
              _summaryRow('Items', '${widget.cart.items.length}'),
              const SizedBox(height: 10),
              _summaryRow(
                'Subtotal',
                'PKR ${widget.cart.subtotal.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 10),
              _summaryRow(
                'Discount',
                'PKR ${widget.cart.discountTotal.toStringAsFixed(2)}',
              ),
              const Divider(color: Colors.white24, height: 24),
              _summaryRow(
                'Total',
                'PKR ${_total.toStringAsFixed(2)}',
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _isPlacing ? null : () => _place(address.id),
            icon: _isPlacing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isPlacing ? 'Placing order...' : 'Place Order'),
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool strong = false}) {
    final style = TextStyle(
      color: strong ? Colors.white : muted,
      fontSize: strong ? 17 : 14,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }

  Future<void> _place(int? addressId) async {
    if (addressId == null) return;
    setState(() => _isPlacing = true);
    try {
      final order = await ref
          .read(placeOrderControllerProvider)
          .place(widget.token, PlaceOrderRequest(addressId: addressId));
      ref.invalidate(cartProvider(widget.token));
      ref.invalidate(ordersProvider(widget.token));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: card,
          title: const Text(
            'Order placed successfully',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Order #${order.id}\nStatus: ${order.status}',
            style: const TextStyle(color: muted),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to place order: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry, this.actionLabel});

  final String text;
  final VoidCallback? onRetry;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _PlaceOrderScreenState.muted),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(actionLabel ?? 'Retry'),
          ),
        ],
      ],
    ),
  );
}