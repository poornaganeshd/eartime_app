import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'ambient_background.dart';

/// Shared layout for the five main tabs: ambient background, safe area, a slim top bar with the
/// settings entry point, and bottom padding that clears the floating navigation.
class TabPage extends StatelessWidget {
  final List<Widget> slivers;
  final VoidCallback? onOpenSettings;
  final Alignment orbA;
  final Alignment orbB;
  final Future<void> Function()? onRefresh;

  const TabPage({
    super.key,
    required this.slivers,
    this.onOpenSettings,
    this.orbA = const Alignment(-1.1, -1.0),
    this.orbB = const Alignment(1.2, 0.6),
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom + 104;
    Widget scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
            child: Row(
              children: [
                Text('EarTime', style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 0.5)),
                const Spacer(),
                if (onOpenSettings != null)
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: onOpenSettings,
                    icon: Icon(Icons.tune_rounded, color: p.textSecondary),
                  ),
              ],
            ),
          ),
        ),
        for (final s in slivers) SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: s),
        SliverToBoxAdapter(child: SizedBox(height: bottom)),
      ],
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, color: p.accent, child: scroll);
    }
    return AmbientBackground(
      primaryAlignment: orbA,
      secondaryAlignment: orbB,
      child: SafeArea(bottom: false, child: scroll),
    );
  }
}

/// Convenience: wraps a box widget as a sliver with vertical spacing below it.
class Gap extends StatelessWidget {
  final Widget child;
  final double after;

  const Gap(this.child, {super.key, this.after = 16});

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: after), child: child);
}
