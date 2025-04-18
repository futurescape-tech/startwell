import 'package:intl/intl.dart';

class WalletTransaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final TransactionType type;
  final String paymentMode;
  final String transactedBy;

  WalletTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.paymentMode,
    required this.transactedBy,
  });

  /// Convert the transaction to a map for UI display
  Map<String, String> toDisplayMap() {
    final DateFormat dateFormat = DateFormat('EEE, dd MMM yyyy');
    final NumberFormat amountFormat = NumberFormat("#,##0.00", "en_IN");

    return {
      "date": dateFormat.format(date),
      "description": description,
      "amount": "₹${amountFormat.format(amount)}",
      "type": type == TransactionType.credit ? "Credit" : "Debit",
      "paymentMode": paymentMode,
      "transactedBy": transactedBy,
    };
  }

  /// Create a transaction from a map (e.g., from API)
  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] ?? '',
      date: map['date'] is DateTime
          ? map['date']
          : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      description: map['description'] ?? '',
      amount: (map['amount'] is num)
          ? map['amount'].toDouble()
          : double.tryParse(map['amount'] ?? '0') ?? 0.0,
      type: (map['type'] == 'Credit' ||
              map['type'] == 'credit' ||
              map['is_credit'] == true)
          ? TransactionType.credit
          : TransactionType.debit,
      paymentMode: map['payment_mode'] ?? map['paymentMode'] ?? '',
      transactedBy: map['transacted_by'] ?? map['transactedBy'] ?? '',
    );
  }

  /// Convert to a map for API storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'type': type == TransactionType.credit ? 'Credit' : 'Debit',
      'payment_mode': paymentMode,
      'transacted_by': transactedBy,
    };
  }
}

enum TransactionType {
  credit,
  debit,
}
