import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/daily_review.dart';
import '../../../shared/widgets/empty_state.dart';

final _reviewsProvider = FutureProvider<List<DailyReviewEntity>>(
  (ref) => ref.watch(dailyReviewsRepositoryProvider).list(),
);

class ReviewsHistoryScreen extends ConsumerWidget {
  const ReviewsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReviews = ref.watch(_reviewsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review history'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/review'),
        icon: const Icon(Icons.add),
        label: const Text('Today'),
      ),
      body: asyncReviews.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.event_note,
              title: 'No reviews yet',
              message: 'End your day by recording what went well and what got in the way.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_reviewsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ReviewTile(review: reviews[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final DailyReviewEntity review;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(_fmt(review.reviewDate.toLocal())),
        subtitle: Row(
          children: [
            if (review.productivityRating != null) _Pill('P', review.productivityRating!),
            if (review.energyRating != null) _Pill('E', review.energyRating!),
            if (review.focusRating != null) _Pill('F', review.focusRating!),
            if (review.wentWell != null && review.wentWell!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.green),
              ),
            if (review.blockedBy != null && review.blockedBy!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.block, size: 16, color: Colors.red),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/review/${_fmt(review.reviewDate.toLocal())}'),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: Text('$label$value'),
      ),
    );
  }
}