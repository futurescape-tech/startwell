import 'dart:math';
import 'package:startwell/models/wallet_transaction.dart';

class WalletService {
  // Singleton instance
  static final WalletService _instance = WalletService._internal();

  factory WalletService() => _instance;

  WalletService._internal();

  /// Get wallet balance details
  Future<Map<String, double>> getWalletBalance() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for demonstration
      return {
        'totalBalance': 850.0,
        'usableBalance': 350.0,
        'lockedBalance': 500.0,
      };
    } catch (e) {
      // Log error
      print('Error fetching wallet balance: $e');
      throw Exception('Failed to load wallet balance: $e');
    }
  }

  /// Get wallet transaction history
  Future<List<WalletTransaction>> getTransactionHistory() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for demonstration
      return [
        WalletTransaction(
          id: 'txn1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          description: 'Meal Plan Recharge',
          amount: 500.0,
          type: TransactionType.credit,
          paymentMode: 'PhonePe',
          transactedBy: 'Parent',
        ),
        WalletTransaction(
          id: 'txn2',
          date: DateTime.now().subtract(const Duration(days: 2)),
          description: 'Lunch Plan Subscription',
          amount: 340.0,
          type: TransactionType.debit,
          paymentMode: 'Startwell Wallet',
          transactedBy: 'System',
        ),
        WalletTransaction(
          id: 'txn3',
          date: DateTime.now().subtract(const Duration(days: 3)),
          description: 'Wallet Recharge',
          amount: 1000.0,
          type: TransactionType.credit,
          paymentMode: 'Razorpay',
          transactedBy: 'Parent',
        ),
        WalletTransaction(
          id: 'txn4',
          date: DateTime.now().subtract(const Duration(days: 4)),
          description: 'Breakfast Plan Subscription',
          amount: 420.0,
          type: TransactionType.debit,
          paymentMode: 'Startwell Wallet',
          transactedBy: 'System',
        ),
      ];
    } catch (e) {
      // Log error
      print('Error fetching transaction history: $e');
      throw Exception('Failed to load transaction history: $e');
    }
  }

  /// Add money to wallet
  Future<bool> addMoney(double amount, String paymentMethod) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success (success 90% of the time)
      final random = Random();
      final success = random.nextDouble() < 0.9;

      if (!success) {
        throw Exception('Payment failed. Please try again.');
      }

      return true;
    } catch (e) {
      // Log error
      print('Error adding money to wallet: $e');
      throw Exception('Failed to add money to wallet: $e');
    }
  }

  /// Get transaction by ID
  Future<WalletTransaction?> getTransactionById(String transactionId) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      final transactions = await getTransactionHistory();
      try {
        return transactions.firstWhere((txn) => txn.id == transactionId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      // Log error
      print('Error fetching transaction by ID: $e');
      throw Exception('Failed to fetch transaction details: $e');
    }
  }
}
