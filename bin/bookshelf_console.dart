import 'dart:io';
import 'dart:convert';

void main() {

  print("bookshelf_console");
  print("${Platform.version}");
  print("${Platform.operatingSystem}");

  String title = '';
  while(title.isEmpty){
    stdout.write("Название: ");
    title = stdin.readLineSync(encoding: utf8) ?? '';
    if(title.isEmpty){
      print("Название не должно быть пустым");
    }
  }

  String author;
  stdout.write("Автор: ");
  author = stdin.readLineSync(encoding: utf8) ?? 'Неизвестен';

  stdout.write("Год издания: ");
  final int year = int.tryParse(stdin.readLineSync() ?? '') ?? 0;

  stdout.write("Кол-во страниц: ");
  final int pages = int.tryParse(stdin.readLineSync() ?? '') ?? 0;

  double rating = -1.0;
  while(rating < 0.0 || rating > 5.0){
    stdout.write("Оценка (0 - 5): ");
    final double? ParsedRating = double.tryParse(stdin.readLineSync() ?? '');
    if (ParsedRating == null || ParsedRating < 0.0 || ParsedRating > 5.0){
      print("Оценка должна быть от 0 до 5");
    }
    else{
      rating = ParsedRating;
    }
  }

  stdout.write("Прочитана: ");
  String isRead = (stdin.readLineSync(encoding: utf8) ?? '');

  stdout.write ('');
  stdout.write ("=" * 44);
  stdout.write ("\n <$title>");
  stdout.write ("\n Автор: $author");
  stdout.write ("\n Год: $year");
  stdout.write ("\n Кол-во страниц: $pages");
  stdout.write ("\n Прочитана: $isRead\n");
  stdout.write ("=" * 44);

  String category;
  if (pages < 150){
    category = "брошюра";
  }
  else if (pages < 400){
    category = "книга";
  }
  else{
    category = "том";
  }

  double reading_time = pages / 50;
  int current_year = DateTime.now().year;
  int age = current_year - year;
  String initials = makeInitials(author);

  print("\nКатегория: $category");
  print("Примерное время чтения: $reading_time");
  print("Возраст издания: $age");
  print("Инициалы автора: $initials");

  List<String> shelf = <String>[
    "Пикник на обочине",
    "Понедельник начинается в субботу",
    "Этюд в багровых тонах",
    "Воспоминания немецкого генерала",
    "Ведьмак: Последнее желание",
  ];
  print("Полка: $shelf");
  print("Длинна: ${shelf.length}");
  print("Первый элемент: ${shelf.first}");
  print("Последний элемент: ${shelf.last}");

  shelf.insert(0, "Богиня благославляет этот прекрасный мир 1");
  shelf.add("Трудно быть богом");
  shelf.remove("Воспоминания немецкого генерала");

  stdout.write('Введите жанры через запятую: ');
  String genresInput = stdin.readLineSync(encoding: utf8) ?? '';
  Set<String> genres = <String>{};

  for (String rawGenre in genresInput.split(',')) {
    String genre = rawGenre.trim();
    if (genre.isNotEmpty) {
      genres.add(genre);
    }
  }

  stdout.write('Жанры: $genres\n');
  stdout.write('Уникальных жанров: ${genres.length}\n');

  Map<String, int> pages_book = <String, int>{
    "Пикник на обочине": 192,
    "Понедельник начинается в субботу": 320,
    "Этюд в багровых тонах": 224,
    "Воспоминания немецкого генерала": 570,
    "Ведьмак: Последнее желание": 318,
  };

  pages_book.forEach((String book, int bookpages){
    print(" $book - $bookpages");
  });

  String maxBook = '';
  int maxPages = 0;
  int totalPages = 0;

  for (MapEntry<String, int> entry in pages_book.entries) {
    totalPages += entry.value;
    if (entry.value > maxPages) {
      maxPages = entry.value;
      maxBook = entry.key;
    }
  }

  double avg_pages = totalPages / pages_book.length;

  stdout.write("Максимальным числом страниц: $maxBook ($maxPages)\n");
  stdout.write("Суммарно страниц: $totalPages\n");
  stdout.write("Среднее количество страниц: ${avg_pages.toStringAsFixed(1)}\n");

  List<String> all = <String>[
    ...shelf,
    if (genres.isNotEmpty) 'Жанры: ${genres.join(", ")}',
    for (int i = 1; i <= 3; i++) 'Книга $i',
  ];

  print("Список all: $all");
  print("");

  print('7 / 2 = ${7 / 2}');   // вещественное деление
  print('7 ~/ 2 = ${7 ~/ 2}'); // целочисленное деление
  print('7 % 2 = ${7 % 2}');   // остаток от деления

  bool sideEffect() {
    print("sideEffect вызван");
    return true;
  }

  bool alwaysFalse() => false;
  print("Ленивое &&: ${alwaysFalse() && sideEffect()}");
  print("Ленивое ||: ${(alwaysFalse() == false) || sideEffect()}");

  // ?., ??, ??=
  String? maybeName;
  print("?. для null: ${maybeName?.length}");
  print("?? для null: ${maybeName ?? "имя не задано"}");
  maybeName ??= "BookShelf";
  print("??=: $maybeName");

  final List<int> finalList = <int>[1, 2, 3];
  finalList.add(4); // можно менять содержимое
  // finalList = <int>[5]; // нельзя переприсвоить

  const List<int> constList = <int>[1, 2, 3];
  // constList.add(4); // нельзя менять содержимое

  print("final список: $finalList");
  print("const список: $constList");

  // Каскадный оператор ..
  final StringBuffer buffer = StringBuffer();
  buffer
  ..write("Book")
  ..write("Shelf")
  ..write(" — ")
  ..write("каталог книг");
  print("Каскад: ${buffer.toString()}");
  print("");

}

String makeInitials(String fullName) {
  final List<String> words = fullName
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .toList();

  final List<String> initials = <String>[];
  for (final String word in words) {
    initials.add('${word.substring(0, 1).toUpperCase()}.');
  }
  return initials.join(' ');
}
