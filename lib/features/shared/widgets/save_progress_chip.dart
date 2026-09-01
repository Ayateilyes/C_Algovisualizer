import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_theme.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';

/// Top-right chip shown on every screen.
/// - Anonymous: shows "Save Progress" with a cloud-upload icon
/// - Linking in progress: shows a small circular loader
/// - Linked to Google: shows the user's avatar + name with a checkmark
///
/// Tapping triggers Google linkWithCredential() — never a navigation push.
class SaveProgressChip extends ConsumerWidget {
  const SaveProgressChip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Show error snackbar if link failed
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return switch (authState.status) {
      AuthStatus.linking => _buildLinkingChip(cs),
      AuthStatus.linked => _buildLinkedChip(authState, cs),
      AuthStatus.anonymous => _buildAnonymousChip(context, ref, cs),
    };
  }

  // ── Anonymous state ─────────────────────────────────────────────────────────

  Widget _buildAnonymousChip(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    return _ChipBase(
      onTap: () => ref.read(authNotifierProvider.notifier).linkWithGoogle(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 16, color: cs.primary),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              'Save Progress',
              style: AppTextStyles.labelMedium.copyWith(color: cs.primary),
            ),
          ],
        ],
      ),
    );
  }

  // ── Linking in progress ─────────────────────────────────────────────────────

  Widget _buildLinkingChip(ColorScheme cs) {
    return _ChipBase(
      onTap: null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(
              'Signing in...',
              style: AppTextStyles.labelMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Linked to Google ────────────────────────────────────────────────────────

  Widget _buildLinkedChip(AuthState auth, ColorScheme cs) {
    return _ChipBase(
      onTap: null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar or fallback icon
          _Avatar(photoUrl: auth.photoUrl),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              auth.displayName ?? auth.email ?? 'Linked',
              style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
        ],
      ),
    );
  }
}

// ─── Shared chip shell ────────────────────────────────────────────────────────

class _ChipBase extends StatelessWidget {
  const _ChipBase({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppDurations.normal,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        borderRadius: AppRadius.fullAll,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.fullAll,
        child: InkWell(
          borderRadius: AppRadius.fullAll,
          onTap: onTap,
          splashColor: cs.primary.withAlpha(30),
          highlightColor: cs.primary.withAlpha(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Avatar widget ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return CircleAvatar(radius: 9, backgroundImage: NetworkImage(photoUrl!));
    }
    return CircleAvatar(
      radius: 9,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.person, size: 11, color: Colors.white),
    );
  }
}
