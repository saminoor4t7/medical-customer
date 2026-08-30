import 'package:flutter/material.dart';
import 'profile/screen.dart';

import 'cart/screen.dart';
import 'categories/screen.dart';
import 'catalog/screen.dart';
import 'orders/screen.dart';


class CustomerShell extends StatefulWidget {
  const CustomerShell({
    required this.accessToken,
    required this.refreshToken,
    super.key,
  });

  final String accessToken;
  final String refreshToken;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(token: widget.accessToken),
      CategoriesScreen(token: widget.accessToken),
      OrdersScreen(token: widget.accessToken),
      CartScreen(token: widget.accessToken),
      ProfileScreen(
        token: widget.accessToken,
        refreshToken: widget.refreshToken,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Category',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
