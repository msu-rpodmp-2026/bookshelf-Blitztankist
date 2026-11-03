import 'dart:io';
import 'dart:convert';

typedef Book = Map<String, Object?>;
typedef BookPredicate = bool Function(Book book);

final List<Book> library = [
  {
    'title': 'Этюд в багровых тонах',
    'author': 'А. К. Дойл',
    'year': 2017,
    'pages': 448,
    'genre': 'детектив',
    'read': true,
  },
  {
    'title': 'На западном фронте без перемен',
    'author': 'Э. М. Ремарк',
    'year': 2023,
    'pages': 256,
    'genre': 'роман',
    'read': false,
  },
  {
    'title': 'Преступление и наказание',
    'author': 'Ф. М. Достоевский',
    'year': 2019,
    'pages': 608,
    'genre': 'роман',
    'read': true,
  },
  {
    'title': 'Японские мифы: от кицунэ и ёкаев до "звонка" и "наруто"',
    'author': 'Д. Фридман',
    'year': 2022,
    'pages': 272,
    'genre': 'Научно-популярная литература',
    'read': true,
  },
  {
    'title': 'Мастер и Маргарита',
    'author': 'М. А. Булгаков',
    'year': 2012,
    'pages': 480,
    'genre': 'роман',
    'read': false,
  },
  {
    'title': 'Крещение огнем',
    'author': 'А. Сапковский',
    'year': 2025,
    'pages': 384,
    'genre': 'фэнтези',
    'read': true,
  },
  {
    'title': 'Трудно быть богом',
    'author': 'А. и Б. Стругацкие',
    'year': 2019,
    'pages': 256,
    'genre': 'фантастика',
    'read': true,
  },
  {
    'title': 'Галлюцинации',
    'author': 'Оливер Сакс',
    'year': 2026,
    'pages': 416,
    'genre': 'Научно-популярная литература',
    'read': true,
  },
];
void printMenu() {
  print('');
  print('=' * 44);
  print('Bookshelf - каталог книг');
  print('=' * 44);
  print(' 1. Показать весь каталог');
  print(' 2. Поиск по автору');
  print(' 3. Поиск по названию');
  print(' 4. Фильтр по жанру');
  print(' 5. Фильтр по признаку «прочитана»');
  print(' 6. Сортировка (название, автор, год, объём)');
  print(' 7. Статистика каталога');
  print(' 8. Добавить книгу');
  print(' 9. Удалить книгу по номеру');
  print('10. Демонстрация функций высшего порядка');
  print(' 0. Выход');
  print('=' * 44);
}

void printAll(List<Book> books, {String emptyMessage = 'Ничего не найдено.'}) {
  if (books.isEmpty) {
    print(emptyMessage);
    return;
  }
  for (int i = 0; i < books.length; i++) {
    final Book b = books[i];
    final String mark = (b['read'] as bool) ? '[+]' : '[ ]';
    print(
      '${(i + 1).toString().padLeft(2)}. $mark'
      '"${b['title']}" - ${b['author']}. '
      '${b['year']} г., ${b['pages']} стр., жанр: ${b['genre']}',
    );
  }
}

List<Book> searchByField(List<Book> books, String field, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return <Book>[];
  return books
      .where((Book b) => (b[field]?.toString() ?? '').toLowerCase().contains(q))
      .toList();
}

List<Book> filterByRead(List<Book> books, bool isRead) {
  return books.where((Book b) => (b['read'] as bool) == isRead).toList();
}

List<Book> sortBy(List<Book> books, String field, {bool descending = false}) {
  final List<Book> copy = <Book>[...books];
  copy.sort((Book a, Book b) {
    final Object? va = a[field];
    final Object? vb = b[field];
    int cmp;
    if (va is num && vb is num) {
      cmp = va.compareTo(vb);
    } else {
      cmp = (va?.toString() ?? '').compareTo(vb?.toString() ?? '');
    }
    return descending ? -cmp : cmp;
  });
  return copy;
}

