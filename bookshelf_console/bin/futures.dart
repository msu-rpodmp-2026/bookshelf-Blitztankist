import 'dart:async';

Future<String> slowTask(String name, int seconds) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  return '$name: выполнена';
}

Future<void> main() async {
  final sw = Stopwatch();

  print('--- Последовательный запуск (await один за другим) ---');
  sw.start();
  await slowTask('Первая', 2);
  await slowTask('Вторая', 3);
  await slowTask('Третья', 2);
  sw.stop();
  print('Время: ${sw.elapsed}');

  print('\n--- Параллельный запуск (Future.wait) ---');
  sw
    ..reset()
    ..start();
  final results = await Future.wait([
    slowTask('Первая', 2),
    slowTask('Вторая', 3),
    slowTask('Третья', 2),
  ]);
  sw.stop();
  for (final r in results) {
    print(r);
  }
  print('Время: ${sw.elapsed}');

  print('\n--- Future.any: побеждает самый быстрый ---');
  final fastest = await Future.any([
    slowTask('Медленная', 3),
    slowTask('Быстрая', 1),
  ]);
  print(fastest);

  print('\n--- timeout и TimeoutException ---');
  try {
    await slowTask('Долгая', 5).timeout(const Duration(milliseconds: 300));
  } on TimeoutException {
    print('TimeoutException перехвачена: задача не уложилась в 300 мс');
  }

  print('\n--- Забытый await ---');
  final result = slowTask('Без await', 1);
  print('Без await значение ещё не готово, в переменной Future: $result');
  final value = await result;
  print('После await значение доступно: $value');
}
