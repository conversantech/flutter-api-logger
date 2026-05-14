import 'package:flutter/material.dart';
import '../models/api_session_model.dart';
import '../services/api_log_service.dart';
import 'api_log_list_screen.dart';

class ApiSessionListScreen extends StatefulWidget {
  const ApiSessionListScreen({super.key});

  @override
  State<ApiSessionListScreen> createState() => _ApiSessionListScreenState();
}

class _ApiSessionListScreenState extends State<ApiSessionListScreen> {
  bool _isEnabled = ApiLogService().isEnabled;

  // Refresh the whole list (e.g. after clear-all or toggle).
  Future<List<ApiSessionModel>> _fetchSessions() =>
      ApiLogService().getSessions();

  void _toggleDebugger(bool value) async {
    if (value) {
      await ApiLogService().enable();
    } else {
      await ApiLogService().disable();
    }
    if (mounted) {
      setState(() {
        _isEnabled = ApiLogService().isEnabled;
      });
    }
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Clear All Data?'),
        content:
            const Text('This will permanently delete all sessions and logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiLogService().clearAll();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isEnabled ? 'Logging active' : 'Logging paused',
                key: ValueKey(_isEnabled),
                style: TextStyle(
                  fontSize: 11,
                  color: _isEnabled
                      ? Colors.green.shade600
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Enable / Disable toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEnabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _isEnabled
                        ? Colors.green.shade600
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: _toggleDebugger,
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          // Clear all
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: FutureBuilder<List<ApiSessionModel>>(
        future: _fetchSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions recorded yet',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isCurrent = session.id == ApiLogService().currentSessionId;
              return _SessionCard(
                session: session,
                isCurrent: isCurrent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApiLogListScreen(
                        sessionId: session.id,
                        sessionName: session.name,
                      ),
                    ),
                  ).then((_) {
                    // Update UI if name has changed or session was deleted
                    if (mounted) setState(() {});
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session Card
// ─────────────────────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final ApiSessionModel session;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dt = session.startTime.toLocal();

    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isCurrent
                ? colorScheme.primaryContainer.withOpacity(0.45)
                : colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? colorScheme.primary.withOpacity(0.55)
                  : colorScheme.outlineVariant.withOpacity(0.5),
              width: isCurrent ? 1.5 : 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Left: Pulsing green dot for active session, grey for others
              _StatusDot(isActive: isCurrent),
              const SizedBox(width: 12),

              // Middle: Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Name & Edit Icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Date + Time row
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time_outlined,
                            size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: API count badge
              FutureBuilder<int>(
                future: ApiLogService().getLogCountForSession(session.id),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return _ApiCountBadge(count: count, isCurrent: isCurrent);
                },
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated pulsing dot for active session
// ─────────────────────────────────────────────────────────────────────────────

class _StatusDot extends StatefulWidget {
  final bool isActive;
  const _StatusDot({required this.isActive});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
      );
    }

    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green,
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API Count Badge
// ─────────────────────────────────────────────────────────────────────────────

class _ApiCountBadge extends StatelessWidget {
  final int count;
  final bool isCurrent;
  const _ApiCountBadge({required this.count, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.primary.withOpacity(0.12)
            : colorScheme.outlineVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary.withOpacity(0.4)
              : colorScheme.outlineVariant.withOpacity(0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.api_outlined,
            size: 11,
            color:
                isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCurrent
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
