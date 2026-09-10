import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/areas_controller.dart';
import '../../../core/domain/entities.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/empty_state.dart';

class AreasScreen extends ConsumerWidget {
  const AreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAreas = ref.watch(areasControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Areas'),
        leading: IconButton(
          icon: const Icon(Icons.dashboard_outlined),
          tooltip: 'Dashboard',
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New area'),
      ),
      body: asyncAreas.when(
        data: (areas) {
          if (areas.isEmpty) {
            return EmptyState(
              icon: Icons.folder_outlined,
              title: 'No areas yet',
              message:
                  'Create your first area — like Frontend, Backend, or DevOps.',
              actionLabel: 'New area',
              onAction: () => _openEditor(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(areasControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: areas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AreaTile(area: areas[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load areas: $e'),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {AreaEntity? area}) async {
    final result = await showModalBottomSheet<({String name, String color, String? icon})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AreaEditor(initial: area),
    );
    if (result == null) return;
    final ctrl = ref.read(areasControllerProvider.notifier);
    if (area == null) {
      await ctrl.create(name: result.name, color: result.color, icon: result.icon);
    } else {
      await ctrl.edit(area.id,
          name: result.name, color: result.color, icon: result.icon);
    }
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({required this.area});
  final AreaEntity area;

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _parseColor(area.color)),
        title: Text(area.name),
        subtitle: Text(area.archivedAt != null ? 'Archived' : 'Active'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/areas/${area.id}'),
      ),
    );
  }
}

class _AreaEditor extends StatefulWidget {
  const _AreaEditor({this.initial});
  final AreaEntity? initial;

  @override
  State<_AreaEditor> createState() => _AreaEditorState();
}

class _AreaEditorState extends State<_AreaEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late String _color = widget.initial?.color ?? '#5B8DEF';

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
          Text(
            widget.initial == null ? 'New area' : 'Edit area',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          ColorPickerField(
            value: _color,
            options: _palette,
            onChanged: (v) => setState(() => _color = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              Navigator.of(context).pop((
                name: _name.text.trim(),
                color: _color,
                icon: null,
              ));
            },
            child: Text(widget.initial == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }
}