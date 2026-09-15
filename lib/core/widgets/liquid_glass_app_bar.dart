import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, Colors;
import '../theme/app_colors.dart';

typedef LGAppBar = LiquidGlassAppBar;

class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final String? subtitleText;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final double height;
  final Widget? bottom;
  final double bottomHeight;
  final bool isLargeTitle;
  final Color? accentColor;

  const LiquidGlassAppBar({
    super.key,
    this.title,
    this.titleText,
    this.subtitleText,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.height = 54.0,
    this.bottom,
    this.bottomHeight = 0,
    this.isLargeTitle = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.accentPurple;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && automaticallyImplyLeading && canPop) {
      effectiveLeading = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.maybePop(context),
        child: Icon(CupertinoIcons.back, color: accent, size: 24),
      );
    }

    Widget effectiveTitle;
    if (title != null) {
      effectiveTitle = title!;
    } else if (isLargeTitle) {
      effectiveTitle = Text(
        titleText ?? '',
        style: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: AppColors.textPrimary(isDark),
        ),
      );
    } else {
      effectiveTitle = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            titleText ?? '',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          if (subtitleText != null && subtitleText!.isNotEmpty)
            Text(
              subtitleText!,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                color: AppColors.textSecondary(isDark),
              ),
            ),
        ],
      );
    }

    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      color: Colors.transparent,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xCC121214)
                  : const Color(0xCCFBFBFE),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        if (effectiveLeading != null)
                          SizedBox(width: 44, child: effectiveLeading)
                        else
                          const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: isLargeTitle
                                ? Alignment.centerLeft
                                : Alignment.center,
                            child: effectiveTitle,
                          ),
                        ),
                        if (actions != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          )
                        else
                          const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
                if (bottom != null)
                  SizedBox(
                    height: bottomHeight,
                    child: bottom,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + bottomHeight);
}



