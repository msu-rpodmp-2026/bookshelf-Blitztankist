library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

enum ReadingStatus {
  planned('Запланирована', 0),
  reading('Читаю', 1),
  finished('Прочитана', 2),
  abandoned('Брошена', 3);

  final String label;
  final int order;
  const ReadingStatus(this.label, this.order);
  bool get isDone => this == ReadingStatus.finished;

  static ReadingStatus fromName(String name) =>
      values.firstWhere((s) => s.name == name, orElse: () => planned);
}

abstract class LibraryItem {
  String get title;
  String describe();
  void printCard() => print(describe());
}

abstract interface class Searchable {
  bool matches(String query);
}

abstract interface class Exportable {
  Map<String, dynamic> toJson();
}

mixin Rateable {
  double _sumVotes = 0;
  int _countVotes = 0;

  double get averageRating => _countVotes == 0 ? 0 : _sumVotes / _countVotes;

  void vote(double value) {
    if (value >= 0 && value <= 10) {
      _sumVotes += value;
      _countVotes++;
    }
  }
}

mixin Loggable {
  void log(String message) {
    final now = DateTime.now().toIso8601String();
    print('[$now] LOG: $message');
  }
}

mixin Borrowable on Book {
  DateTime? _dueDate;
  bool get isBorrowed => _dueDate != null;
  void borrow(int days) {
    _dueDate = DateTime.now().add(Duration(days: days));
    print('Книга "$title" выдана до ${_dueDate.toString().split(' ')[0]}');
  }

  void giveBack() {
    if (isBorrowed) {
      _dueDate = null;
      print('Книга "$title" возвращена.');
    }
  }
}

class Book extends LibraryItem
    with Rateable
    implements Searchable, Exportable, Comparable<Book> {
  @override
  final String title;
  final String author;
  final int year;
  final int pages;
  final Set<String> genres;
  final String? coverUrl;
  ReadingStatus status;
  double? _rating;

  Book({
    required this.title,
    required this.author,
    this.year = 2024,
    this.pages = 100,
    Set<String>? genres,
    this.coverUrl,
    this.status = ReadingStatus.planned,
    double? rating,
  }) : genres = genres ?? <String>{} {
    if (rating != null) {
      this.rating = rating;
    }
  }

  String get shortTitle =>
      title.length > 25 ? '${title.substring(0, 22)}...' : title;
  double get readingHours => pages / 50.0;
  int get age => DateTime.now().year - year;
  bool get isRated => _rating != null;
  double? get rating => _rating;

  set rating(double value) {
    if (value < 0 || value > 5) {
      throw ArgumentError('Оценка должна быть от 0 до 5');
    }
    _rating = value;
  }

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'year': year,
    'pages': pages,
    'genres': genres.toList(),
    'status': status.name,
    if (_rating != null) 'rating': _rating,
    if (coverUrl != null) 'coverUrl': coverUrl,
  };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
    title: j['title'] is String ? j['title'] as String : 'Без названия',
    author: j['author'] is String ? j['author'] as String : 'Автор неизвестен',
    year: j['year'] is num ? (j['year'] as num).toInt() : 0,
    pages: j['pages'] is num ? (j['pages'] as num).toInt() : 0,
    genres: j['genres'] is List
        ? (j['genres'] as List).whereType<String>().toSet()
        : <String>{},
    status: ReadingStatus.fromName(
      j['status'] is String ? j['status'] as String : '',
    ),
    rating: j['rating'] is num ? (j['rating'] as num).toDouble() : null,
    coverUrl: j['coverUrl'] is String ? j['coverUrl'] as String : null,
  );

  @override
  String describe() {
    final ratingStr = isRated ? _rating!.toStringAsFixed(1) : 'нет';
    return '«$title» — $author ($year г., $pages стр., статус: '
        '${status.label}, оценка: $ratingStr)';
  }

  @override
  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        author.toLowerCase().contains(q) ||
        genres.any((g) => g.toLowerCase().contains(q));
  }

  @override
  String toString() => 'Book(title: $title, author: $author, year: $year)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Book &&
        other.title == title &&
        other.author == author &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(title, author, year);

  @override
  int compareTo(Book other) => title.compareTo(other.title);

  Book copyWith({
    String? title,
    String? author,
    int? year,
    int? pages,
    Set<String>? genres,
    String? coverUrl,
    ReadingStatus? status,
    double? rating,
  }) {
    return Book(
      title: title ?? this.title,
      author: author ?? this.author,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      genres: genres ?? this.genres,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      rating: rating ?? _rating,
    );
  }
}

class PaperBook extends Book with Loggable, Borrowable {
  final String shelf;
  PaperBook({
    required super.title,
    required super.author,
    required this.shelf,
    super.year,
    super.pages,
    super.genres,
    super.status,
    super.rating,
  });

  @override
  String describe() => '${super.describe()} [Бумажная, полка: $shelf]';
}

