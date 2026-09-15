import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay time;
  final String category;
  final String description;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'title': title,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
      'category': category,
      'description': description,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    final hour = map['hour'] is int
        ? map['hour'] as int
        : int.tryParse('${map['hour']}') ?? 0;
    final minute = map['minute'] is int
        ? map['minute'] as int
        : int.tryParse('${map['minute']}') ?? 0;
    return Event(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      time: TimeOfDay(hour: hour, minute: minute),
      category: map['category']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }
}
