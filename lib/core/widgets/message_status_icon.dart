import 'package:flutter/material.dart';

/// Traffic Signal Message Status Indicator:
/// - 🔴 **Red Light**: Not Send (pending, failed, unsent)
/// - 🟡 **Yellow Light**: Send (sent to server / delivered to recipient)
/// - 🟢 **Green Light**: Seen (read / viewed by recipient)
class MessageStatusIcon extends StatelessWidget {
  final String status;
  final double? dotSize;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.dotSize,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();
    final bool isSeen = s == 'seen' || s == 'read';
    final bool isSend = !isSeen && (s == 'send' || s == 'sent' || s == 'delivered');
    final bool isNotSend = !isSeen && !isSend; // pending, failed, not send, error, etc.

    final String tooltip = isSeen
        ? 'Seen (Traffic Signal: Green)'
        : (isSend
            ? 'Sent (Traffic Signal: Yellow)'
            : 'Not sent (Traffic Signal: Red)');

    final double dSize = dotSize ?? 6.0;

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔴 RED LIGHT: Not Send
            _SignalLight(
              color: const Color(0xFFFF3B30),
              isActive: isNotSend,
              size: dSize,
            ),
            const SizedBox(width: 3.0),
            // 🟡 YELLOW LIGHT: Send
            _SignalLight(
              color: const Color(0xFFFFCC00),
              isActive: isSend,
              size: dSize,
            ),
            const SizedBox(width: 3.0),
            // 🟢 GREEN LIGHT: Seen
            _SignalLight(
              color: const Color(0xFF34C759),
              isActive: isSeen,
              size: dSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalLight extends StatelessWidget {
  final Color color;
  final bool isActive;
  final double size;

  const _SignalLight({
    required this.color,
    required this.isActive,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? color : color.withValues(alpha: 0.22),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.85),
                  blurRadius: 4.5,
                  spreadRadius: 1.0,
                ),
              ]
            : null,
      ),
    );
  }
}


