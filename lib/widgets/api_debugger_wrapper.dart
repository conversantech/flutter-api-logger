import 'package:flutter/material.dart';
import '../services/api_log_service.dart';
import '../flutter_api_tracker.dart';

class ApiDebuggerWrapper extends StatefulWidget {
  final Widget child;

  /// What happens when the 6-tap gesture is triggered.
  /// If null, it defaults to enabling (if needed) and opening the debugger.
  final void Function(BuildContext context)? onTrigger;

  /// Number of taps required to trigger the action. Defaults to 6.
  final int tapCount;

  const ApiDebuggerWrapper({
    super.key,
    required this.child,
    this.onTrigger,
    this.tapCount = 6,
  });

  @override
  State<ApiDebuggerWrapper> createState() => _ApiDebuggerWrapperState();
}

class _ApiDebuggerWrapperState extends State<ApiDebuggerWrapper> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount >= widget.tapCount) {
      _tapCount = 0;
      if (widget.onTrigger != null) {
        widget.onTrigger!(context);
      } else {
        _defaultAction();
      }
    }
  }

  Future<void> _defaultAction() async {
    if (!ApiLogService().isEnabled) {
      await _enableWithNotification();
    }
    if (!mounted) return;
    ApiDebugger.open(context);
  }

  Future<void> _enableWithNotification() async {
    await ApiLogService().enable();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚡ API Debugger Enabled'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