class EBook extends Book {
  final String format;
  final double sizeMb;
  EBook({
    required super.title,
    required super.author,
    required this.format,
    required this.sizeMb,
    super.year,
    super.pages,
    super.genres,
    super.status,
    super.rating,
  });

  @override
  String describe() =>
      '${super.describe()} [Электронная, формат: $format, $sizeMb МБ]';
}

class AudioBook extends Book {
  final Duration duration;
  final String narrator;
  AudioBook({
    required super.title,
    required super.author,
    required this.duration,
    required this.narrator,
    super.year,
    super.pages,
    super.genres,
    super.status,
    super.rating,
  });
  @override
  double get readingHours => duration.inMinutes / 60;
  @override
  String describe() =>
      '«$title» — аудиокнига, читает $narrator, '
      '${duration.inMinutes} мин.';
}

class Library<T extends LibraryItem> {
  final List<T> _items = [];

  List<T> get items => List.unmodifiable(_items);
  int get count => _items.length;

  void add(T item) {
    if (!_items.contains(item)) {
      _items.add(item);
    } else {
      print('Такая книга уже есть');
    }
  }

  bool remove(T item) => _items.remove(item);

  T? findByTitle(String title) {
    for (final item in _items) {
      if (item.title.toLowerCase() == title.toLowerCase()) return item;
    }
    return null;
  }

  Iterable<T> search(String query) => _items.where(
    (item) => item is Searchable && (item as Searchable).matches(query),
  );
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

class LibraryFormatException implements Exception {
  final String message;
  final int line;
  LibraryFormatException(this.message, this.line);

  @override
  String toString() => 'Ошибка в строке $line: $message';
}

class LibraryStorage {
  final String directory;
  const LibraryStorage(this.directory);

  String get _jsonPath => p.join(directory, 'library.json');
  String get _csvPath => p.join(directory, 'library.csv');

  Future<List<Book>> load() async {
    final file = File(_jsonPath);
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! List) {
        throw const FormatException('корневой элемент не является массивом');
      }
      return data.whereType<Map<String, dynamic>>().map(Book.fromJson).toList();
    } on FormatException {
      await file.rename('$_jsonPath.bak');
      stderr.writeln('Файл каталога повреждён, сохранён как library.json.bak');
      return [];
    }
  }

  Future<void> save(List<Book> books) async {
    await Directory(directory).create(recursive: true);
    final json = JsonEncoder.withIndent('  ')
        .convert(books.map((b) => b.toJson()).toList());
    final tmp = File('$_jsonPath.tmp');
    await tmp.writeAsString(json);
    await tmp.rename(_jsonPath);
  }

  Future<void> exportCsv(List<Book> books) async {
    await Directory(directory).create(recursive: true);
    final lines = <String>['title;author;year;pages;genres;status;rating'];
    for (final b in books) {
      lines.add(
        [
          _csvField(b.title),
          _csvField(b.author),
          b.year.toString(),
          b.pages.toString(),
          _csvField(b.genres.join(',')),
          b.status.name,
          if (b.rating != null) b.rating.toString(),
        ].join(';'),
      );
    }
    await File(_csvPath).writeAsString('${lines.join('\n')}\n');
  }

  Future<List<Book>> importCsv() async {
    final file = File(_csvPath);
    if (!await file.exists()) {
      return [];
    }
    final books = <Book>[];
    var skipped = 0;
    final lines = await file.readAsLines();
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        continue;
      }
      try {
        books.add(_parseCsvLine(line, i + 1));
      } on LibraryFormatException {
        skipped++;
      }
    }
    if (skipped > 0) {
      print('Импорт из CSV: пропущено некорректных строк — $skipped');
    }
    return books;
  }

  Book _parseCsvLine(String line, int lineNo) {
    final fields = _splitCsvLine(line);
    if (fields.length < 5) {
      throw LibraryFormatException(
        'неверное число полей (${fields.length})',
        lineNo,
      );
    }
    return Book(
      title: fields[0].isEmpty ? 'Без названия' : fields[0],
      author: fields[1],
      year: int.tryParse(fields[2]) ?? 0,
      pages: int.tryParse(fields[3]) ?? 0,
      genres: fields[4]
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toSet(),
      status: ReadingStatus.fromName(fields.length > 5 ? fields[5] : ''),
      rating: fields.length > 6 ? double.tryParse(fields[6]) : null,
    );
  }

  List<String> _splitCsvLine(String line) {
    final fields = <String>[];
    var buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ';') {
        fields.add(buf.toString());
        buf = StringBuffer();
      } else {
        buf.write(ch);
      }
    }
    fields.add(buf.toString());
    return fields;
  }

  String _csvField(String value) {
    if (value.contains(';') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<bool> backup() async {
    final source = File(_jsonPath);
    if (!await source.exists()) {
      return false;
    }
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}';
    await source.copy(p.join(directory, 'library_$stamp.json'));
    return true;
  }
}
