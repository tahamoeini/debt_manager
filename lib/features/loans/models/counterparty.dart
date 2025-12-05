import 'package:flutter/foundation.dart';

@immutable
class Counterparty {
  final int? id;
  final String name;
  final String? type; // e.g. 'bank', 'company', 'person'
  final String? tag; // optional category / tag like 'credit card', 'family'

  const Counterparty({this.id, required this.name, this.type, this.tag});

  /// Convert this model to a map suitable for SQLite insert/update.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'name': name, 'type': type, 'tag': tag};
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Create a [Counterparty] from a map (e.g. result from SQLite query).
  factory Counterparty.fromMap(Map<String, dynamic> map) {
    return Counterparty(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      name: map['name'] as String? ?? '',
      type: map['type'] as String?,
      tag: map['tag'] as String?,
    );
  }

  /// Create a copy with optional overrides.
  Counterparty copyWith({int? id, String? name, String? type, String? tag}) {
    return Counterparty(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      tag: tag ?? this.tag,
    );
  }

  @override
  String toString() =>
      'Counterparty(id: $id, name: $name, type: $type, tag: $tag)';
}
