import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities.dart';
import '../../../core/domain/courses.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../courses/application/courses_controller.dart';
import '../../subjects/application/subjects_controller.dart';

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsControllerProvider(null));
    final coursesAsync = ref.watch(coursesControllerProvider(subjectId));
    final progressAsync = ref.watch(subjectProgressProvider(subjectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCourseEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New course'),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (subjects) {
          final subject = subjects.where((s) => s.id == subjectId).firstOrNull;
          if (subject == null) {
            return const Center(child: Text('Subject not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(subject: subject, progressAsync: progressAsync),
              const SizedBox(height: 16),
              Text('Courses',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No courses yet',
                      message:
                          'Organize this subject into a course with modules and lessons.',
                    );
                  }
                  return Column(
                    children: [
                      for (final c in courses) _CourseTile(course: c),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text('$e'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCourseEditor(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String name, String? description})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CourseEditor(),
    );
    if (result == null) return;
    await ref.read(coursesControllerProvider(subjectId).notifier).create(
          name: result.name,
          description: result.description,
        );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subject, required this.progressAsync});
  final SubjectEntity subject;
  final AsyncValue<SubjectProgressEntity> progressAsync;

  Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF94A3B8);
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(subject.color);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.3),
                  child: Icon(Icons.book_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (subject.description != null &&
                          subject.description!.isNotEmpty)
                        Text(subject.description!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            progressAsync.when(
              data: (p) {
                final pct = p.percentComplete;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: pct.clamp(0, 1),
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}% complete'
                      ' • ${p.completedLessons}/${p.totalLessons} lessons'
                      ' • ${p.completedHours.toStringAsFixed(1)}h of '
                      '${p.targetHours.toStringAsFixed(0)}h target',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 4,
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTile extends ConsumerWidget {
  const _CourseTile({required this.course});
  final CourseEntity course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = course.percentLessonsComplete;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.menu_book),
        title: Text(course.name),
        subtitle: Text(
          course.totalLessons == 0
              ? 'No lessons yet'
              : '${course.completedLessons}/${course.totalLessons} lessons complete'
                  ' • ${(pct * 100).toStringAsFixed(0)}%',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/subjects/${course.subjectId}/courses/${course.id}'),
      ),
    );
  }
}

class _CourseEditor extends StatefulWidget {
  const _CourseEditor();
  @override
  State<_CourseEditor> createState() => _CourseEditorState();
}

class _CourseEditorState extends State<_CourseEditor> {
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
          Text('New course', style: Theme.of(context).textTheme.titleLarge),
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

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}