import 'package:flutter/material.dart';

/// A single pulsing placeholder box, used as a building block for
/// skeleton list items shown while a screen's first page of data loads.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFe2e8f0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.5 + _ctrl.value * 0.4),
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// A column of card-shaped skeleton placeholders mimicking a typical
/// list-tile layout (icon/accent + two lines of text), shown instead of
/// a bare spinner while a list screen's first page loads.
class SkeletonListPlaceholder extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonListPlaceholder({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 78,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: itemHeight,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: Row(children: [
          SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.circular(10)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SkeletonBox(height: 14, width: 160),
              const SizedBox(height: 8),
              SkeletonBox(height: 11, width: itemHeight),
            ]),
          ),
        ]),
      ),
    );
  }
}
