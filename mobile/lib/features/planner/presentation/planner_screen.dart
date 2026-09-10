import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/planner_controller.dart';
import '../../../core/domain/entities.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = widget.initialDate ??
        DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(plannerControllerProvider(_date));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _date = picked);
              }
            },
          ),
        ],
      ),
      floatingActionButton: asyncState.maybeWhen(
        data: (s) => FloatingActionButton.extended(
          onPressed: () => _openAddSheet(context, ref, s),
          icon: const Icon(Icons.add),
          label: const Text('Add session'),
        ),
        orElse: () => null,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) {
          final totalHours = s.totalPlannedSeconds / 3600;
          final scheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Planned: ${_fmt(s.totalPlannedSeconds)} '
                  '(${(totalHours).toStringAsFixed(1)}h)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (s.warning != null) ...[
                  const SizedBox(height: 12),
                  _Warning(severity: s.warning!, totalHours: totalHours),
                ],
                const SizedBox(height: 16),
                if (s.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Nothing planned yet.\nUse the button below to add a session.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: s.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = s.items[i];
                        final subject = s.subjects.firstWhere(
                          (sub) => sub.id == item.subjectId,
                          orElse: () => SubjectEntity(
                            id: item.subjectId,
                            userId: '',
                            areaId: '',
                            name: 'Unknown',
                            description: null,
                            color: null,
                            targetHours: 0,
                            status: 'active',
                            priority: 0,
                            deadline: null,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.schedule),
                            title: Text(subject.name),
                            subtitle: Text(
                              '${item.startTime} • ${item.durationSeconds ~/ 60}m',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(plannerControllerProvider(_date).notifier)
                                  .removeItem(i),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    PlannerState s,
  ) async {
    if (s.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a subject first.')),
      );
      return;
    }
    final result = await showModalBottomSheet<({String subjectId, String startTime, int durationMinutes})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddItemSheet(subjects: s.subjects),
    );
    if (result == null) return;
    await ref.read(plannerControllerProvider(_date).notifier).addItem(
          subjectId: result.subjectId,
          startTime: result.startTime,
          durationSeconds: result.durationMinutes * 60,
        );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.severity, required this.totalHours});
  final String severity; // 'yellow' | 'red'
  final double totalHours;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRed = severity == 'red';
    final bg = isRed ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg = isRed ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    final msg = isRed
        ? 'You planned ${totalHours.toStringAsFixed(1)}h today.\n'
            'This may be an unrealistic workload.'
        : 'You planned ${totalHours.toStringAsFixed(1)}h today.\n'
            'Heavy but possible.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg, style: TextStyle(color: fg)),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.subjects});
  final List<SubjectEntity> subjects;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _subjectId = '';
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  int _minutes = 60;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjects.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New plan item', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _subjectId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            items: widget.subjects
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _subjectId = v ?? _subjectId),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    'Start: ${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
                  ),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _start,
                    );
                    if (picked != null) setState(() => _start = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: DropdownButtonFormField<int>(
                  initialValue: _minutes,
                  decoration: const InputDecoration(
                    labelText: 'Min',
                    border: OutlineInputBorder(),
                  ),
                  items: const [25, 30, 45, 60, 90, 120]
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                      .toList(),
                  onChanged: (v) => setState(() => _minutes = v ?? 60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final hh = _start.hour.toString().padLeft(2, '0');
              final mm = _start.minute.toString().padLeft(2, '0');
              Navigator.of(context).pop((
                subjectId: _subjectId,
                startTime: '$hh:$mm',
                durationMinutes: _minutes,
              ));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}