import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';

final beyPartsCatalogProvider = FutureProvider<BeyPartsCatalog>((ref) async {
  final base = await BeyPartsCatalog.load();
  try {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.components)
        .where('active', isEqualTo: true)
        .limit(500)
        .get();
    final adminParts = snap.docs.map(BeyPart.fromFirestore).toList();
    return base.merge(adminParts);
  } catch (_) {
    return base;
  }
});

class PartStats {
  final int attack;
  final int defense;
  final int stamina;
  final int xDash;
  final int burstResistance;

  const PartStats({
    this.attack = 0,
    this.defense = 0,
    this.stamina = 0,
    this.xDash = 0,
    this.burstResistance = 0,
  });

  int get total => attack + defense + stamina + xDash + burstResistance;

  PartStats operator +(PartStats other) {
    return PartStats(
      attack: attack + other.attack,
      defense: defense + other.defense,
      stamina: stamina + other.stamina,
      xDash: xDash + other.xDash,
      burstResistance: burstResistance + other.burstResistance,
    );
  }

  Map<String, int> toMap() {
    return {
      'attack': attack,
      'defense': defense,
      'stamina': stamina,
      'xDash': xDash,
      'burstResistance': burstResistance,
    };
  }
}

class BeyPart {
  final String id;
  final String category;
  final String name;
  final String? alias;
  final String type;
  final String line;
  final String? image;
  final String? spinType;
  final String? integratedRatchet;
  final String? description;
  final List<String> source;
  final List<PartStats> modes;
  final List<String> modeLabels;
  final PartStats stats;

  const BeyPart({
    required this.id,
    required this.category,
    required this.name,
    required this.type,
    required this.line,
    required this.source,
    required this.stats,
    this.alias,
    this.image,
    this.spinType,
    this.integratedRatchet,
    this.description,
    this.modes = const [],
    this.modeLabels = const [],
  });

  bool get isCx => line.toUpperCase() == 'CX';
  String? get imageUrl {
    final value = image?.trim();
    if (value == null || value.isEmpty) return null;
    return _isNetworkImage(value) ? value : null;
  }

  String? get assetPath {
    final value = image?.trim();
    if (value == null || value.isEmpty || _isNetworkImage(value)) return null;
    return 'assets/beybrew/parts/$value';
  }
  bool get isIntegrated =>
      integratedRatchet != null ||
      name.toLowerCase().contains('integrated') ||
      category == 'ratchets' && name.toLowerCase().contains('integrated');

  String get shortCode {
    if (alias != null && alias!.trim().isNotEmpty) return alias!.trim();
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.map((word) => word[0]).take(2).join().toUpperCase();
  }

