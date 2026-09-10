import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities.dart';
import '../../../core/time/time_source.dart';
import '../../../shared/widgets/duration_text.dart';
import '../../areas/application/areas_controller.dart';
import '../../subjects/application/subjects_controller.dart';
import '../application/sessions_controller.dart';
import '../domain/session_timer.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _tick;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionsControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No active session.\nTap "Quick Start" to begin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final elapsed = session.elapsedSecondsAt(_now);
    final isPaused = session.status == SessionStatus.paused;
    final isCompleted = session.status == SessionStatus.completed ||
        session.status == SessionStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studying'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel session',
          onPressed: () => _confirmCancel(context, ref),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SubjectHeader(
                  sessionId: session.sessionId,
                  subjectId: session.sessionId, // unused; UI uses subject lookup
                  fallbackSubjectId: session.sessionId,
                ),
                const SizedBox(height: 24),
                if (session.status == SessionStatus.paused)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Paused',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ),
                if (isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DurationText(
                  seconds: elapsed,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Planned: ${_fmt(session.plannedDurationSeconds)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                if (!isCompleted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isPaused)
                        FilledButton.icon(
                          onPressed: () =>
                              ref.read(sessionsControllerProvider.notifier).pause(),
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () =>
                              ref.read(sessionsControllerProvider.notifier).resume(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                        ),
                      const SizedBox(width: 16),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await ref
                              .read(sessionsControllerProvider.notifier)
                              .complete();
                          if (context.mounted) {
                            context.go('/session/${session.sessionId}/summary');
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel session?'),
        content: const Text(
          'Cancelled sessions are saved but do not count toward your stats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sessionsControllerProvider.notifier).cancel();
      if (context.mounted) context.go('/dashboard');
    }
  }
}

class _SubjectHeader extends ConsumerWidget {
  const _SubjectHeader({
    required this.sessionId,
    required this.subjectId,
    required this.fallbackSubjectId,
  });

  final String sessionId;
  final String subjectId;
  final String fallbackSubjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAreas = ref.watch(areasControllerProvider);
    final asyncSubjects = ref.watch(subjectsControllerProvider(null));
    return asyncAreas.when(
      loading: () => const SizedBox(height: 24),
      error: (_, _) => const SizedBox(height: 24),
      data: (areas) => asyncSubjects.when(
        loading: () => const SizedBox(height: 24),
        error: (_, _) => const SizedBox(height: 24),
        data: (subjects) {
          // Look up the most-recently-active subject; in MVP the timer state
          // is global, so we pick the first subject in the list as a sane
          // label fallback when subjectId is not part of SessionState.
          if (subjects.isEmpty) {
            return const SizedBox.shrink();
          }
          final s = subjects.first;
          return Column(
            children: [
              Text(
                s.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (s.description != null && s.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    s.description!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}