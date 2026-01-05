import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import '../utils/category_helper.dart';
import '../main.dart'; // For AppColors

class TransactionDetailModal extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailModal({super.key, required this.transaction});

  static void show(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailModal(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final isExpense = transaction.isExpense;
    final categoryColor = CategoryHelper.getColor(transaction.category);
    final backgroundColor = CategoryHelper.getBackgroundColor(
      transaction.category,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  CategoryHelper.getIcon(transaction.category),
                  color: categoryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),

          const Divider(height: 32),

          // Transaction Info
          _buildDetailRow(
            'Loại giao dịch',
            isExpense ? 'Chi tiêu' : 'Thu nhập',
          ),
          _buildDetailRow('Danh mục', transaction.category),
          _buildDetailRow(
            'Số tiền',
            "${isExpense ? '-' : '+'}${currencyFormat.format(transaction.amount.abs())}",
            valueColor: isExpense ? AppColors.danger : AppColors.success,
          ),
          if (transaction.title.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Ghi chú',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            Text(
              transaction.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (transaction.walletName != null)
            _buildDetailRow('Ví', transaction.walletName!),

          // Proof Image
          if (transaction.proofImage != null &&
              transaction.proofImage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Hình ảnh minh chứng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                transaction.proofImage!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(
                      LucideIcons.imageOff,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
