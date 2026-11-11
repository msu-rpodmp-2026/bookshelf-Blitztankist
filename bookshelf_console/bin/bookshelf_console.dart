import 'dart:io';
import 'dart:convert';

//перечисление
enum readingStatus{
  planned('Запланирована', 0),
  reading('Читаю', 1),
  finished('Прочитана', 2),
  abandoned('Брошена', 3);

  final String label;
  final int order;
  const readingStatus(this.label, this.order);
  bool get isDone => this == readingStatus.finished;
}
//абстрактные классы интерфейса
abstract class LibraryItem {
  String get title;
  String describe();
  void printCard() => print(describe);
}

abstract interface class Searchable {
  bool matches(String query);
}

abstract interface class Exportable {
  Map<String, dynamic> toJson();
}
//основные классы
class Book extends LibraryItem with Rateable{
  @override
  final String title;
  final String author;
  final int year;
  final int pages;
  final Set<String> genres;
  readingStatus status;
  double? _rating;

  Book({
    required this.title,
    required this.author,
    this.year = 2024,
    this.pages = 100,
    Set<String>? genres,
    this.status = readingStatus.planned,
    double? rating,
}) : genres = genres ?? <String>{}, _rating = rating {
    if (rating != null){
      setRating(rating);
    }
  }

  String get shortTitle => title.length > 25 ? '${title.substring(0, 22)}...'
      : title;
  double get readingHours => pages / 50.0;
  int get age => DateTime.now().year - year;
  bool get isRated => _rating != null;

  @override
  void setRating(double value){
    if (value < 0 || value > 10)
      throw ArgumentError('Оценка должна быть от 0 ''4до 10');
    _rating = value;
  }

  @override
  String describe(){
    final ratingStr = isRated ? _rating.toStringAsFixed(1) : 'нет';
    return '«$title» — $author ($year г., $pages стр., статус: '
        '${status.label}, оценка: $ratingStr)';
  }

  @override
  bool matches(String query){
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) || author.toLowerCase().contains(q)
        || genres.any((g) => g.toLowerCase().contains(q));
  }

  @override
  String toString() => 'Book(title: $title, author: $author, year: $year)';

  @override
  bool operator == (Object other) {
    if (identical(this, other))
      return true;
    return other is Book && other.title == title && other.author == author
        && other.year == year;
  }

  @override
  int get hashCode => Object.hash(title, author, year);

  @override
  int compareTo(Book other) => title.compareTo(other.title);

  Book copyWith({String? title, String? author, int? year, int? pages,
    Set<String>? genres, readingStatus? status, double? rating}){
    return Book(
      title: title ?? this.title, author: author ?? this.author,
      year: year ?? this.year, pages: pages ?? this.pages,
      genres: genres ?? this.genres, status: status ?? this.status,
      rating: rating ?? _rating,
    );
  }
}

class PaperBook extends Book with Rateable, Loggable, Borrowable {
  final String shelf;
  PaperBook({required super.title, required super.author, required this.shelf,
    super.year, super.pages, super.genres, super.status, super.rating});

  @override
  String describe() => '${super.describe()} [Бумажная, полка: $shelf]';
}

class EBook extends Book {
  final String format;
  final double sizeMb;
  EBook({required super.title, required super.author, required this.format,
    required this.sizeMb, super.year, super.pages, super.genres, super.status,
    super.rating});

  @override
  String describe() => '${super.describe()} [Электронная, формат: '
      '$format, $sizeMb МБ]';
}

class AudioBook extends Book{
  final Duration duration;
  final String narrator;
  AudioBook({
    required super.title,
    required super.author,
    required this.duration,
    required this.narrator,
    super.year,
  });
  @override
  double get readingHours => duration.inMinutes / 60;
  @override
  String describe() => '«$title» — аудиокнига, читает $narrator, '
      '${duration.inMinutes} мин.';
}

class Library<T extends LibraryItem>{
  final List<T> _items = [];

  List<T> get items => List.unmodifiable(_items);
  int get count => _items.length;

  void add(T item){
    if (!_items.contains(item))
      _items.add(item);
    else print('Такая книга уже есть');
  }

  bool remove(T item) => _items.remove(item);

  T? findByTitle(String title){
    try{
      return _items.firstWhere((item) => item.title.toLowerCase()
          == title.toLowerCase());
    }
    catch(e) {return null;}
  }

