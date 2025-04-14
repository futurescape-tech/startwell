import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/themes/app_theme.dart';

class StartwellWalletPage extends StatelessWidget {
  const StartwellWalletPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wallet Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Implement refresh functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletBalanceSection(),
            const SizedBox(height: 24),
            _buildWalletHistorySection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement recharge functionality
        },
        backgroundColor: AppTheme.purple,
        icon: const Icon(Icons.add),
        label: Text(
          'Recharge Wallet',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBalanceSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹0.00',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceBreakdown(
                    'Usable Balance',
                    '₹0.00',
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceBreakdown(
                    'Locked Balance',
                    '₹0.00',
                    Icons.lock,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBreakdown(String title, String amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.purple,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletHistorySection() {
    // Sample transaction data
    List<Map<String, String>> transactions = [
      {
        "date": "Mon, 15 Apr 2025",
        "description": "Meal Plan Recharge",
        "amount": "₹500.00",
        "type": "Credit",
        "paymentMode": "PhonePe",
        "transactedBy": "Parent"
      },
      {
        "date": "Sun, 14 Apr 2025",
        "description": "Lunch Plan Subscription",
        "amount": "₹340.00",
        "type": "Debit",
        "paymentMode": "Startwell Wallet",
        "transactedBy": "System"
      },
      {
        "date": "Sat, 13 Apr 2025",
        "description": "Wallet Recharge",
        "amount": "₹1000.00",
        "type": "Credit",
        "paymentMode": "Razorpay",
        "transactedBy": "Parent"
      },
      {
        "date": "Fri, 12 Apr 2025",
        "description": "Breakfast Plan Subscription",
        "amount": "₹420.00",
        "type": "Debit",
        "paymentMode": "Startwell Wallet",
        "transactedBy": "System"
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.purple),
              onPressed: () {
                // TODO: Implement refresh functionality
              },
              tooltip: 'Refresh transactions',
            ),
          ],
        ),
        const SizedBox(height: 8),
        transactions.isEmpty
            ? _buildEmptyTransactionsView()
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final txn = transactions[index];
                  return _buildTransactionCard(txn);
                },
              ),
      ],
    );
  }

  Widget _buildEmptyTransactionsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No transactions yet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Transactions will appear here when you use your wallet",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, String> txn) {
    final isCredit = txn["type"] == "Credit";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoRowWithIcon(
                  Icons.calendar_today,
                  "Date",
                  txn["date"] ?? "",
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    txn["type"] ?? "",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCredit
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRowWithIcon(
              Icons.description,
              "Description",
              txn["description"] ?? "",
            ),
            const SizedBox(height: 8),
            _buildInfoRowWithIcon(
              Icons.currency_rupee,
              "Amount",
              txn["amount"] ?? "",
              valueColor:
                  isCredit ? Colors.green.shade700 : Colors.red.shade700,
              valueFontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            _buildInfoRowWithIcon(
              Icons.payment,
              "Payment Mode",
              txn["paymentMode"] ?? "",
            ),
            const SizedBox(height: 8),
            _buildInfoRowWithIcon(
              Icons.person,
              "Transacted By",
              txn["transactedBy"] ?? "",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value,
      {Color? valueColor, FontWeight? valueFontWeight}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.purple,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: "$label: ",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: valueFontWeight ?? FontWeight.normal,
                    color: valueColor ?? AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
