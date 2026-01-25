import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:connect/components/menu_item.dart';
import 'package:connect/components/bottom_sheet_wrapper.dart';
import 'package:connect/services/user_api_service.dart';
import 'package:connect/models/user_profile.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/auth/google_auth_service.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:connect/services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/services/payment_api_service.dart';
import 'package:connect/models/wallet_balance.dart';
import 'package:connect/services/user_heartbeat_manager.dart';
import 'package:connect/services/call_heartbeat_manager.dart';
import 'package:connect/core/utils/ui_utils.dart';
import 'package:connect/core/config/currency_config.dart';
import 'dart:developer' as developer;

@NowaGenerated()
class ProfilePage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserApiService _userApiService = UserApiService();
  final PaymentApiService _paymentApiService = PaymentApiService();
  UserProfile? _userProfile;
  WalletBalance? _walletBalance;
  double _conversionRate = 50.0; // Default if API fails
  bool _isLoading = true;
  bool _isPaymentProcessing = false;
  late RazorpayService _razorpayService;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _fetchProfile();
  }

  void _initRazorpay() {
    _razorpayService = RazorpayService(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(String message) {
    if (mounted) {
      setState(() {
        _isPaymentProcessing = false;
      });
      UiUtils.showSuccessSnackBar(message);
      _fetchProfile(); // Refresh profile to see updated balance
    }
  }

  void _handlePaymentError(String message) {
    if (mounted) {
      setState(() {
        _isPaymentProcessing = false;
      });
      if (message.contains('cancelled')) {
        UiUtils.showWarningSnackBar(message);
      } else {
        UiUtils.showErrorSnackBar(message);
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      UiUtils.showInfoSnackBar(
          'External Wallet Selected: ${response.walletName}');
    }
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _userApiService.getUserProfile();
      final balance = await _paymentApiService.getWalletBalance();

      if (mounted) {
        if (profile != null) {
          await TokenManager.saveUserType(profile.userType);
        }
        setState(() {
          _userProfile = profile;
          _walletBalance = balance.data;
          _isLoading = false;
        });
        _fetchConversionRate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchConversionRate() async {
    try {
      final response = await _paymentApiService.getConversionRate();
      if (mounted && response.data != null) {
        setState(() {
          _conversionRate = (response.data!['rate'] ?? 50.0).toDouble();
        });
      }
    } catch (e) {
      developer.log('Error fetching conversion rate: $e', name: 'ProfilePage');
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // 1. Clear local tokens
    await TokenManager.clearTokens();

    // 2. Stop heartbeats
    UserHeartbeatManager.instance.stop();
    CallHeartbeatManager.instance.stop();

    // 3. Sign out from Google to force account picker next time
    await GoogleAuthService().signOut();

    // 4. Uninit Zego
    await ZegoUIKitPrebuiltCallInvitationService().uninit();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        'LoginPage',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Main Profile Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Profile Photo with Edit Icon
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: _userProfile?.photoUrl != null &&
                                            _userProfile!.photoUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            child: Image.network(
                                              _userProfile!.photoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerLowest,
                                          width: 3,
                                        ),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          UiUtils.showInfoSnackBar(
                                              'Edit photo coming soon!');
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Name
                              Text(
                                _userProfile?.displayName ?? 'Guest User',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                              if (_userProfile?.email != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _userProfile!.email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Joining Date
                              if (_userProfile?.createdOn != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Joined ${_formatDate(_userProfile!.createdOn)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 32),
                              // Divider
                              Divider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 24),
                              // Action Buttons Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.edit_outlined,
                                      label: 'Edit Profile',
                                      onPressed: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          'EditProfilePage',
                                          arguments: _userProfile,
                                        );
                                        _fetchProfile(); // Refresh on return
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _ActionButton(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      label: 'Add ${CurrencyConfig.coinName}',
                                      onPressed: () {
                                        if (_userProfile == null) return;
                                        _showAddBalanceDialog(context);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Stats Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'User ID',
                                  value: _userProfile?.userId ?? '-',
                                  context: context,
                                  onTap: () {
                                    if (_userProfile?.userId != null) {
                                      Clipboard.setData(ClipboardData(
                                          text: _userProfile!.userId));
                                      UiUtils.showInfoSnackBar(
                                          'ID copied to clipboard');
                                    }
                                  },
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.2),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Balance',
                                  value: _walletBalance?.formattedBalance ??
                                      '${CurrencyConfig.coinIconText}0',
                                  context: context,
                                  onTap: () => _showAddBalanceDialog(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Menu Items
                        MenuItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Transactions',
                          onTap: () {
                            Navigator.pushNamed(context, 'PaymentHistoryPage');
                          },
                        ),
                        const SizedBox(height: 12),
                        MenuItem(
                          icon: Icons.language_outlined,
                          label: 'Change Language',
                          onTap: () {
                            Navigator.pushNamed(
                                context, 'PreferredLanguagePage');
                          },
                        ),
                        const SizedBox(height: 12),
                        MenuItem(
                          icon: Icons.logout_outlined,
                          label: 'Logout',
                          onTap: () {
                            _showLogoutConfirmation(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        MenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () {
                            Navigator.pushNamed(context, 'SettingsPage');
                          },
                        ),
                        const SizedBox(height: 12),
                        MenuItem(
                          icon: Icons.delete_outline,
                          label: 'Delete Account',
                          isDestructive: true,
                          onTap: () {
                            UiUtils.showInfoSnackBar(
                                'Delete account coming soon!');
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          if (_isPaymentProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          'Processing Payment...',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please do not close the app',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return 'January 2026'; // Fallback
    }
  }

  void _showAddBalanceDialog(BuildContext context) {
    final TextEditingController amountController =
        TextEditingController(text: '100');
    final List<int> quickAmounts = [50, 100, 500, 1000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => BottomSheetWrapper(
          title: 'Add ${CurrencyConfig.coinName}',
          footer: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  UiUtils.showWarningSnackBar('Please enter a valid amount');
                  return;
                }
                Navigator.pop(context);
                setState(() {
                  _isPaymentProcessing = true;
                });
                _razorpayService
                    .openCheckout(
                  amount: amount,
                  currency: 'COIN',
                  name: 'Connect App',
                  description: 'Add ${CurrencyConfig.coinName} to wallet',
                  userProfile: _userProfile!,
                  razorpayKey: ApiConstants.razorpayKey,
                )
                    .catchError((e) {
                  if (mounted) {
                    setState(() {
                      _isPaymentProcessing = false;
                    });
                    UiUtils.showErrorSnackBar('Error starting payment: $e');
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Proceed to Pay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recharge your wallet to connect with experts',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Quick Amounts
              Text(
                'Quick Select (Tap to add)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: quickAmounts.map((amount) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setSheetState(() {
                            final current =
                                int.tryParse(amountController.text) ?? 0;
                            amountController.text =
                                (current + amount).toString();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            '+$amount',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Custom Amount Input
              Text(
                'Custom Amount',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      CurrencyConfig.coinIconText,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
                onChanged: (value) {
                  setSheetState(() {});
                },
              ),

              // Conversion Info
              if (_conversionRate > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 INR = ${_conversionRate.toStringAsFixed(0)} ${CurrencyConfig.coinName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Builder(
                        builder: (context) {
                          final coinAmount =
                              double.tryParse(amountController.text) ?? 0.0;
                          final inrEquivalent = coinAmount / _conversionRate;
                          return Text(
                            'Pay: ₹${inrEquivalent.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.context,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
