import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/time/time_source.dart';
import '../application/sessions_controller.dart';
import '../domain/session_timer.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState
    extends ConsumerState<SessionSummaryScreen> {
  String? _goalResult;
  int _focus = 3;
  int _energy = 3;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionsControllerProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Session not found.')),
      );
    }
    final elapsed = session.elapsedSecondsAt(DateTime.now().toUtc());

    return Scaffold(
      appBar: AppBar(title: const Text('Session complete')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Planned vs Actual',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Planned: ${_fmt(session.plannedDurationSeconds)}'),
                        Text('Actual:  ${_fmt(elapsed)}'),
                        if (session.goalText != null) ...[
                          const SizedBox(height: 12),
                          Text('Goal: ${session.goalText}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Did you complete your goal?',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'yes', label: Text('Yes')),
                    ButtonSegment(value: 'partially', label: Text('Partially')),
                    ButtonSegment(value: 'no', label: Text('No')),
                  ],
                  selected: _goalResult == null ? {} : {_goalResult!},
                  onSelectionChanged: (s) =>
                      setState(() => _goalResult = s.first),
                ),
                const SizedBox(height: 20),
                _RatingRow(
                  label: 'Focus',
                  value: _focus,
                  onChanged: (v) => setState(() => _focus = v),
                ),
                const SizedBox(height: 12),
                _RatingRow(
                  label: 'Energy',
                  value: _energy,
                  onChanged: (v) => setState(() => _energy = v),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _save(context, ref, elapsed),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _save(BuildContext context, WidgetRef ref, int elapsed) async {
    final ctrl = ref.read(sessionsControllerProvider.notifier);
    final s = ctrl.state;
    if (s == null) return;
    await ref.read(sessionsDaoProvider).complete(
          s.sessionId,
          endedAt: s.endedAt ?? DateTime.now().toUtc(),
          actualDurationSeconds: elapsed,
          pausedIntervalsSeconds: s.pausedIntervalsSeconds,
          goalResult: _goalResult,
          focusRating: _focus,
          energyRating: _energy,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (context.mounted) context.go('/dashboard');
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        for (var i = 1; i <= 5; i++)
          IconButton(
            icon: Icon(
              i <= value ? Icons.circle : Icons.circle_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => onChanged(i),
          ),
      ],
    );
  }
}