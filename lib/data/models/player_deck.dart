import 'package:cloud_firestore/cloud_firestore.dart';

import 'bey_part.dart';

class DeckPartSnapshot {
  final String partId;
  final String category;
  final String name;
  final String? alias;
  final String type;
  final String line;
  final String? image;
  final PartStats stats;
  final List<String> source;

  const DeckPartSnapshot({
    required this.partId,
    required this.category,
    required this.name,
    required this.type,
    required this.line,
    required this.stats,
    required this.source,
    this.alias,
    this.image,
  });

  String get shortCode {
    if (alias != null && alias!.trim().isNotEmpty) return alias!.trim();
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.map((word) => word[0]).take(2).join().toUpperCase();
  }

  String? get assetPath => image == null || image!.trim().isEmpty
      ? null
      : 'assets/beybrew/parts/${image!.trim()}';

  factory DeckPartSnapshot.fromPart(BeyPart part) {
    return DeckPartSnapshot(
      partId: part.id,
      category: part.category,
      name: part.name,
      alias: part.alias,
      type: part.type,
      line: part.line,
      image: part.image,
      stats: part.stats,
      source: part.source,
    );
  }

  factory DeckPartSnapshot.fromMap(Map<String, dynamic> map) {
    return DeckPartSnapshot(
      partId: (map['partId'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      alias: map['alias']?.toString(),
      type: (map['type'] ?? 'balance').toString(),
      line: (map['line'] ?? '').toString(),
      image: map['image']?.toString(),
      source: ((map['source'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      stats: PartStats(
        attack: (map['attack'] as num?)?.round() ?? 0,
        defense: (map['defense'] as num?)?.round() ?? 0,
        stamina: (map['stamina'] as num?)?.round() ?? 0,
        xDash: (map['xDash'] as num?)?.round() ?? 0,
        burstResistance: (map['burstResistance'] as num?)?.round() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'category': category,
      'name': name,
      'alias': alias,
      'type': type,
      'line': line,
      'image': image,
      'attack': stats.attack,
      'defense': stats.defense,
      'stamina': stats.stamina,
      'xDash': stats.xDash,
      'burstResistance': stats.burstResistance,
      'source': source,
    };
  }
}

class DeckComboSnapshot {
  final DeckPartSnapshot? blade;
  final DeckPartSnapshot? assistBlade;
  final DeckPartSnapshot? overBlade;
  final DeckPartSnapshot? lockChip;
  final DeckPartSnapshot? ratchet;
  final DeckPartSnapshot? bit;

  const DeckComboSnapshot({
    this.blade,
    this.assistBlade,
    this.overBlade,
    this.lockChip,
    this.ratchet,
    this.bit,
  });

  List<DeckPartSnapshot> get selectedParts => [
        blade,
        assistBlade,
        overBlade,
        lockChip,
        ratchet,
        bit,
      ].whereType<DeckPartSnapshot>().toList();

  DeckComboDraft toDraft() {
    return DeckComboDraft(
      bladeId: blade?.partId,
      assistBladeId: assistBlade?.partId,
      overBladeId: overBlade?.partId,
      lockChipId: lockChip?.partId,
      ratchetId: ratchet?.partId,
      bitId: bit?.partId,
    );
  }

  String get compactLabel {
    return '${blade?.name ?? '-'} / ${ratchet?.name ?? '-'} / ${bit?.name ?? '-'}';
  }

  factory DeckComboSnapshot.fromDraft(
    BeyPartsCatalog catalog,
    DeckComboDraft draft,
  ) {
    DeckPartSnapshot? snapshot(String? id) {
      if (id == null) return null;
      final part = catalog.find(id);
      return part == null ? null : DeckPartSnapshot.fromPart(part);
    }

    return DeckComboSnapshot(
      blade: snapshot(draft.bladeId),
      assistBlade: snapshot(draft.assistBladeId),
      overBlade: snapshot(draft.overBladeId),
      lockChip: snapshot(draft.lockChipId),
      ratchet: snapshot(draft.ratchetId),
      bit: snapshot(draft.bitId),
    );
  }

  factory DeckComboSnapshot.fromMap(Map<String, dynamic> map) {
    DeckPartSnapshot? part(String key) {
      final raw = map[key];
      if (raw is Map) {
        return DeckPartSnapshot.fromMap(Map<String, dynamic>.from(raw));
      }
      return null;
    }

    return DeckComboSnapshot(
      blade: part('blade'),
      assistBlade: part('assistBlade'),
      overBlade: part('overBlade'),
      lockChip: part('lockChip'),
      ratchet: part('ratchet'),
      bit: part('bit'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blade': blade?.toMap(),
      'assistBlade': assistBlade?.toMap(),
      'overBlade': overBlade?.toMap(),
      'lockChip': lockChip?.toMap(),
      'ratchet': ratchet?.toMap(),
      'bit': bit?.toMap(),
    };
  }
}

class PlayerDeck {
  final String id;
  final String ownerId;
  final String name;
  final String deckClass;
  final String tier;
  final bool legal;
  final List<String> issues;
  final List<DeckComboSnapshot> combos;
  final PartStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlayerDeck({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.deckClass,
    required this.tier,
    required this.legal,
    required this.issues,
    required this.combos,
    required this.stats,
    this.createdAt,
    this.updatedAt,
  });

  List<DeckComboDraft> toDrafts() {
    return combos.map((combo) => combo.toDraft()).toList();
  }

  factory PlayerDeck.fromDraft({
    required String id,
    required String ownerId,
    required String name,
    required BeyPartsCatalog catalog,
    required List<DeckComboDraft> drafts,
  }) {
    final issues = validateDeck(catalog, drafts);
    var total = const PartStats();
    for (final draft in drafts) {
      total = total + comboStats(catalog, draft);
    }
    final averaged = PartStats(
      attack: (total.attack / drafts.length).round(),
      defense: (total.defense / drafts.length).round(),
      stamina: (total.stamina / drafts.length).round(),
      xDash: (total.xDash / drafts.length).round(),
      burstResistance: (total.burstResistance / drafts.length).round(),
    );
    final hasCx = drafts.any((draft) {
      if (draft.bladeId == null) return false;
      return catalog.find(draft.bladeId!)?.isCx ?? false;
    });
    return PlayerDeck(
      id: id,
      ownerId: ownerId,
      name: name.trim().isEmpty ? 'Untitled Deck' : name.trim(),
      deckClass: _deckClass(averaged),
      tier: hasCx ? 'CX READY' : 'STANDARD',
      legal: issues.isEmpty,
      issues: issues,
      combos: drafts
          .map((draft) => DeckComboSnapshot.fromDraft(catalog, draft))
          .toList(),
      stats: averaged,
    );
  }

  factory PlayerDeck.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PlayerDeck.fromMap(doc.id, data);
  }

  factory PlayerDeck.fromMap(String id, Map<String, dynamic> data) {
    DateTime? dateOf(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PlayerDeck(
      id: (data['id'] ?? id).toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      name: (data['name'] ?? 'Untitled Deck').toString(),
      deckClass: (data['deckClass'] ?? 'BALANCE').toString(),
      tier: (data['tier'] ?? 'STANDARD').toString(),
      legal: data['legal'] != false,
      issues: ((data['issues'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      combos: ((data['combos'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) =>
              DeckComboSnapshot.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      stats: PartStats(
        attack: (data['attack'] as num?)?.round() ?? 0,
        defense: (data['defense'] as num?)?.round() ?? 0,
        stamina: (data['stamina'] as num?)?.round() ?? 0,
        xDash: (data['xDash'] as num?)?.round() ?? 0,
        burstResistance: (data['burstResistance'] as num?)?.round() ?? 0,
      ),
      createdAt: dateOf('createdAt'),
      updatedAt: dateOf('updatedAt'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      ...toSnapshot(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toSnapshot() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'deckClass': deckClass,
      'tier': tier,
      'legal': legal,
      'issues': issues,
      'combos': combos.map((combo) => combo.toMap()).toList(),
      'attack': stats.attack,
      'defense': stats.defense,
      'stamina': stats.stamina,
      'xDash': stats.xDash,
      'burstResistance': stats.burstResistance,
    };
  }
}

String _deckClass(PartStats stats) {
  if (stats.attack >= stats.defense && stats.attack >= stats.stamina) {
    return 'ATTACK';
  }
  if (stats.defense >= stats.attack && stats.defense >= stats.stamina) {
    return 'DEFENSE';
  }
  if (stats.stamina >= stats.attack && stats.stamina >= stats.defense) {
    return 'STAMINA';
  }
  return 'BALANCE';
}
