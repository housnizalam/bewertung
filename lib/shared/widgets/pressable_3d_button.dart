import 'package:flutter/material.dart';

class Pressable3DButton extends StatefulWidget {
  const Pressable3DButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.showProofBadge = true,
    this.width,
    this.height = 52,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showProofBadge;
  final double? width;
  final double height;

  @override
  State<Pressable3DButton> createState() => _Pressable3DButtonState();
}

class _Pressable3DButtonState extends State<Pressable3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null;
    final bg = widget.backgroundColor ?? theme.colorScheme.primary;
    final fg = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    final depth = enabled ? (_pressed ? 0.0 : 4.0) : 0.0;
    final topOffset = enabled ? (_pressed ? 4.0 : 0.0) : 0.0;
    final topHighlight = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.16),
      bg,
    );
    final bottomLayerColor = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.28),
      bg,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: SizedBox(
          width: widget.width,
          height: widget.height + 4,
          child: Padding(
            // Reserve visual space for the raised bottom layer.
            padding: const EdgeInsets.only(bottom: 4),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              scale: _pressed ? 0.97 : 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: bottomLayerColor,
                        borderRadius: widget.borderRadius,
                        boxShadow: enabled
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: _pressed ? 0.08 : 0.22,
                                  ),
                                  blurRadius: _pressed ? 2 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : const <BoxShadow>[],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(0, topOffset, 0),
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [topHighlight, bg],
                      ),
                      boxShadow: enabled
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: _pressed ? 0.06 : 0.12,
                                ),
                                blurRadius: _pressed ? 1 : 5,
                                offset: Offset(0, _pressed ? 1 : depth),
                              ),
                            ]
                          : const <BoxShadow>[],
                    ),
                    child: SizedBox(
                      height: widget.height,
                      child: Padding(
                        padding: widget.padding,
                        child: IconTheme(
                          data: IconThemeData(color: fg),
                          child: DefaultTextStyle(
                            style: theme.textTheme.titleMedium!.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w700,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Center(child: widget.child),
                                if (widget.showProofBadge)
                                  Positioned(
                                    right: 0,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: fg.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '3D',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: fg,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
