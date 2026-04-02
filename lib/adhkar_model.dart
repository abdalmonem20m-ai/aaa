class Dhikr {
  final String id;
  final String category; // صباح، مساء، بعد الصلاة
  final String text;
  final int count; // عدد المرات
  final String? description;

  Dhikr({required this.id, required this.category, required this.text, required this.count, this.description});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'text': text,
      'count': count,
      'description': description,
    };
  }
}