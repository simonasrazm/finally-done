import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../generated/app_localizations.dart';

/// Widget for displaying when not connected to Google
class NotConnectedView extends StatelessWidget {

  const NotConnectedView({
    super.key,
    this.onNavigateToSettings,
  });
  final VoidCallback? onNavigateToSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.sectionSpacing + DesignTokens.spacing2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: DesignTokens.icon4xl,
              color: AppColors.getTextSecondaryColor(context),
            ),
            const SizedBox(height: DesignTokens.sectionSpacing),
            Text(
              AppLocalizations.of(context)!.notConnectedToGoogle,
              style: AppTypography.title3.copyWith(color: AppColors.getTextPrimaryColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              AppLocalizations.of(context)!.connectToGoogleToViewTasks,
              style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: onNavigateToSettings,
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizations.of(context)!.goToSettings),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.componentPadding,
                  vertical: DesignTokens.spacing3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying loading state
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: DesignTokens.componentPadding),
          Text(
            AppLocalizations.of(context)!.loadingTasks,
            style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying error state
class ErrorView extends StatelessWidget {

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.componentPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: DesignTokens.icon4xl,
              color: AppColors.error,
            ),
            const SizedBox(height: DesignTokens.componentPadding),
            Text(
              AppLocalizations.of(context)!.errorLoadingTasks,
              style: AppTypography.title3.copyWith(color: AppColors.getTextPrimaryColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              AppLocalizations.of(context)!.errorLoadingTasksDescription,
              style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying empty state
class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.sectionSpacing + DesignTokens.spacing2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: DesignTokens.icon4xl,
              color: AppColors.getTextSecondaryColor(context),
            ),
            const SizedBox(height: DesignTokens.sectionSpacing),
            Text(
              AppLocalizations.of(context)!.noTasksFound,
              style: AppTypography.title3.copyWith(color: AppColors.getTextPrimaryColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              AppLocalizations.of(context)!.addYourFirstTask,
              style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
