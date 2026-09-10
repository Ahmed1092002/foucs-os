import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/entities.dart';
import '../../../core/error/app_failure.dart';
import '../data/areas_repository.dart';

class AreasController extends AsyncNotifier<List<AreaEntity>> {
  @override
  Future<List<AreaEntity>> build() async {
    return _fetch();
  }

  Future<List<AreaEntity>> _fetch() async {
    return ref.read(areasRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<AreaEntity> create({
    required String name,
    required String color,
    String? icon,
  }) async {
    final repo = ref.read(areasRepositoryProvider);
    final created = await repo.create(name: name, color: color, icon: icon);
    await refresh();
    return created;
  }

  Future<void> edit(
    String id, {
    String? name,
    String? color,
    String? icon,
    bool? archived,
  }) async {
    try {
      await ref.read(areasRepositoryProvider).update(
            id,
            name: name,
            color: color,
            icon: icon,
            archived: archived,
          );
      await refresh();
    } on AppFailure {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    await ref.read(areasRepositoryProvider).delete(id);
    await refresh();
  }
}

final areasControllerProvider =
    AsyncNotifierProvider<AreasController, List<AreaEntity>>(
  AreasController.new,
);