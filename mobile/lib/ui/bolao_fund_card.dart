import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BolaoFundCard extends StatelessWidget {
  final int participantCount;
  final int amountPerParticipantBrl;
  final int totalAmountBrl;

  const BolaoFundCard({
    super.key,
    required this.participantCount,
    required this.amountPerParticipantBrl,
    required this.totalAmountBrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.92),
            scheme.primaryContainer.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: scheme.onPrimary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arrecadação do bolão',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$participantCount participante${participantCount == 1 ? '' : 's'} × ${currency.format(amountPerParticipantBrl)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Text(
            currency.format(totalAmountBrl),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFFFCD400),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
