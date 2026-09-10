import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../areas/application/areas_controller.dart';
import '../../subjects/application/subjects_controller.dart';
import '../application/sessions_controller.dart';

const _presets = [25, 30, 45, 60, 90, 120];

class QuickStartScreen extends ConsumerStatefulWidget {
  const QuickStartScreen({super.key});
  @override
  ConsumerState<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends ConsumerState<QuickStartScreen> {
  String? _subjectId;
  int _minutes = 60;
  bool _custom = false;
  final _topic = TextEditingController();
  final _goal = TextEditingController();
  final _customMinutes = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    _goal.dispose();
    _customMinutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsControllerProvider(null));
    final areasAsync = ref.watch(areasControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Start')),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return _NoSubjects(areas: areasAsync.value ?? const []);
          }
          _subjectId ??= subjects.first.id;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Subject',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
                const SizedBox(height: 20),
                Text('Duration',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._presets.map((m) => ChoiceChip(
                          label: Text('$m min'),
                          selected: !_custom && _minutes == m,
                          onSelected: (_) => setState(() {
                            _custom = false;
                            _minutes = m;
                          }),
                        )),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _custom,
                      onSelected: (_) => setState(() => _custom = true),
                    ),
                  ],
                ),
                if (_custom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customMinutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) _minutes = n;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Text('Topic (optional)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _topic,
                  decoration: const InputDecoration(
                    hintText: 'e.g. useEffect',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Goal (optional)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _goal,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'What do you want to learn?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _subjectId == null ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start session'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _start() async {
    if (_subjectId == null) return;
    await ref.read(sessionsControllerProvider.notifier).start(
          subjectId: _subjectId!,
          plannedDurationSeconds: _minutes * 60,
          topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
          goalText: _goal.text.trim().isEmpty ? null : _goal.text.trim(),
        );
    if (mounted) context.go('/session/active');
  }
}

class _NoSubjects extends StatelessWidget {
  const _NoSubjects({required this.areas});
  final List areas;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, size: 64),
            const SizedBox(height: 16),
            Text(
              'Create a subject first',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'You need at least one subject before starting a session.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}