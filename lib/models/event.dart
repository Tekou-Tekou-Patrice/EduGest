import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay time;
  final String category;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
      'category': category,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
      category: map['category'],
    );
  }
}
