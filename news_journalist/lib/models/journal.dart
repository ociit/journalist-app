class Journal {
  final int? id;
  final String title;
  final String content;
  final DateTime date; // ubah dari String ke DateTime

  Journal({
    this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  Journal copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? date, // ubah juga disini
  }) {
    return Journal(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (id != null) {
      map['id'] = id;
    }

    map['title'] = title;
    map['content'] = content;
    map['date'] = date.toIso8601String(); // simpan sebagai string ISO8601

    return map;
  }

  factory Journal.fromMap(Map<String, dynamic> map) {
    return Journal(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']), // parsing dari string ke DateTime
    );
  }
}
