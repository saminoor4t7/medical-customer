import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model.dart';
import 'provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({required this.token, super.key});

  final String token;

  static const navy = Color(0xFF061A33);
  static const card = Color(0xFF09243D);
  static const teal = Color(0xFF00C9A7);
  static const muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider(token));
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Orders'),
      ),
      body: ValueListenableBuilder<List<PlacedOrder>>(
        valueListenable: orders,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No orders yet.', style: TextStyle(color: muted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _OrderCard(order: items[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final summary = order.items.isEmpty
        ? 'Order items'
        : order.items.map((item) => '${item.quantity} item(s)').join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrdersScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OrdersScreen.teal.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                order.status.toUpperCase(),
                style: const TextStyle(
                  color: OrdersScreen.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(summary, style: const TextStyle(color: OrdersScreen.muted)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.paymentMethod.toUpperCase(),
                style: const TextStyle(color: OrdersScreen.muted),
              ),
              Text(
                'PKR ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
