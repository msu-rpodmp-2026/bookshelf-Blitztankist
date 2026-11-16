library;

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
  ReadingStatus status;
  double? _rating;

  Book({
    required this.title,
    required this.author,
    this.year = 2024,
    this.pages = 100,
    Set<String>? genres,
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
    'rating': _rating,
  };

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
    ReadingStatus? status,
    double? rating,
  }) {
    return Book(
      title: title ?? this.title,
      author: author ?? this.author,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      genres: genres ?? this.genres,
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
