import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/services/sorting_set_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'saves immutable original numbers and loads them in recent-first order',
    () async {
      final input = [9, 2, 5];
      final first = await SortingSetStorageService.save('Mi práctica', input);
      input[0] = 0;
      final second = await SortingSetStorageService.save('Mi práctica', [4, 1]);

      expect(first.values, [9, 2, 5]);
      expect(second.name, 'Mi práctica (2)');
      expect(
        (await SortingSetStorageService.getSavedSets()).map(
          (item) => item.values,
        ),
        [
          [4, 1],
          [9, 2, 5],
        ],
      );
      expect(() => first.values.add(8), throwsUnsupportedError);
    },
  );

  test('deletes only the selected saved set', () async {
    final first = await SortingSetStorageService.save('A', [3, 1]);
    final second = await SortingSetStorageService.save('B', [8, 7]);
    await SortingSetStorageService.delete(first.id);
    final saved = await SortingSetStorageService.getSavedSets();
    expect(saved, hasLength(1));
    expect(saved.single.id, second.id);
  });
}
