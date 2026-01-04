import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../utils/category_helper.dart';
import '../main.dart'; // For AppColors

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final amount = transaction.amount;
    final isExpense = transaction.isExpense;

    final categoryColor = CategoryHelper.getColor(transaction.category);
    final backgroundColor = CategoryHelper.getBackgroundColor(
      transaction.category,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Category Icon (No Avatar)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                CategoryHelper.getIcon(transaction.category),
                color: categoryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên ví
                  if (transaction.walletName != null)
                    Text(
                      transaction.walletName!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),

                  // Category Name as Title
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      // Hashtag or Title or Date
                      if (transaction.hashtag != null)
                        Text(
                          transaction.hashtag!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      if (transaction.hashtag != null) const SizedBox(width: 4),
                      if (transaction.title.isNotEmpty)
                        Expanded(
                          child: Text(
                            transaction.title,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if ((transaction.title.isNotEmpty ||
                          transaction.hashtag != null))
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            "•",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(transaction.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount Column
            Text(
              "${isExpense ? '-' : '+'}${currencyFormat.format(amount.abs())}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isExpense ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
