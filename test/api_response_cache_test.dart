import 'package:edugest/service/api_response_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores and reads API responses for the same user and school', () async {
    final data = [
      {'id': 12, 'name': 'Classe 6e'},
    ];

    await ApiResponseCache.store(
      userId: 'user-1',
      schoolId: 'school-1',
      requestUri: 'https://example.test/api/classes',
      data: data,
    );

    final result = await ApiResponseCache.read(
      userId: 'user-1',
      schoolId: 'school-1',
      requestUri: 'https://example.test/api/classes',
    );
    expect(result.found, isTrue);
    expect(result.data, data);
  });

  test('does not expose cached responses across users or schools', () async {
    await ApiResponseCache.store(
      userId: 'user-1',
      schoolId: 'school-1',
      requestUri: 'https://example.test/api/classes',
      data: [1],
    );

    final otherUser = await ApiResponseCache.read(
      userId: 'user-2',
      schoolId: 'school-1',
      requestUri: 'https://example.test/api/classes',
    );
    final otherSchool = await ApiResponseCache.read(
      userId: 'user-1',
      schoolId: 'school-2',
      requestUri: 'https://example.test/api/classes',
    );

    expect(otherUser.found, isFalse);
    expect(otherSchool.found, isFalse);
  });
}