void printStatistics(List<Book> books) {
  if (books.isEmpty) {
    print('Каталог пуст.');
    return;
  }
  final int total = books.length;
  final int readCount = books.where((Book b) => b['read'] as bool).length;

  final int totalPages = books.fold<int>(
    0,
    (int sum, Book b) => sum + (b['pages'] as int),
  );
  final double avgPages = totalPages / total;

  final Book oldest = books.reduce(
    (Book a, Book b) => (a['year'] as int) < (b['year'] as int) ? a : b,
  );
  final Book newest = books.reduce(
    (Book a, Book b) => (a['year'] as int) > (b['year'] as int) ? a : b,
  );
  final Book biggest = books.reduce(
    (Book a, Book b) => (a['pages'] as int) > (b['pages'] as int) ? a : b,
  );

  final Set<String> genres = books
      .map((Book b) => b['genre'] as String)
      .toSet();

  final Map<String, int> byGenre = books.fold<Map<String, int>>(
    <String, int>{},
    (Map<String, int> map, Book b) {
      final String g = b['genre'] as String;
      map[g] = (map[g] ?? 0) + 1;
      return map;
    },
  );

  final double readShare = readCount / total * 100;
  final bool allRead = books.every((Book b) => b['read'] as bool);
  final bool anyRead = books.any((Book b) => b['read'] as bool);

  print('');
  print('--- Статистика каталога ---');
  print('Всего книг: $total');
  print('Прочитано: $readCount (${readShare.toStringAsFixed(1)} %)');
  print('Суммарно страниц: $totalPages');
  print('Средний объём: ${avgPages.toStringAsFixed(1)} стр.');
  print('Самая старая: «${oldest['title']}» (${oldest['year']})');
  print('Самая новая: «${newest['title']}» (${newest['year']})');
  print('Самая объёмная: «${biggest['title']}» (${biggest['pages']} стр.)');
  print('Жанры: ${genres.join(", ")}');
  print('Книг по жанрам:');
  byGenre.forEach((String g, int n) => print('  $g — $n'));
  print('Все прочитаны: ${allRead ? "да" : "нет"}');
  print('Есть хотя бы одна прочитанная: ${anyRead ? "да" : "нет"}');
}

int askInt(String prompt, {int min = 0, int? max}) {
  int? value;
  do {
    stdout.write('$prompt: ');
    value = int.tryParse((stdin.readLineSync(encoding: utf8) ?? '').trim());
    if (value == null || value < min || (max != null && value > max)) {
      print(
        'Некорректное значение. Ожидается целое число'
        '${max == null ? "не меньше $min" : "от $min до $max"}.',
      );
      value = null;
    }
  } while (value == null);
  return value;
}

String askString(String prompt, {bool allowEmpty = false}) {
  while (true) {
    stdout.write('$prompt: ');
    final String v = (stdin.readLineSync(encoding: utf8) ?? '').trim();
    if (v.isNotEmpty || allowEmpty) return v;
    print('Пустое значение недопустимо');
  }
}

bool askBool(String prompt) {
  while (true) {
    stdout.write('$prompt (да/нет): ');
    final String a = (stdin.readLineSync(encoding: utf8) ?? '')
        .trim()
        .toLowerCase();
    if (a == 'да' || a == 'yes' || a == 'y') return true;
    if (a == 'нет' || a == 'no' || a == 'n') return false;
    print('Введите "да" или "нет".');
  }
}

void addBook() {
  print('');
  print('--- Добавление книги ---');
  final String title = askString('Название');
  final String author = askString('Автор');
  final int year = askInt('Год издания', min: 1, max: 2100);
  final int pages = askInt('Количество страниц', min: 1);
  final String genre = askString('Жанр');
  final bool read = askBool('Прочитана');

  library.add(<String, Object?>{
    'title': title,
    'author': author,
    'year': year,
    'pages': pages,
    'genre': genre,
    'read': read,
  });

  print('Книга «$title» добавлена.');
}

