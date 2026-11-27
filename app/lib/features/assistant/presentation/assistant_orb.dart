import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated visual identity for AETHERA's assistant. It is deliberately a UI
/// component only; it does not imply that an AI model is connected.
class AssistantOrb extends StatefulWidget {
  final double size;
  const AssistantOrb({super.key, this.size = 154});

  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value * math.pi * 2;
        final pulse = 1 + (math.sin(phase) * .035);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.scale(
            scale: pulse,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * .94,
                  height: widget.size * .94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF91CBB0).withValues(alpha: .25)),
                  ),
                ),
                Transform.rotate(
                  angle: phase,
                  child: Container(
                    width: widget.size * .78,
                    height: widget.size * .78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          const Color(0xFFB7E8C8).withValues(alpha: .08),
                          const Color(0xFF5CC6A0).withValues(alpha: .65),
                          const Color(0xFF72C6D4).withValues(alpha: .18),
                          const Color(0xFFB7E8C8).withValues(alpha: .08),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: widget.size * .63,
                  height: widget.size * .63,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-.35 + math.sin(phase) * .12, -.4),
                      colors: const [
                        Color(0xFFE0FFF0),
                        Color(0xFF83D7B0),
                        Color(0xFF278A69),
                        Color(0xFF123F35),
                      ],
                      stops: const [0, .22, .62, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF68CBA5).withValues(alpha: .38),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: widget.size * .2,
                  height: widget.size * .2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .78),
                    boxShadow: [
                      BoxShadow(color: Colors.white.withValues(alpha: .65), blurRadius: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
