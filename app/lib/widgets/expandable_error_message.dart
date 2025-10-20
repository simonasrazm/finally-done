import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../generated/app_localizations.dart';

class ExpandableErrorMessage extends StatefulWidget {
  final String errorMessage;
  final Map<String, bool> expandedErrorMessages;

  const ExpandableErrorMessage({
    super.key,
    required this.errorMessage,
    required this.expandedErrorMessages,
  });

  @override
  State<ExpandableErrorMessage> createState() => _ExpandableErrorMessageState();
}

class _ExpandableErrorMessageState extends State<ExpandableErrorMessage> {
  @override
  Widget build(BuildContext context) {
    const int maxLength = 100;
    final bool isLong = widget.errorMessage.length > maxLength;
    final bool isExpanded = widget.expandedErrorMessages[widget.errorMessage] ?? false;
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacing2),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: DesignTokens.iconSm,
                color: AppColors.error,
              ),
              const SizedBox(width: DesignTokens.spacing2),
              Expanded(
                child: Text(
                  isLong && !isExpanded 
                    ? '${widget.errorMessage.substring(0, maxLength)}...'
                    : widget.errorMessage,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (isLong) ...[
            const SizedBox(height: DesignTokens.spacing1),
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.expandedErrorMessages[widget.errorMessage] = !isExpanded;
                });
              },
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: DesignTokens.iconSm,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: DesignTokens.spacing1),
                  Text(
                    isExpanded ? AppLocalizations.of(context)!.showLess : AppLocalizations.of(context)!.showMore,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.error.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
