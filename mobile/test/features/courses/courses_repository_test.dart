// Unit tests for CoursesRepository against a fake Dio adapter.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/core/domain/courses.dart';
import 'package:focus_os/core/error/app_failure.dart';
import 'package:focus_os/data/remote/api_client.dart';
import 'package:focus_os/data/remote/token_storage.dart';
import 'package:focus_os/features/courses/data/courses_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);
  final Future<ResponseBody> Function(RequestOptions options) responder;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      responder(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) {
  final bytes = Uint8List.fromList(utf8.encode(json.encode(body)));
  return ResponseBody.fromBytes(bytes, status, headers: {
    'content-type': ['application/json'],
  });
}

class _NoOpTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<String?> readUserId() async => null;
  @override
  Future<String?> readEmail() async => null;
  @override
  Future<String?> readTimezone() async => null;
  @override
  Future<void> clear() async {}
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String timezone,
  }) async {}
  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

Map<String, dynamic> _courseJson({
  required String id,
  required String subjectId,
  required String name,
  List<Map<String, dynamic>> modules = const [],
}) {
  return {
    'id': id,
    'userId': 'u1',
    'subjectId': subjectId,
    'name': name,
    'description': null,
    'createdAt': '2026-09-07T00:00:00.000Z',
    'updatedAt': '2026-09-07T00:00:00.000Z',
    'modules': modules,
  };
}

Map<String, dynamic> _moduleJson({
  required String id,
  required String courseId,
  required String name,
  List<Map<String, dynamic>> lessons = const [],
}) {
  return {
    'id': id,
    'courseId': courseId,
    'name': name,
    'description': null,
    'orderIndex': 0,
    'lessons': lessons,
  };
}

Map<String, dynamic> _lessonJson({
  required String id,
  required String moduleId,
  required String name,
  String status = 'not_started',
}) {
  return {
    'id': id,
    'moduleId': moduleId,
    'name': name,
    'description': null,
    'status': status,
    'orderIndex': 0,
    'completedAt': null,
    'createdAt': '2026-09-07T00:00:00.000Z',
    'updatedAt': '2026-09-07T00:00:00.000Z',
  };
}

void main() {
  late ApiClient api;
  late CoursesRepository repo;

  setUp(() {
    api = ApiClient(tokenStorage: _NoOpTokenStorage());
    repo = CoursesRepository(api);
  });

  test('list decodes nested course tree', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json([
        _courseJson(
          id: 'c1',
          subjectId: 's1',
          name: 'React',
          modules: [
            _moduleJson(
              id: 'm1',
              courseId: 'c1',
              name: 'Hooks',
              lessons: [
                _lessonJson(id: 'l1', moduleId: 'm1', name: 'useEffect'),
                _lessonJson(id: 'l2', moduleId: 'm1', name: 'useMemo', status: 'completed'),
              ],
            ),
          ],
        ),
      ]);
    });

    final courses = await repo.list();
    expect(courses, hasLength(1));
    expect(courses.first.modules, hasLength(1));
    expect(courses.first.modules.first.lessons, hasLength(2));
    expect(courses.first.modules.first.lessons.last.isCompleted, true);
  });

  test('create posts the right body shape', () async {
    Map<String, dynamic>? captured;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      captured = opts.data as Map<String, dynamic>?;
      return _json(_courseJson(id: 'c1', subjectId: 's1', name: 'Angular'));
    });
    await repo.create(subjectId: 's1', name: 'Angular');
    expect(captured!['subjectId'], 's1');
    expect(captured!['name'], 'Angular');
  });

  test('updateLesson sends the right status wire', () async {
    Map<String, dynamic>? captured;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      captured = opts.data as Map<String, dynamic>?;
      return _json(_lessonJson(
        id: 'l1',
        moduleId: 'm1',
        name: 'useEffect',
        status: 'completed',
      ));
    });
    await repo.updateLesson(
      'c1',
      'm1',
      'l1',
      status: LessonStatus.completed,
    );
    expect(captured!['status'], 'completed');
  });

  test('subjectProgress decodes all numbers correctly', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json({
        'subjectId': 's1',
        'completedHours': 1.5,
        'targetHours': 40.0,
        'percentTime': 0.0375,
        'totalLessons': 4,
        'completedLessons': 1,
        'percentLessons': 0.25,
        'percentComplete': 0.14375,
      });
    });
    final p = await repo.subjectProgress('s1');
    expect(p.completedHours, 1.5);
    expect(p.totalLessons, 4);
    expect(p.completedLessons, 1);
    expect(p.percentComplete, closeTo(0.14375, 1e-5));
  });

  test('failure maps to NotFoundFailure on 404', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json({'code': 'NOT_FOUND', 'message': 'Course not found'},
          status: 404);
    });
    expect(
      () => repo.getOne('nope'),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}