  factory BeyPart.fromJson(String category, Map<String, dynamic> json) {
    final modes = ((json['modes'] as List?) ?? const [])
        .whereType<Map>()
        .map((mode) => _statsFromJson(Map<String, dynamic>.from(mode)))
        .toList();
    final modeLabels = ((json['modes'] as List?) ?? const [])
        .whereType<Map>()
        .map((mode) => (mode['label'] ?? 'Mode').toString())
        .toList();
    final fallbackStats = modes.isNotEmpty ? modes.first : _statsFromJson(json);
    final name = (json['name'] ?? 'Unknown').toString();
    return BeyPart(
      id: '${category}_${_slug(name)}',
      category: category,
      name: name,
      alias: json['alias']?.toString(),
      type: (json['type'] ?? 'balance').toString(),
      line: (json['line'] ?? '').toString(),
      image: json['image']?.toString(),
      spinType: json['spinType']?.toString(),
      integratedRatchet: json['integratedRatchet']?.toString(),
      description: json['description']?.toString(),
      source: ((json['source'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      stats: fallbackStats,
      modes: modes,
      modeLabels: modeLabels,
    );
  }

  factory BeyPart.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final category = (data['category'] ?? 'blades').toString();
    final stats = _statsFromJson(
      Map<String, dynamic>.from(data['stats'] as Map? ?? data),
    );
    return BeyPart(
      id: doc.id,
      category: category,
      name: (data['name'] ?? 'Custom Part').toString(),
      alias: data['alias']?.toString(),
      type: (data['type'] ?? 'balance').toString(),
      line: (data['line'] ?? '').toString(),
      image: data['image']?.toString(),
      spinType: data['spinType']?.toString(),
      integratedRatchet: data['integratedRatchet']?.toString(),
      description: data['description']?.toString(),
      source: ((data['source'] as List?) ?? const ['Admin'])
          .map((item) => item.toString())
          .toList(),
      stats: stats,
    );
  }
}

class BeyPartsCatalog {
  final List<BeyPart> blades;
  final List<BeyPart> assistBlades;
  final List<BeyPart> ratchets;
  final List<BeyPart> bits;
  final List<BeyPart> lockChips;
  final List<BeyPart> overBlades;

  const BeyPartsCatalog({
    required this.blades,
    required this.assistBlades,
    required this.ratchets,
    required this.bits,
    required this.lockChips,
    required this.overBlades,
  });

  static Future<BeyPartsCatalog> load() async {
    final raw = await rootBundle.loadString('assets/data/beyparts.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    List<BeyPart> list(String key) {
      return ((json[key] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => BeyPart.fromJson(key, Map<String, dynamic>.from(item)))
          .toList();
    }

    return BeyPartsCatalog(
      blades: list('blades'),
      assistBlades: list('assist_blades'),
      ratchets: list('ratchets'),
      bits: list('bits'),
      lockChips: list('lock_chips'),
      overBlades: list('over_blades'),
    );
  }

  BeyPartsCatalog merge(Iterable<BeyPart> adminParts) {
    final nextBlades = [...blades];
    final nextAssistBlades = [...assistBlades];
    final nextRatchets = [...ratchets];
    final nextBits = [...bits];
    final nextLockChips = [...lockChips];
    final nextOverBlades = [...overBlades];

    void upsert(List<BeyPart> list, BeyPart part) {
      final index = list.indexWhere((item) => item.id == part.id);
      if (index >= 0) {
        list[index] = part;
      } else {
        list.add(part);
      }
    }

    for (final part in adminParts) {
      switch (part.category) {
        case 'assist_blades':
          upsert(nextAssistBlades, part);
        case 'ratchets':
          upsert(nextRatchets, part);
        case 'bits':
          upsert(nextBits, part);
        case 'lock_chips':
          upsert(nextLockChips, part);
        case 'over_blades':
          upsert(nextOverBlades, part);
        case 'blades':
        default:
          upsert(nextBlades, part);
      }
    }

    return BeyPartsCatalog(
      blades: nextBlades,
      assistBlades: nextAssistBlades,
      ratchets: nextRatchets,
      bits: nextBits,
      lockChips: nextLockChips,
      overBlades: nextOverBlades,
    );
  }

  List<BeyPart> bySlot(DeckSlot slot) {
    return switch (slot) {
      DeckSlot.blade => blades,
      DeckSlot.assistBlade => assistBlades,
      DeckSlot.overBlade => overBlades,
      DeckSlot.lockChip => lockChips,
      DeckSlot.ratchet => ratchets,
      DeckSlot.bit => bits,
    };
  }

  BeyPart? find(String id) {
    for (final part in [
      ...blades,
      ...assistBlades,
      ...overBlades,
      ...lockChips,
      ...ratchets,
      ...bits,
    ]) {
      if (part.id == id) return part;
    }
    return null;
  }

  BeyPart? findByName(String name, {String? category}) {
    final target = _normalizePartLookup(name);
    if (target.isEmpty) return null;
    final normalizedCategory = category?.trim();
    for (final part in [
      ...blades,
      ...assistBlades,
      ...overBlades,
      ...lockChips,
      ...ratchets,
      ...bits,
    ]) {
      if (normalizedCategory != null &&
          normalizedCategory.isNotEmpty &&
          part.category != normalizedCategory) {
        continue;
      }
      if (_normalizePartLookup(part.name) == target ||
          _normalizePartLookup(part.alias ?? '') == target) {
        return part;
      }
    }
    return null;
  }

  BeyPart? integratedRatchetForBit(BeyPart bit) {
    if (bit.name == 'Turbo') {
      return ratchets
          .where((part) => part.name.startsWith('Turbo'))
          .firstOrNull;
    }
    if (bit.name == 'Operate') {
      return ratchets
          .where((part) => part.name.startsWith('Operate'))
          .firstOrNull;
    }
    return null;
  }

  BeyPart? integratedRatchetForBlade(BeyPart blade) {
    if (blade.integratedRatchet == null) return null;
    return ratchets
        .where((part) => part.name == blade.integratedRatchet)
        .firstOrNull;
  }
}

enum DeckSlot {
  blade,
  assistBlade,
  overBlade,
  lockChip,
  ratchet,
  bit,
}

extension DeckSlotLabel on DeckSlot {
  String get label {
    return switch (this) {
      DeckSlot.blade => 'Blade',
      DeckSlot.assistBlade => 'Assist',
      DeckSlot.overBlade => 'Over',
      DeckSlot.lockChip => 'Lock',
      DeckSlot.ratchet => 'Ratchet',
      DeckSlot.bit => 'Bit',
    };
  }
}

class DeckComboDraft {
  final String? bladeId;
  final String? assistBladeId;
  final String? overBladeId;
  final String? lockChipId;
  final String? ratchetId;
  final String? bitId;

  const DeckComboDraft({
    this.bladeId,
    this.assistBladeId,
    this.overBladeId,
    this.lockChipId,
    this.ratchetId,
    this.bitId,
  });

  String? valueFor(DeckSlot slot) {
    return switch (slot) {
      DeckSlot.blade => bladeId,
      DeckSlot.assistBlade => assistBladeId,
      DeckSlot.overBlade => overBladeId,
      DeckSlot.lockChip => lockChipId,
      DeckSlot.ratchet => ratchetId,
      DeckSlot.bit => bitId,
    };
  }

  DeckComboDraft copyWithSlot(DeckSlot slot, String? value) {
    return switch (slot) {
      DeckSlot.blade => DeckComboDraft(
          bladeId: value,
          ratchetId: ratchetId,
          bitId: bitId,
        ),
      DeckSlot.assistBlade => DeckComboDraft(
          bladeId: bladeId,
          assistBladeId: value,
          overBladeId: overBladeId,
          lockChipId: lockChipId,
          ratchetId: ratchetId,
          bitId: bitId,
        ),
      DeckSlot.overBlade => DeckComboDraft(
          bladeId: bladeId,
          assistBladeId: assistBladeId,
          overBladeId: value,
          lockChipId: lockChipId,
          ratchetId: ratchetId,
          bitId: bitId,
        ),
      DeckSlot.lockChip => DeckComboDraft(
          bladeId: bladeId,
          assistBladeId: assistBladeId,
          overBladeId: overBladeId,
          lockChipId: value,
          ratchetId: ratchetId,
          bitId: bitId,
        ),
      DeckSlot.ratchet => DeckComboDraft(
          bladeId: bladeId,
          assistBladeId: assistBladeId,
          overBladeId: overBladeId,
          lockChipId: lockChipId,
          ratchetId: value,
          bitId: bitId,
        ),
      DeckSlot.bit => DeckComboDraft(
          bladeId: bladeId,
          assistBladeId: assistBladeId,
          overBladeId: overBladeId,
          lockChipId: lockChipId,
          ratchetId: ratchetId,
          bitId: value,
        ),
    };
  }

  DeckComboDraft copyWith({
    String? bladeId,
    String? assistBladeId,
    String? overBladeId,
    String? lockChipId,
    String? ratchetId,
    String? bitId,
    bool clearCxParts = false,
  }) {
    return DeckComboDraft(
      bladeId: bladeId ?? this.bladeId,
      assistBladeId: clearCxParts ? null : assistBladeId ?? this.assistBladeId,
      overBladeId: clearCxParts ? null : overBladeId ?? this.overBladeId,
      lockChipId: clearCxParts ? null : lockChipId ?? this.lockChipId,
      ratchetId: ratchetId ?? this.ratchetId,
      bitId: bitId ?? this.bitId,
    );
  }

  List<String> selectedIds() {
    return [
      bladeId,
      assistBladeId,
      overBladeId,
      lockChipId,
      ratchetId,
      bitId,
    ].whereType<String>().toList();
  }
}

PartStats comboStats(BeyPartsCatalog catalog, DeckComboDraft combo) {
  var stats = const PartStats();
  for (final id in combo.selectedIds()) {
    stats = stats + (catalog.find(id)?.stats ?? const PartStats());
  }
  return stats;
}

List<String> validateDeck(
    BeyPartsCatalog catalog, List<DeckComboDraft> combos) {
  final issues = <String>[];
  final seen = <String, int>{};
  for (var i = 0; i < combos.length; i++) {
    final combo = combos[i];
    final blade = combo.bladeId == null ? null : catalog.find(combo.bladeId!);
    final bit = combo.bitId == null ? null : catalog.find(combo.bitId!);
    final ratchet =
        combo.ratchetId == null ? null : catalog.find(combo.ratchetId!);
    final cx = blade?.isCx ?? false;

    if (blade == null) issues.add('Kombo ${i + 1}: Blade belum dipilih.');
    if (bit == null) issues.add('Kombo ${i + 1}: Bit belum dipilih.');
    if (ratchet == null) issues.add('Kombo ${i + 1}: Ratchet belum dipilih.');
    if (cx && combo.assistBladeId == null) {
      issues.add('Kombo ${i + 1}: CX wajib memilih Assist Blade.');
    }
    if (cx && combo.lockChipId == null) {
      issues.add('Kombo ${i + 1}: CX wajib memilih Lock Chip.');
    }
    if (!cx && (combo.assistBladeId != null || combo.lockChipId != null)) {
      issues.add('Kombo ${i + 1}: Assist/Lock hanya aktif untuk Blade CX.');
    }
    if (bit != null &&
        (bit.name == 'Turbo' || bit.name == 'Operate') &&
        !(ratchet?.name.startsWith(bit.name) ?? false)) {
      issues.add('Kombo ${i + 1}: ${bit.name} memakai ratchet integrated.');
    }
    if (blade != null &&
        blade.integratedRatchet != null &&
        ratchet?.name != blade.integratedRatchet) {
      issues.add('Kombo ${i + 1}: ${blade.name} memakai ratchet integrated.');
    }

    for (final id in combo.selectedIds()) {
      seen[id] = (seen[id] ?? 0) + 1;
    }
  }

  for (final entry in seen.entries.where((entry) => entry.value > 1)) {
    final part = catalog.find(entry.key);
    issues.add(
        'Duplicate part: ${part?.name ?? entry.key} dipakai lebih dari sekali.');
  }
  return issues;
}

PartStats _statsFromJson(Map<String, dynamic> json) {
  int read(String key) {
    final value = json[key];
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  return PartStats(
    attack: read('attack'),
    defense: read('defense'),
    stamina: read('stamina'),
    xDash: read('xDash'),
    burstResistance: read('burstResistance'),
  );
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String _normalizePartLookup(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

bool _isNetworkImage(String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}
