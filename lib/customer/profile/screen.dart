import 'package:flutter/material.dart';
import 'package:mediacl_panda/customer/profile/model.dart';
import 'package:mediacl_panda/customer/profile/services.dart';

import '../../auth/logout/screen.dart';
import '../../core/app_theme.dart';
import '../address/screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.token,
    required this.refreshToken,
    super.key,
  });

  final String token;
  final String refreshToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CustomerProfile? _profile;

  String? _error;

  bool _loading = true;
  final _service = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ------------------------------------------------------------
  // LOAD PROFILE
  // ------------------------------------------------------------

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.getProfile(widget.token);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to connect to the server.';
        _loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // FIRST ADDRESS
  // ------------------------------------------------------------

  CustomerAddress? get _firstAddress {
    if (_profile?.addresses.isNotEmpty == true) {
      return _profile!.addresses.first;
    }

    return null;
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF061A33),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF061A33),
        body: _ErrorState(message: _error!, onRetry: _loadProfile),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061A33),
      body: Stack(
        children: [
          // Background decoration
          const _BackgroundDecoration(),

          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: const Color(0xFF0B223B),
              onRefresh: _loadProfile,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Manage your account and\npreferences',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .65),
                                    fontSize: 16,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _CircleIconButton(
                            icon: Icons.settings_outlined,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // PROFILE CARD
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _ProfileCard(profile: _profile, onTap: () {}),
                    ),
                  ),

                  // ------------------------------------------------
                  // WALLET + LANGUAGE
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'My Wallet',
                              value: 'PKR ${_profile?.walletBalance ?? '0.00'}',
                              bottomText: 'View transactions',
                              onTap: () {},
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.language,
                              title: 'Language',
                              value: _profile?.preferredLanguage ?? '-',
                              bottomText: 'Change language',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // MY ORDERS
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'My Orders',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _OrdersCard(),
                    ),
                  ),

                  // ------------------------------------------------
                  // ACCOUNT OPTIONS
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _AccountMenu(
                        address: _firstAddress,
                        onAddressTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AddressScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // LOGOUT
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
                      child: _LogoutButton(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LogoutScreen(
                              accessToken: widget.token,
                              refreshToken: widget.refreshToken,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BACKGROUND
// ================================================================

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -130,
            top: -110,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0BA99D).withValues(alpha: .13),
              ),
            ),
          ),

          Positioned(
            left: -170,
            bottom: 80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0BA99D).withValues(alpha: .08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PROFILE CARD
// ================================================================

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});

  final CustomerProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2038).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Image.asset('assets/logo.jpeg', fit: BoxFit.cover),
                ),
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                    border: Border.all(
                      color: const Color(0xFF0A2038),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer #${profile?.id ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 15, color: AppTheme.primary),
                      SizedBox(width: 5),
                      Text(
                        'Verified Customer',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Medical Panda Customer',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, color: AppTheme.primary, size: 28),
        ],
      ),
    );
  }
}

// ================================================================
// SUMMARY CARD
// ================================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.bottomText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String bottomText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2038).withValues(alpha: .78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: .10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 21),
            ),

            const SizedBox(height: 13),

            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                Expanded(
                  child: Text(
                    bottomText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .48),
                      fontSize: 11,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ORDERS
// ================================================================

class _OrdersCard extends StatelessWidget {
  const _OrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2038).withValues(alpha: .80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: .17)),
      ),
      child: Row(
        children: [
          _OrderItem(icon: Icons.receipt_long_outlined, title: 'All'),
          _OrderItem(icon: Icons.inventory_2_outlined, title: 'Processing'),
          _OrderItem(icon: Icons.delivery_dining_outlined, title: 'On Way'),
          _OrderItem(icon: Icons.check_circle_outline, title: 'Delivered'),
          _OrderItem(icon: Icons.cancel_outlined, title: 'Cancelled'),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF12304A),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACCOUNT MENU
// ================================================================

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.address, required this.onAddressTap});

  final CustomerAddress? address;
  final VoidCallback onAddressTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A2038).withValues(alpha: .80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: .17)),
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {},
          ),

          _MenuItem(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            subtitle: address == null
                ? 'No address saved'
                : _addressSummary(address!),
            onTap: onAddressTap,
          ),

          _MenuItem(
            icon: Icons.credit_card_outlined,
            title: 'Payment Methods',
            onTap: () {},
          ),

          _MenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'Prescriptions',
            onTap: () {},
          ),

          _MenuItem(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {},
          ),

          _MenuItem(
            icon: Icons.support_agent_outlined,
            title: 'Help & Support',
            onTap: () {},
          ),

          _MenuItem(
            icon: Icons.info_outline,
            title: 'About Medical Panda',
            showDivider: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MENU ITEM
// ================================================================

String _addressSummary(CustomerAddress address) {
  final parts = <String>[];

  if (address.label.trim().isNotEmpty) {
    parts.add(address.label.trim());
  }
  if (address.addressLine.trim().isNotEmpty) {
    parts.add(address.addressLine.trim());
  }
  if (address.city.trim().isNotEmpty) {
    parts.add(address.city.trim());
  }

  if (parts.isEmpty) {
    return 'No address saved';
  }

  return parts.join(' • ');
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 24),

                const SizedBox(width: 17),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .42),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right,
                  color: AppTheme.primary.withValues(alpha: .85),
                  size: 24,
                ),
              ],
            ),
          ),

          if (showDivider)
            Divider(
              height: 1,
              indent: 60,
              endIndent: 16,
              color: Colors.white.withValues(alpha: .07),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// LOGOUT
// ================================================================

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: .20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SETTINGS BUTTON
// ================================================================

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A2038).withValues(alpha: .8),
            border: Border.all(color: AppTheme.primary.withValues(alpha: .15)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ================================================================
// ERROR
// ================================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppTheme.primary,
              size: 55,
            ),

            const SizedBox(height: 18),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),

            const SizedBox(height: 16),

            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
