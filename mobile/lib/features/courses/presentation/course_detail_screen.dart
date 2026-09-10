import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/courses.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/courses_controller.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({
    super.key,
    required this.subjectId,
    required this.courseId,
  });
  final String subjectId;
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/subjects/$subjectId'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add module',
            onPressed: () => _openModuleEditor(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete course',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (course) {
          final pct = course.percentLessonsComplete;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (course.description != null &&
                          course.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(course.description!,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: pct.clamp(0, 1),
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}% complete'
                        ' • ${course.completedLessons}/${course.totalLessons} lessons',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Modules',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (course.modules.isEmpty)
                const EmptyState(
                  icon: Icons.view_module_outlined,
                  title: 'No modules yet',
                  message: 'Modules group related lessons.',
                )
              else
                for (final m in course.modules)
                  _ModuleSection(
                    subjectId: subjectId,
                    courseId: courseId,
                    module: m,
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openModuleEditor(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String name, String? description})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ModuleEditor(),
    );
    if (result == null) return;
    await ref.read(lessonsControllerProvider(courseId).notifier).addModule(
          courseId: courseId,
          name: result.name,
          description: result.description,
        );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete course?'),
        content: const Text(
            'All modules and lessons in this course will be deleted too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(coursesControllerProvider(subjectId).notifier).delete(courseId);
    if (context.mounted) context.go('/subjects/$subjectId');
  }
}

class _ModuleSection extends ConsumerWidget {
  const _ModuleSection({
    required this.subjectId,
    required this.courseId,
    required this.module,
  });
  final String subjectId;
  final String courseId;
  final ModuleEntity module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final done = module.lessons.where((l) => l.isCompleted).length;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(module.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add lesson',
                  onPressed: () => _addLesson(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete module',
                  onPressed: () async {
                    await ref
                        .read(lessonsControllerProvider(courseId).notifier)
                        .deleteModule(courseId: courseId, moduleId: module.id);
                  },
                ),
              ],
            ),
            if (module.description != null && module.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(module.description!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                module.lessons.isEmpty
                    ? 'No lessons yet'
                    : '$done/${module.lessons.length} lessons complete',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
            for (final lesson in module.lessons)
              _LessonTile(
                subjectId: subjectId,
                courseId: courseId,
                moduleId: module.id,
                lesson: lesson,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addLesson(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String name, String? description})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LessonEditor(),
    );
    if (result == null) return;
    await ref.read(lessonsControllerProvider(courseId).notifier).addLesson(
          courseId: courseId,
          moduleId: module.id,
          name: result.name,
          description: result.description,
        );
  }
}

class _LessonTile extends ConsumerWidget {
  const _LessonTile({
    required this.subjectId,
    required this.courseId,
    required this.moduleId,
    required this.lesson,
  });
  final String subjectId;
  final String courseId;
  final String moduleId;
  final LessonEntity lesson;

  Color _statusColor(LessonStatus s, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (s) {
      LessonStatus.completed => scheme.primary,
      LessonStatus.inProgress => scheme.tertiary,
      LessonStatus.notStarted => scheme.outline,
    };
  }

  IconData _statusIcon(LessonStatus s) {
    return switch (s) {
      LessonStatus.completed => Icons.check_circle,
      LessonStatus.inProgress => Icons.play_circle_outline,
      LessonStatus.notStarted => Icons.circle_outlined,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _pickStatus(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(_statusIcon(lesson.status),
                size: 18, color: _statusColor(lesson.status, context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lesson.name,
                style: TextStyle(
                  decoration: lesson.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: lesson.isCompleted
                      ? scheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(_statusLabel(lesson.status)),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(LessonStatus s) {
    return switch (s) {
      LessonStatus.completed => 'Done',
      LessonStatus.inProgress => 'In progress',
      LessonStatus.notStarted => 'Not started',
    };
  }

  Future<void> _pickStatus(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<LessonStatus>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in LessonStatus.values)
              ListTile(
                leading: Icon(_statusIcon(s)),
                title: Text(_statusLabel(s)),
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == lesson.status) return;
    await ref.read(lessonsControllerProvider(courseId).notifier).setStatus(
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lesson.id,
          status: picked,
        );
  }
}

class _ModuleEditor extends StatefulWidget {
  const _ModuleEditor();
  @override
  State<_ModuleEditor> createState() => _ModuleEditorState();
}

class _ModuleEditorState extends State<_ModuleEditor> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
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
          Text('New module', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              Navigator.of(context).pop((
                name: _name.text.trim(),
                description: _description.text.trim().isEmpty
                    ? null
                    : _description.text.trim(),
              ));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _LessonEditor extends StatefulWidget {
  const _LessonEditor();
  @override
  State<_LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends State<_LessonEditor> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
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
          Text('New lesson', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              Navigator.of(context).pop((
                name: _name.text.trim(),
                description: _description.text.trim().isEmpty
                    ? null
                    : _description.text.trim(),
              ));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}