void deleteBook() {
  if (library.isEmpty) {
    print('Каталог пуст.');
    return;
  }
  printAll(library);
  final int num = askInt(
    'Номер книги для удаления',
    min: 1,
    max: library.length,
  );
  final Book b = library[num - 1];

  if (askBool('Удалить «${b['title']}»')) {
    library.removeAt(num - 1);
    print('Удалено.');
  } else {
    print('Отменено.');
  }
}

void searchByAuthor() {
  final String q = askString('Подстрока автора', allowEmpty: true);
  printAll(searchByField(library, 'author', q));
}

void searchByTitle() {
  final String q = askString('Подстрока названия', allowEmpty: true);
  printAll(searchByField(library, 'title', q));
}

void filterByGenre() {
  final String g = askString('Жанр', allowEmpty: true);
  if (g.isEmpty) {
    print('Жанр не задан');
    return;
  }
  final String q = g.toLowerCase();
  printAll(
    library
        .where((Book b) => (b['genre'] as String).toLowerCase() == q)
        .toList(),
  );
}

void filterByReadMenu() {
  final bool read = askBool('Показать прочитанные');
  printAll(filterByRead(library, read));
}

void sortMenu() {
  print('\nПоле сортировки:');
  print(' 1 — по названию');
  print(' 2 — по автору');
  print(' 3 — по году');
  print(' 4 — по объёму (страниц)');
  stdout.write('> ');
  final String fieldChoice = (stdin.readLineSync(encoding: utf8) ?? '').trim();

  final String field;
  switch (fieldChoice) {
    case '1':
      field = 'title';
      break;
    case '2':
      field = 'author';
      break;
    case '3':
      field = 'year';
      break;
    case '4':
      field = 'pages';
      break;
    default:
      print('Неизвестное поле.');
      return;
  }

  final bool desc = askBool('По убыванию');
  printAll(sortBy(library, field, descending: desc));
}

List<Book> filter(List<Book> books, BookPredicate test) {
  return books.where(test).toList();
}

Function makeCounter() {
  int count = 0;
  return () => ++count;
}

void demoHigherFunctions() {
  final thick = filter(library, (Book b) => (b['pages'] as int) > 500);
  print('\nТолстые книги (>500 стр.):');
  printAll(thick);

  final modern = filter(library, (Book b) => (b['year'] as int) > 2000);
  print('\nКниги нового века (год > 2000):');
  printAll(modern);

  final unreadFunction = filter(
    library,
    (Book b) => b['genre'] == 'фэнтези' && !(b['read'] as bool),
  );
  print('\nНепрочитанное фэнтези:');
  printAll(unreadFunction);
}

void main() {
  final Function counter = makeCounter();
  int executed = 0;
  bool running = true;

  while (running) {
    printMenu();
    stdout.write('> ');
    final command = stdin.readLineSync()?.trim();
    switch (command) {
      case '1':
        printAll(library);
        executed = counter();
        break;
      case '2':
        searchByAuthor();
        executed = counter();
        break;
      case '3':
        searchByTitle();
        executed = counter();
        break;
      case '4':
        filterByGenre();
        executed = counter();
        break;
      case '5':
        filterByReadMenu();
        executed = counter();
        break;
      case '6':
        sortMenu();
        executed = counter();
        break;
      case '7':
        printStatistics(library);
        executed = counter();
        break;
      case '8':
        addBook();
        executed = counter();
        break;
      case '9':
        deleteBook();
        executed = counter();
        break;
      case '10':
        demoHigherFunctions();
        executed = counter();
        break;
      case '0':
        running = false;
        break;
      default:
        print('Неизвестная команда. Повторите ввод');
    }
  }
  print('Работа завершена. Выполнено команд: $executed');
}
