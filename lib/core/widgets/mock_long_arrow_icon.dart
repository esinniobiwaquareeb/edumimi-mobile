import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MockLongArrowDirection { left, right }

/// Long-tail navigation arrow (<---- / ---->) used across the mobile app.
class MockLongArrowIcon extends StatelessWidget {
  const MockLongArrowIcon({
    super.key,
    required this.direction,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  final MockLongArrowDirection direction;
  final double size;
  final Color? color;
  final String? semanticLabel;

  static const _leftAsset = 'assets/icons/arrow-long-left.svg';
  static const _rightAsset = 'assets/icons/arrow-long-right.svg';

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? IconTheme.of(context).color ?? Theme.of(context).iconTheme.color!;
    final asset = direction == MockLongArrowDirection.left ? _leftAsset : _rightAsset;

    return Semantics(
      label: semanticLabel,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      ),
    );
  }
}
