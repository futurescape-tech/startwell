import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/wallet_transaction.dart';
import 'package:startwell/services/wallet_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/app_colors.dart';
import 'package:startwell/widgets/empty_state.dart';
import 'package:startwell/widgets/loading.dart';

// Move the extension outside the class definition
extension WidgetAnimationExtension on Widget {
  Widget animate() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: AppTheme.purpleToDeepPurple,
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: this,
    );
  }
}

class StartwellWalletPage extends StatefulWidget {
  const StartwellWalletPage({super.key});

  @override
  State<StartwellWalletPage> createState() => _StartwellWalletPageState();
}

class _StartwellWalletPageState extends State<StartwellWalletPage> {
  final WalletService _walletService = WalletService();

  double _totalBalance = 0.0;
  double _usableBalance = 0.0;
  double _lockedBalance = 0.0;

  List<WalletTransaction> _transactions = [];

  bool _isLoading = true;
  bool _isAddingMoney = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasPrecachedImages = false;

  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'PhonePe';

  // Payment method icons mapping with fallback mechanism
  final Map<String, String> paymentMethodIcons = {
    'PhonePe': 'assets/images/payment/phonepe.png',
    'Google Pay': 'assets/images/payment/gpay.png',
    'Paytm': 'assets/images/payment/paytm.png',
  };

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    // Remove context-dependent code from initState
    // _precachePaymentImages() will be called in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only precache images once
    if (!_hasPrecachedImages) {
      _precachePaymentImages();
      _hasPrecachedImages = true;
    }
  }

  // Pre-cache payment method images
  void _precachePaymentImages() {
    for (final imagePath in paymentMethodIcons.values) {
      precacheImage(AssetImage(imagePath), context).catchError((_) {
        // Silently handle any image loading errors during precaching
        debugPrint('Failed to precache: $imagePath');
      });
    }
    // Precache wallet icon
    precacheImage(const AssetImage('assets/images/payment/wallet.png'), context)
        .catchError((_) {
      debugPrint('Failed to precache wallet icon');
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Fetch wallet balance and transaction history
  Future<void> _fetchWalletData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      // Fetch wallet balance
      final balanceData = await _walletService.getWalletBalance();
      final transactions = await _walletService.getTransactionHistory();

      if (mounted) {
        setState(() {
          _totalBalance = balanceData['totalBalance'] ?? 0.0;
          _usableBalance = balanceData['usableBalance'] ?? 0.0;
          _lockedBalance = balanceData['lockedBalance'] ?? 0.0;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet data: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load wallet data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // Show add money modal
  void _showAddMoneyModal() {
    _amountController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Money to Wallet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    'PhonePe',
                    paymentMethodIcons['PhonePe']!,
                    _selectedPaymentMethod == 'PhonePe',
                    () {
                      setModalState(() => _selectedPaymentMethod = 'PhonePe');
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    'Google Pay',
                    paymentMethodIcons['Google Pay']!,
                    _selectedPaymentMethod == 'Google Pay',
                    () {
                      setModalState(
                          () => _selectedPaymentMethod = 'Google Pay');
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    'Paytm',
                    paymentMethodIcons['Paytm']!,
                    _selectedPaymentMethod == 'Paytm',
                    () {
                      setModalState(() => _selectedPaymentMethod = 'Paytm');
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAddingMoney
                          ? null
                          : () => _addMoneyToWallet(setModalState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isAddingMoney
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Add Money'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Add money to wallet
  Future<void> _addMoneyToWallet(StateSetter setModalState) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showSnackBar('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount');
      return;
    }

    setModalState(() => _isAddingMoney = true);

    try {
      await _walletService.addMoney(amount, _selectedPaymentMethod);

      Navigator.pop(context); // Close the modal

      await _fetchWalletData(); // Refresh wallet data

      if (mounted) {
        _showSnackBar('Successfully added ₹$amount to your wallet');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
        setModalState(() => _isAddingMoney = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Build payment method option with fallback icon handling
  Widget _buildPaymentMethodOption(
    String name,
    String imagePath,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Image with error handling
            _buildImageWithFallback(
              imagePath: imagePath,
              height: 30,
              width: 30,
              fallbackIcon: Icons.payment,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  // Widget to handle image loading with fallback
  Widget _buildImageWithFallback({
    required String imagePath,
    required double height,
    required double width,
    required IconData fallbackIcon,
    Color? iconColor,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: Image.asset(
        imagePath,
        height: height,
        width: width,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image $imagePath: $error');
          return Icon(
            fallbackIcon,
            size: height * 0.8,
            color: iconColor ?? AppColors.primary,
          );
        },
      ),
    );
  }

  String _formatAmount(double amount) {
    final NumberFormat formatter = NumberFormat("#,##0.00", "en_IN");
    return '₹${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Startwell Wallet',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.purpleToDeepPurple,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: _isLoading
            ? const Loading()
            : _hasError
                ? _buildErrorView()
                : _buildWalletContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Could not load wallet data",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchWalletData,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Use LayoutBuilder to ensure responsive UI
  Widget _buildWalletContent() {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Constrain all content to screen width
            SizedBox(
              width: maxWidth - 32, // Account for padding
              child: _buildWalletBalanceCard(),
            ),
            const SizedBox(height: 20),
            _buildAddMoneyButton(),
            const SizedBox(height: 30),
            _buildTransactionHistorySection(maxWidth),
          ],
        ),
      );
    });
  }

  Widget _buildWalletBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF7B68EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildImageWithFallback(
                  imagePath: 'assets/images/payment/wallet.png',
                  height: 32,
                  width: 32,
                  fallbackIcon: Icons.account_balance_wallet,
                  iconColor: Colors.white,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _formatAmount(_totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceInfo(
                    'Usable Balance',
                    _formatAmount(_usableBalance),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBalanceInfo(
                    'Locked Balance',
                    _formatAmount(_lockedBalance),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoneyButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange,
              Colors.deepOrangeAccent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _showAddMoneyModal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Money',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistorySection(double maxWidth) {
    return SizedBox(
      width: maxWidth - 32, // Account for padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Transaction History'),
          const SizedBox(height: 15),
          if (_transactions.isEmpty)
            EmptyState(
              icon: Icons.receipt_long,
              title: 'No transactions found',
              message: 'Your transaction history will appear here',
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.deepPurple,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final DateFormat dateFormat = DateFormat('EEE, dd MMM yyyy');
    final bool isCredit = transaction.type == TransactionType.credit;
    final Color indicatorColor = isCredit ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      shadowColor: AppTheme.deepPurple.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: indicatorColor,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: indicatorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(transaction.date)} • ${transaction.paymentMode}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isCredit ? '+' : '-'} ${_formatAmount(transaction.amount)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: indicatorColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(WalletTransaction transaction) {
    final details = transaction.toDisplayMap();
    final bool isCredit = transaction.type == TransactionType.credit;
    final Color indicatorColor = isCredit ? Colors.green : Colors.red;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: indicatorColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Transaction Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: details.entries
                      .map((entry) => _buildDetailItem(entry.key, entry.value))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
