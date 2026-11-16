import 'dart:convert';
import 'dart:io';

import 'package:bookshelf_console/models/models.dart';

String? _readLine() => stdin.readLineSync(encoding: utf8)?.trim();

void _aborted() => print('Ввод прерван — действие отменено.');

int? _askInt(String prompt, {int min = 0, int? max}) {
  while (true) {
    stdout.write('$prompt: ');
    final line = _readLine();
    if (line == null) return null;
    final value = int.tryParse(line);
    if (value != null && value >= min && (max == null || value <= max)) {
      return value;
    }
    print(
      'Некорректное значение. Ожидается целое число'
      '${max == null ? ' не меньше $min' : ' от $min до $max'}.',
    );
  }
}

String? _askString(String prompt, {bool allowEmpty = false}) {
  while (true) {
    stdout.write('$prompt: ');
    final line = _readLine();
    if (line == null) return null;
    if (line.isNotEmpty || allowEmpty) return line;
    print('Пустое значение недопустимо.');
  }
}

bool? _askBool(String prompt) {
  while (true) {
    stdout.write('$prompt (да/нет): ');
    final line = _readLine();
    if (line == null) return null;
    switch (line.toLowerCase()) {
      case 'да':
      case 'yes':
      case 'y':
        return true;
      case 'нет':
      case 'no':
      case 'n':
        return false;
    }
    print('Введите "да" или "нет".');
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
    final String? line = _readLine();

    if (line == null) {
      print('\nВвод завершён.');
      break;
    }

    switch (line) {
      case '1':
        _printAll(library.items);
        break;
      case '2':
        _searchMenu(library);
        break;
      case '3':
        _filterMenu(library);
        break;
      case '4':
        _sortMenu(library);
        break;
      case '5':
        _printStatistics(library);
        break;
      case '6':
        _addBook(library);
        break;
      case '7':
        _deleteBook(library);
        break;
      case '8':
        _demoSpecialMethods();
        break;
      case '0':
        running = false;
        break;
      default:
        print('Неизвестная команда. Повторите ввод.');
    }
  }
  print('Работа завершена.');
}

void printMenu() {
  print('\n${'=' * 44}');
  print(' BookShelf — каталог книг');
  print('=' * 44);
  print(' 1 Показать весь каталог');
  print(' 2 Поиск (по названию, автору, жанру)');
  print(' 3 Фильтр (прочитанные, непрочитанные, жанр)');
  print(' 4 Сортировка (название, автор, год, объём)');
  print(' 5 Статистика каталога');
  print(' 6 Добавить книгу');
  print(' 7 Удалить книгу по номеру');
  print(' 8 Демонстрация ==, hashCode, Set');
  print(' 0 Выход');
  print('=' * 44);
}

void _seedData(Library<Book> lib) {
  lib.add(
    PaperBook(
      title: 'Этюд в багровых тонах',
      author: 'А. К. Дойл',
      shelf: 'A-1',
      year: 2017,
      pages: 448,
      genres: {'детектив'},
      status: ReadingStatus.finished,
    ),
  );
  lib.add(
    PaperBook(
      title: 'На западном фронте без перемен',
      author: 'Э. М. Ремарк',
      shelf: 'A-2',
      year: 2023,
      pages: 256,
      genres: {'роман'},
      status: ReadingStatus.planned,
    ),
  );
  lib.add(
    PaperBook(
      title: 'Преступление и наказание',
      author: 'Ф. М. Достоевский',
      shelf: 'A-3',
      year: 2019,
      pages: 608,
      genres: {'роман'},
      status: ReadingStatus.finished,
    ),
  );
  lib.add(
    PaperBook(
      title: 'Японские мифы: от кицунэ и ёкаев до "звонка" и "наруто"',
      author: 'Д. Фридман',
      shelf: 'B-1',
      year: 2022,
      pages: 272,
      genres: {'Научно-популярная литература'},
      status: ReadingStatus.finished,
    ),
  );
  lib.add(
    PaperBook(
      title: 'Мастер и Маргарита',
      author: 'М. А. Булгаков',
      shelf: 'A-4',
      year: 2012,
      pages: 480,
      genres: {'роман'},
      status: ReadingStatus.planned,
    ),
  );
  lib.add(
    PaperBook(
      title: 'Крещение огнем',
      author: 'А. Сапковский',
      shelf: 'B-2',
      year: 2025,
      pages: 384,
      genres: {'фэнтези'},
      status: ReadingStatus.finished,
    ),
  );
  lib.add(
    PaperBook(
      title: 'Трудно быть богом',
      author: 'А. и Б. Стругацкие',
      shelf: 'B-3',
      year: 2019,
      pages: 256,
      genres: {'фантастика'},
      status: ReadingStatus.finished,
    ),
  );
  lib.add(
    PaperBook(
      title: 'Галлюцинации',
      author: 'Оливер Сакс',
      shelf: 'B-4',
      year: 2026,
      pages: 416,
      genres: {'Научно-популярная литература'},
      status: ReadingStatus.finished,
    ),
  );
}

void _printAll(List<LibraryItem> items) {
  if (items.isEmpty) {
    print('Ничего не найдено.');
    return;
  }
  for (int i = 0; i < items.length; i++) {
    print('${(i + 1).toString().padLeft(2)}. ${items[i].describe()}');
  }
}

void _searchMenu(Library<Book> lib) {
  final q = _askString('Запрос (название, автор или жанр)', allowEmpty: true);
  if (q == null) return _aborted();
  _printAll(lib.search(q).toList());
}