  Iterable<T> search(String query) => _items.where((item) => item is
  Searchable && (item as Searchable).matches(query));
  Iterable<T> where(bool Function(T) test) => _items.where(test);

  Map<String, int> countByGenre() {
    final Map<String, int> counts = {};
    for (final item in _items) {
      if (item is Book) {
        for (final genre in item.genres) {
          counts[genre] = (counts[genre] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}

//миксины
mixin Rateable {
  double _sumVotes = 0;
  int _countVotes = 0;

  double get averageRating => _countVotes == 0 ? 0 : _sumVotes / _countVotes;

  void vote(double value){
    if (value >= 0 && value <= 10) {
      _sumVotes += value;
      _countVotes++;
    }
  }
}

mixin Loggable{
  void log(String message){
    final now = DateTime.now().toIso8601String();
    print('[$now] LOG: #=$message');
  }
}

mixin Borrowable on Book {
  DateTime? _dueDate;
  bool get isBorrowed => _dueDate != null;
  void borrow(int days){
    _dueDate = DateTime.now().add(Duration(days: days));
    print('Книга "$title" выдана до ${_dueDate.toString().split(' ')[0]}');
  }
  void giveBack(){
    if (isBorrowed){
      _dueDate = null;
      print('Книга "$title" возвращена.');
    }
  }
}

void main() {
  stdout.encoding = utf8;
  final Library<Book> library = Library<Book>();
  _seedData(library);

  bool running = true;
  while (running) {
    printMenu();
    stdout.write('> ');
    final String command = (stdin.readLineSync(encoding: utf8) ?? '').trim();

    switch (command) {
      case '1': _printAll(library.items); break;
      case '2': _searchMenu(library); break;
      case '3': _filterMenu(library); break;
      case '4': _sortMenu(library); break;
      case '5': _printStatistics(library); break;
      case '6': _addBook(library); break;
      case '7': _deleteBook(library); break;
      case '8': _demoSpecialMethods(); break;
      case '0': running = false; break;
      default: print('Неизвестная команда. Повторите ввод.');
    }
  }
  print('Работа завершена.');
}

void printMenu() {
  print('\n' + '=' * 44);
  print(' BookShelf — каталог книг (ООП)');
  print('=' * 44);
  print(' 1 Показать весь каталог');
  print(' 2 Поиск (по названию, автору, жанру)');
  print(' 3 Фильтр (прочитанные, по жанру)');
  print(' 4 Сортировка (по названию)');
  print(' 5 Статистика каталога');
  print(' 6 Добавить книгу');
  print(' 7 Удалить книгу по номеру');
  print(' 8 Демонстрация ==, hashCode, Set (Задание 6)');
  print(' 0 Выход');
  print('=' * 44);
}

void _seedData(Library<Book> lib) {
  lib.add(PaperBook(
      title: 'Этюд в багровых тонах',
      author: 'А. К. Дойл',
      shelf: 'A-1',
      year: 2017,
      pages: 448,
      genres: {'детектив'},
      status: readingStatus.finished));
  lib.add(PaperBook(
      title: 'На западном фронте без перемен',
      author: 'Э. М. Ремарк',
      shelf: 'A-2',
      year: 2023,
      pages: 256,
      genres: {'роман'},
      status: readingStatus.planned));
  lib.add(PaperBook(
      title: 'Преступление и наказание',
      author: 'Ф. М. Достоевский',
      shelf: 'A-3',
      year: 2019,
      pages: 608,
      genres: {'роман'},
      status: readingStatus.finished));
  lib.add(PaperBook(
      title: 'Японские мифы: от кицунэ и ёкаев до "звонка" и "наруто"',
      author: 'Д. Фридман',
      shelf: 'B-1',
      year: 2022,
      pages: 272,
      genres: {'Научно-популярная литература'},
      status: readingStatus.finished));
  lib.add(PaperBook(
      title: 'Мастер и Маргарита',
      author: 'М. А. Булгаков',
      shelf: 'A-4',
      year: 2012,
      pages: 480,
      genres: {'роман'},
      status: readingStatus.planned));
  lib.add(PaperBook(
      title: 'Крещение огнем',
      author: 'А. Сапковский',
      shelf: 'B-2',
      year: 2025,
      pages: 384,
      genres: {'фэнтези'},
      status: readingStatus.finished));
  lib.add(PaperBook(
      title: 'Трудно быть богом',
      author: 'А. и Б. Стругацкие',
      shelf: 'B-3',
      year: 2019,
      pages: 256,
      genres: {'фантастика'},
      status: readingStatus.finished));
  lib.add(PaperBook(
      title: 'Галлюцинации',
      author: 'Оливер Сакс',
      shelf: 'B-4',
      year: 2026,
      pages: 416,
      genres: {'Научно-популярная литература'},
      status: readingStatus.finished));
}

void _printAll(List<LibraryItem> items) {
  if (items.isEmpty) { print('Ничего не найдено.'); return; }
  for (int i = 0; i < items.length; i++) {
    print('${(i + 1).toString().padLeft(2)}. ${items[i].describe()}');
  }
}

void _searchMenu(Library<Book> lib) {
  stdout.write('Введите запрос (название, автор или жанр): ');
  final q = (stdin.readLineSync(encoding: utf8) ?? '').trim();
  _printAll(lib.search(q).toList());
}

void _filterMenu(Library<Book> lib) {
  print('1 - Только прочитанные\n2 - Фильтр по жанру');
  stdout.write('> ');
  final choice = (stdin.readLineSync(encoding: utf8) ?? '').trim();
  if (choice == '1') _printAll(lib.where((b) => b.status ==
      readingStatus.finished).toList());
  else if (choice == '2') {
    stdout.write('Введите жанр: ');
    final genre = (stdin.readLineSync(encoding: utf8) ?? '')
        .trim().toLowerCase();
    _printAll(lib.where((b) => b.genres.any((g) => g.toLowerCase() == genre))
        .toList());
  }
}

void _sortMenu(Library<Book> lib) {
  final List<Book> sorted = List.from(lib.items);
  sorted.sort(); // Благодаря compareTo в классе Book
  _printAll(sorted);
}

void _printStatistics(Library<Book> lib) {
  if (lib.count == 0) { print('Каталог пуст.'); return; }
  final totalPages = lib.items.fold<int>(0, (sum, b) => sum + b.pages);
  final avgPages = totalPages / lib.count;
  print('\n--- Статистика ---');
  print('Всего книг: ${lib.count}');
  print('Средний объём: ${avgPages.toStringAsFixed(1)} стр.');
  print('Книг по жанрам: ${lib.countByGenre()}');
}

void _addBook(Library<Book> lib) {
  print('\nВыберите тип книги: 1 - Бумажная, 2 - Электронная, 3 - Аудио');
  stdout.write('> ');
  final type = (stdin.readLineSync(encoding: utf8) ?? '').trim();
  stdout.write('Название: ');
  final title = (stdin.readLineSync(encoding: utf8) ?? '').trim();
  stdout.write('Автор: ');
  final author = (stdin.readLineSync(encoding: utf8) ?? '').trim();

  if (title.isEmpty || author.isEmpty) { print('Ошибка: пустые поля.'); return; }
  try {
    if (type == '1') {
      stdout.write('Полка: ');
      final shelf = (stdin.readLineSync(encoding: utf8) ?? '').trim();
      lib.add(PaperBook(title: title, author: author, shelf: shelf));
    } else if (type == '2') {
      lib.add(EBook(title: title, author: author, format: 'PDF', sizeMb: 5.0));
    } else if (type == '3') {
      lib.add(AudioBook(title: title, author: author, duration: Duration(hours: 2), narrator: 'Неизвестен'));
    } else { print('Неверный тип.'); return; }
    print('Книга добавлена.');
  } catch (e) { print('Ошибка: $e'); }
}

void _deleteBook(Library<Book> lib) {
  _printAll(lib.items);
  stdout.write('Введите номер для удаления: ');
  final num = int.tryParse((stdin.readLineSync(encoding: utf8) ?? '').trim());
  if (num != null && num > 0 && num <= lib.count) {
    final book = lib.items[num - 1];
    if (lib.remove(book)) print('Книга «${book.title}» удалена.');
  } else { print('Неверный номер.'); }
}

void _demoSpecialMethods() {
  print('\n--- Демонстрация ==, hashCode и Set ---');
  final b1 = Book(title: 'Война и мир', author: 'Л. Толстой', year: 1869);
  final b2 = Book(title: 'Война и мир', author: 'Л. Толстой', year: 1869);
  print('b1 == b2: ${b1 == b2}');
  final Set<Book> bookSet = {b1, b2};
  print('Размер Set с двумя одинаковыми книгами: ${bookSet.length}');
}