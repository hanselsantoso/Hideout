# HIDEOUT Flutter Implementation — Prompt untuk Claude Code

Paste prompt ini ke Claude Code beserta file-file yang ada di folder ini.

---

## Konteks

Saya sedang mengganti tampilan Flutter app saya dengan design system HIDEOUT (dark theme,
Oswald + JetBrains Mono + Inter fonts, skema warna ungu #9B4FA3). Saya punya:

- Flutter 3.3+
- State management: Riverpod 2.x
- Navigasi/routing sudah jalan

Saya ingin kamu mengintegrasikan file-file berikut ke dalam project Flutter saya yang sudah ada:

---

## File yang Perlu Diintegrasikan

### 1. Core/Theme
- `lib/core/theme/hideout_tokens.dart` → Design tokens (warna, tipografi, spacing, radius)
- `lib/core/theme/hideout_theme.dart`  → ThemeData lengkap, pasang ke `MaterialApp(theme: HDTTheme.dark)`

### 2. Core/Widgets
- `lib/core/widgets/hdt_widgets.dart`  → Semua shared widgets:
  - `HDTPagination`      — pagination bar dengan page numbers
  - `HDTResultBadge`     — badge WIN/LOSS
  - `HDTEloChip`         — +24 / -8 berwarna
  - `HDTDeckClassBadge`  — RUSHER/STAMINA/DEFENDER/BALANCE
  - `HDTGameBadge`       — BURST/OVER/SPIN/LOSS
  - `HDTStatCard`        — stat summary card
  - `HDTFilterChip`      — toggle filter chip
  - `HDTSearchField`     — search input
  - `HDTStatusBadge`     — LIVE/UPCOMING/COMPLETED
  - `HDTTierBadge`       — PREMIER/STANDARD/CASUAL
  - `HDTDateRangeBar`    — filter rentang tanggal dengan presets
  - `HDTResultFormStrip` — deretan kotak hijau/merah form strip
  - `HDTEmptyState`      — placeholder kosong
  - `HDTCardContainer`   — wrapper card standar

### 3. Features/Screens
- `lib/features/matches/match_history_screen.dart`
  - `MatchHistoryScreen` widget
  - `MatchRecord` model
  - `matchHistoryProvider` (NotifierProvider)
  - Filter: tanggal preset/kustom, WIN/LOSS, search
  - Expandable row → deck vs deck + game-by-game
  - Pagination 10/halaman

- `lib/features/leaderboard/leaderboard_screen.dart`
  - `LeaderboardScreen` widget
  - `PlayerEntry` model
  - `leaderboardProvider`
  - Podium top 3 + tabel dengan pagination 10/halaman

- `lib/features/tournaments/tournaments_screen.dart`
  - `TournamentsScreen` widget
  - `TournamentEntry` model
  - `tournamentProvider`
  - Filter tier/status/kota + pagination 6/halaman

- `lib/features/notifications/notifications_screen.dart`
  - `NotificationsScreen` widget
  - `NotifItem` model
  - `notificationProvider`
  - Filter tipe + pagination 6/halaman

---

## Dependencies yang Perlu Ditambahkan ke pubspec.yaml

```yaml
dependencies:
  flutter_riverpod: ^2.4.0   # atau versi terbaru
  riverpod_annotation: ^2.3.0
  google_fonts: ^6.1.0
  intl: ^0.19.0

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```

---

## Langkah Integrasi

### Step 1 — Tambah dependencies
```bash
flutter pub add flutter_riverpod google_fonts intl
```

### Step 2 — Wrap MaterialApp dengan ProviderScope
```dart
// main.dart
void main() {
  runApp(const ProviderScope(child: HideoutApp()));
}

class HideoutApp extends StatelessWidget {
  const HideoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HIDEOUT',
      theme: HDTTheme.dark,
      darkTheme: HDTTheme.dark,
      themeMode: ThemeMode.dark,
      // ... routes kamu yang sudah ada
    );
  }
}
```

### Step 3 — Copy file-file ke project
Salin semua file dari folder `flutter/lib/` ke folder `lib/` project Flutter kamu.

### Step 4 — Sesuaikan routing
Tambahkan route untuk setiap screen baru ke router yang sudah ada:
```dart
// Contoh dengan GoRouter:
GoRoute(path: '/matches',       builder: (_, __) => const MatchHistoryScreen()),
GoRoute(path: '/leaderboard',   builder: (_, __) => const LeaderboardScreen()),
GoRoute(path: '/tournaments',   builder: (_, __) => const TournamentsScreen()),
GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),

// Contoh dengan Navigator:
'/matches':       (context) => const MatchHistoryScreen(),
'/leaderboard':   (context) => const LeaderboardScreen(),
'/tournaments':   (context) => const TournamentsScreen(),
'/notifications': (context) => const NotificationsScreen(),
```

### Step 5 — Ganti AppShell navigasi kamu
Sidebar/bottom nav yang sudah ada: ubah warna dan style menggunakan token dari `HDTColors`.

Contoh bottom nav yang sudah pakai theme baru (theme sudah handle otomatis):
```dart
BottomNavigationBar(
  // NavigationBar M3 lebih dianjurkan:
  // background, selected/unselected sudah diset di HDTTheme
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
    BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'TURNAMEN'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'LEADERBOARD'),
    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'NOTIFIKASI'),
  ],
)
```

---

## Catatan Penting untuk Claude Code

1. **Jangan ubah logika business/routing yang sudah ada** — hanya ganti UI dan theme

2. **ConsumerWidget** — semua screen yang pakai Riverpod sudah extends `ConsumerWidget`.
   Kalau screen yang sudah ada masih `StatefulWidget`, wrap saja atau jadikan `ConsumerStatefulWidget`.

3. **Font loading** — `google_fonts` auto-download. Kalau mau offline, tambahkan font asset
   ke `pubspec.yaml` dan gunakan `GoogleFonts.config.allowRuntimeFetching = false`.

4. **Warna di theme** — `HDTColors.bg`, `HDTColors.s1`, dll bisa dipakai langsung tanpa
   `Theme.of(context)`. Tapi untuk widget yang ikut Material theme, gunakan `Theme.of(context).colorScheme`.

5. **Import path** — Sesuaikan package name. Ganti `your_app` dengan nama package Flutter kamu:
   ```dart
   // Cari-ganti di semua file:
   import 'package:your_app/core/theme/...'
   // → ganti dengan:
   import 'package:nama_package_kamu/core/theme/...'
   ```

6. **Mock data** → **API real** — Data di setiap screen masih hardcoded. Untuk koneksi ke
   backend nyata, buat `AsyncNotifierProvider` dan fetch dari API. Struktur model sudah siap.

---

## Struktur Folder Setelah Integrasi

```
lib/
├── core/
│   ├── theme/
│   │   ├── hideout_tokens.dart   ← Design tokens
│   │   └── hideout_theme.dart    ← ThemeData
│   └── widgets/
│       └── hdt_widgets.dart      ← Shared widgets
├── features/
│   ├── matches/
│   │   └── match_history_screen.dart
│   ├── leaderboard/
│   │   └── leaderboard_screen.dart
│   ├── tournaments/
│   │   └── tournaments_screen.dart
│   └── notifications/
│       └── notifications_screen.dart
└── main.dart
```

---

## Warna Reference (untuk widget yang belum dimigrasi)

| Token CSS (React)    | Dart Constant          | Hex       |
|----------------------|------------------------|-----------|
| `--bjx-bg`           | `HDTColors.bg`         | `#0F1115` |
| `--bjx-s1`           | `HDTColors.s1`         | `#181B21` |
| `--bjx-s2`           | `HDTColors.s2`         | `#23282F` |
| `--bjx-accent`       | `HDTColors.accent`     | `#9B4FA3` |
| `--bjx-accent-hover` | `HDTColors.accentHover`| `#BB6FC3` |
| `--bjx-text`         | `HDTColors.text`       | `#F1F3F7` |
| `--bjx-text-2`       | `HDTColors.text2`      | `#8B95A5` |
| `--bjx-text-3`       | `HDTColors.text3`      | `#4A5568` |
| `--bjx-success`      | `HDTColors.success`    | `#4ADE80` |
| `--bjx-danger`       | `HDTColors.danger`     | `#F87171` |