void _filterMenu(Library<Book> lib) {
  print('1 - Только прочитанные');
  print('2 - Только непрочитанные');
  print('3 - По жанру');
  final choice = _askString('Фильтр', allowEmpty: true);
  if (choice == null) return _aborted();

  if (choice == '1') {
    _printAll(lib.where((b) => b.status == ReadingStatus.finished).toList());
  } else if (choice == '2') {
    _printAll(lib.where((b) => b.status != ReadingStatus.finished).toList());
  } else if (choice == '3') {
    final genre = _askString('Жанр');
    if (genre == null) return _aborted();
    final q = genre.toLowerCase();
    _printAll(
      lib.where((b) => b.genres.any((g) => g.toLowerCase() == q)).toList(),
    );
  } else {
    print('Неизвестный фильтр.');
  }
}

void _sortMenu(Library<Book> lib) {
  print('Сортировка:');
  print(' 1 - по названию');
  print(' 2 - по автору');
  print(' 3 - по году');
  print(' 4 - по объёму (страниц)');
  final field = _askString('Поле', allowEmpty: true);
  if (field == null) return _aborted();

  final comparators = <String, int Function(Book, Book)>{
    '1': (a, b) => a.title.compareTo(b.title),
    '2': (a, b) => a.author.compareTo(b.author),
    '3': (a, b) => a.year.compareTo(b.year),
    '4': (a, b) => a.pages.compareTo(b.pages),
  };
  final compare = comparators[field];
  if (compare == null) {
    print('Неизвестное поле.');
    return;
  }

  final desc = _askBool('По убыванию');
  if (desc == null) return _aborted();

  final sorted = [...lib.items]..sort(desc ? (a, b) => compare(b, a) : compare);
  _printAll(sorted);
}

void _printStatistics(Library<Book> lib) {
  if (lib.count == 0) {
    print('Каталог пуст.');
    return;
  }
  final totalPages = lib.items.fold<int>(0, (sum, b) => sum + b.pages);
  final avgPages = totalPages / lib.count;
  print('\n--- Статистика ---');
  print('Всего книг: ${lib.count}');
  print('Средний объём: ${avgPages.toStringAsFixed(1)} стр.');
  print('Книг по жанрам: ${lib.countByGenre()}');
}

void _addBook(Library<Book> lib) {
  print('\n--- Добавление книги ---');
  print('Тип: 1 - бумажная, 2 - электронная, 3 - аудио');
  final type = _askInt('Тип', min: 1, max: 3);
  if (type == null) return _aborted();
  final title = _askString('Название');
  if (title == null) return _aborted();
  final author = _askString('Автор');
  if (author == null) return _aborted();
  final year = _askInt('Год издания', min: 1, max: 2100);
  if (year == null) return _aborted();
  final pages = _askInt('Количество страниц', min: 1);
  if (pages == null) return _aborted();
  final genresInput = _askString('Жанры через запятую');
  if (genresInput == null) return _aborted();
  final genres = genresInput
      .split(',')
      .map((g) => g.trim())
      .where((g) => g.isNotEmpty)
      .toSet();
  print('Статус: 1 - Запланирована, 2 - Читаю, 3 - Прочитана, 4 - Брошена');
  final statusNum = _askInt('Статус', min: 1, max: 4);
  if (statusNum == null) return _aborted();
  final status = ReadingStatus.values[statusNum - 1];

  try {
    switch (type) {
      case 1:
        final shelf = _askString('Полка');
        if (shelf == null) return _aborted();
        lib.add(
          PaperBook(
            title: title,
            author: author,
            shelf: shelf,
            year: year,
            pages: pages,
            genres: genres,
            status: status,
          ),
        );
      case 2:
        final format = _askString('Формат', allowEmpty: true);
        if (format == null) return _aborted();
        final sizeMb = _askInt('Размер, МБ', min: 0);
        if (sizeMb == null) return _aborted();
        lib.add(
          EBook(
            title: title,
            author: author,
            format: format.isEmpty ? 'PDF' : format,
            sizeMb: sizeMb.toDouble(),
            year: year,
            pages: pages,
            genres: genres,
            status: status,
          ),
        );
      case 3:
        final narrator = _askString('Читает');
        if (narrator == null) return _aborted();
        final hours = _askInt('Длительность, часов', min: 1);
        if (hours == null) return _aborted();
        lib.add(
          AudioBook(
            title: title,
            author: author,
            duration: Duration(hours: hours),
            narrator: narrator,
            year: year,
            pages: pages,
            genres: genres,
            status: status,
          ),
        );
    }
    print('Книга «$title» добавлена.');
  } catch (e) {
    print('Ошибка: $e');
  }
}

void _deleteBook(Library<Book> lib) {
  if (lib.count == 0) {
    print('Каталог пуст.');
    return;
  }
  _printAll(lib.items);
  final num = _askInt('Номер книги для удаления', min: 1, max: lib.count);
  if (num == null) return _aborted();
  final book = lib.items[num - 1];
  final confirm = _askBool('Удалить «${book.title}»');
  if (confirm == null) return _aborted();
  if (confirm) {
    lib.remove(book);
    print('Книга «${book.title}» удалена.');
  } else {
    print('Отменено.');
  }
}

void _demoSpecialMethods() {
  print('\n--- Демонстрация ==, hashCode и Set ---');
  final b1 = Book(title: 'Война и мир', author: 'Л. Толстой', year: 1869);
  final b2 = Book(title: 'Война и мир', author: 'Л. Толстой', year: 1869);
  print('b1 == b2: ${b1 == b2}');
  final Set<Book> bookSet = {b1, b2};
  print('Размер Set с двумя одинаковыми книгами: ${bookSet.length}');
}
