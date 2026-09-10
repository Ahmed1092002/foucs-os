import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities.dart';
import '../../../core/di/providers.dart';
import '../../areas/application/areas_controller.dart';
import '../../subjects/application/subjects_controller.dart';
import '../../../shared/widgets/color_picker_field.dart';

class SubjectListScreen extends ConsumerWidget {
  const SubjectListScreen({super.key, required this.areaId});
  final String areaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasControllerProvider);
    final subjectsAsync = ref.watch(subjectsControllerProvider(areaId));

    return areasAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (areas) {
        final area = areas.where((a) => a.id == areaId).firstOrNull;
        if (area == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Area not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(area.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/areas'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Archive area',
                onPressed: () async {
                  final ok = await _confirm(context,
                      'Archive this area? Subjects stay visible in history.');
                  if (!ok) return;
                  await ref.read(areasControllerProvider.notifier).delete(area.id);
                  if (context.mounted) context.go('/areas');
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openSubjectEditor(context, ref, area),
            icon: const Icon(Icons.add),
            label: const Text('New subject'),
          ),
          body: subjectsAsync.when(
            data: (subjects) {
              if (subjects.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No subjects yet.\nAdd one to start tracking study time.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _SubjectTile(subject: subjects[i]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        );
      },
    );
  }

  Future<void> _openSubjectEditor(BuildContext context, WidgetRef ref, AreaEntity area) async {
    final result = await showModalBottomSheet<({String name, double targetHours, int priority, String? color})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SubjectEditor(),
    );
    if (result == null) return;
    await ref.read(subjectsControllerProvider(area.id).notifier).create(
          areaId: area.id,
          name: result.name,
          targetHours: result.targetHours,
          priority: result.priority,
          color: result.color,
        );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject});
  final SubjectEntity subject;

  Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF94A3B8);
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(subject.color).withValues(alpha: 0.3),
          child: Icon(Icons.book_outlined, color: _parseColor(subject.color)),
        ),
        title: Text(subject.name),
        subtitle: Text('Target: ${subject.targetHours.toStringAsFixed(0)}h'),
        trailing: subject.priority > 0
            ? Chip(label: Text('P${subject.priority}'))
            : const Icon(Icons.chevron_right),
        onTap: () => context.go('/subjects/${subject.id}'),
      ),
    );
  }
}

class _SubjectEditor extends StatefulWidget {
  const _SubjectEditor();

  @override
  State<_SubjectEditor> createState() => _SubjectEditorState();
}

class _SubjectEditorState extends State<_SubjectEditor> {
  final _name = TextEditingController();
  final _hours = TextEditingController(text: '10');
  int _priority = 0;
  String _color = '#22C55E';

  static const _palette = [
    '#5B8DEF',
    '#22C55E',
    '#F59E0B',
    '#EF4444',
    '#A855F7',
    '#06B6D4',
    '#EC4899',
  ];

  @override
  void dispose() {
    _name.dispose();
    _hours.dispose();
    super.dispose();
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
          Text('New subject', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target hours',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('None')),
              DropdownMenuItem(value: 1, child: Text('Low')),
              DropdownMenuItem(value: 2, child: Text('Medium')),
              DropdownMenuItem(value: 3, child: Text('High')),
            ],
            onChanged: (v) => setState(() => _priority = v ?? 0),
          ),
          const SizedBox(height: 12),
          ColorPickerField(
            value: _color,
            options: _palette,
            onChanged: (v) => setState(() => _color = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              final hours = double.tryParse(_hours.text) ?? 0;
              Navigator.of(context).pop((
                name: _name.text.trim(),
                targetHours: hours,
                priority: _priority,
                color: _color,
              ));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Future<bool> _confirm(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
      ],
    ),
  );
  return ok ?? false;
}