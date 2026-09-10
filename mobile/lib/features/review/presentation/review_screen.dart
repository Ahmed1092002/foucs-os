import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/daily_review.dart';

/// Today (date-only) in the device's local timezone.
DateTime _todayLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, this.date});
  final DateTime? date;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late DateTime _date;
  int _productivity = 3;
  int _energy = 3;
  int _focus = 3;
  final _wentWell = TextEditingController();
  final _blockedBy = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  bool _exists = false;

  @override
  void initState() {
    super.initState();
    _date = widget.date ?? _todayLocal();
    _load();
  }

  @override
  void dispose() {
    _wentWell.dispose();
    _blockedBy.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(dailyReviewsRepositoryProvider);
    final existing = await repo.getForDate(_date);
    if (existing != null && mounted) {
      setState(() {
        _productivity = existing.productivityRating ?? 3;
        _energy = existing.energyRating ?? 3;
        _focus = existing.focusRating ?? 3;
        _wentWell.text = existing.wentWell ?? '';
        _blockedBy.text = existing.blockedBy ?? '';
        _exists = true;
        _loaded = true;
      });
    } else if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(dailyReviewsRepositoryProvider).upsert(
            _date,
            productivityRating: _productivity,
            energyRating: _energy,
            focusRating: _focus,
            wentWell: _wentWell.text.trim().isEmpty ? null : _wentWell.text.trim(),
            blockedBy: _blockedBy.text.trim().isEmpty ? null : _blockedBy.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review saved.')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_exists ? 'Edit review' : 'Daily review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _RatingRow(
                  label: 'Productivity',
                  value: _productivity,
                  onChanged: (v) => setState(() => _productivity = v),
                ),
                const SizedBox(height: 8),
                _RatingRow(
                  label: 'Energy',
                  value: _energy,
                  onChanged: (v) => setState(() => _energy = v),
                ),
                const SizedBox(height: 8),
                _RatingRow(
                  label: 'Focus',
                  value: _focus,
                  onChanged: (v) => setState(() => _focus = v),
                ),
                const SizedBox(height: 20),
                Text('What went well?',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _wentWell,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'A win from today…',
                  ),
                ),
                const SizedBox(height: 16),
                Text('What blocked you?',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _blockedBy,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'What got in the way?',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save review'),
                ),
              ],
            ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        for (var i = 1; i <= 5; i++)
          IconButton(
            icon: Icon(
              i <= value ? Icons.circle : Icons.circle_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => onChanged(i),
          ),
      ],
    );
  }
}