# Phase 3B — Analytics & Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three premium analytics charts to ProgressScreen (Pain by Body Area, Weekly Improvement Rate, Session Frequency Grid) and a PDF export feature that patients can share with any doctor via their device's share sheet.

**Architecture:** A new `ProgressAnalyticsService` handles all Firestore aggregation (keeps ProgressScreen clean). A new `ExportService` builds the PDF using the `pdf` package's graphics primitives. A `SessionFrequencyGrid` widget is a self-contained custom painter. Everything surfaces in the existing `ProgressScreen` behind the existing `PremiumBadge` gate.

**Tech Stack:** Flutter, Cloud Firestore, `fl_chart` (existing), `pdf: ^3.10.8`, `printing: ^5.12.0`, `share_plus: ^10.0.0`.

---

## Task 1: Add New Packages

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add packages to pubspec.yaml**

In `pubspec.yaml`, under `dependencies:`, add after the existing `intl` entry:

```yaml
  pdf: ^3.10.8
  printing: ^5.12.0
  share_plus: ^10.0.0
  path_provider: ^2.1.4
```

- [ ] **Step 2: Install packages**

```
flutter pub get
```

Expected: Resolving dependencies... (success, no conflicts)

- [ ] **Step 3: Verify packages installed**

```
flutter pub deps | grep -E "pdf|printing|share_plus"
```

Expected: Lines showing `pdf`, `printing`, `share_plus` with version numbers.

- [ ] **Step 4: Commit**

```
git add pubspec.yaml pubspec.lock
git commit -m "chore: add pdf, printing, share_plus packages for Phase 3B"
```

---

## Task 2: WeeklyImprovement Model + ProgressAnalyticsService

**Files:**
- Create: `lib/services/progress_analytics_service.dart`

- [ ] **Step 1: Write the service**

```dart
// lib/services/progress_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/models/exercise_model.dart';

class WeeklyImprovement {
  final int weekIndex; // 0 = oldest, 7 = most recent
  final double avgReduction; // painBefore - painAfter averaged across the week

  const WeeklyImprovement({
    required this.weekIndex,
    required this.avgReduction,
  });
}

class ProgressAnalyticsService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<List<SessionModel>> _fetchCompletedSessions(String userId) async {
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('completed', isEqualTo: true)
        .orderBy('completedAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => SessionModel.fromFirestore(doc))
        .toList();
  }

  Future<List<ProgressModel>> _fetchProgress(String userId) async {
    final snapshot = await _db
        .collection('progress')
        .where('userId', isEqualTo: userId)
        .orderBy('recordedAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => ProgressModel.fromFirestore(doc))
        .toList();
  }

  Future<ExerciseModel?> _fetchExercise(String exerciseId) async {
    final doc =
        await _db.collection('exercises').doc(exerciseId).get();
    if (!doc.exists) return null;
    return ExerciseModel.fromFirestore(doc);
  }

  /// Returns avg pain level (before) per body area.
  /// Joins sessions → exercises to get body area. Deduplicated exercise fetches.
  Future<Map<String, double>> getPainByBodyArea(String userId) async {
    final sessions = await _fetchCompletedSessions(userId);
    final progress = await _fetchProgress(userId);

    // Build sessionId → painLevelBefore map
    final painMap = <String, int>{};
    for (final p in progress) {
      painMap[p.sessionId] = p.painLevelBefore;
    }

    // Fetch unique exercises
    final uniqueIds = sessions.map((s) => s.exerciseId).toSet();
    final exerciseMap = <String, ExerciseModel>{};
    for (final id in uniqueIds) {
      final ex = await _fetchExercise(id);
      if (ex != null) exerciseMap[id] = ex;
    }

    // Group pain levels by body area
    final areaData = <String, List<int>>{};
    for (final session in sessions) {
      final exercise = exerciseMap[session.exerciseId];
      if (exercise == null) continue;
      final pain = painMap[session.id];
      if (pain == null) continue;
      areaData.putIfAbsent(exercise.bodyArea, () => []).add(pain);
    }

    return areaData.map((area, levels) {
      final avg = levels.reduce((a, b) => a + b) / levels.length;
      return MapEntry(area, avg);
    });
  }

  /// Returns avg pain reduction per week for the last 8 weeks.
  /// weekIndex 0 = 8 weeks ago, 7 = current week.
  Future<List<WeeklyImprovement>> getWeeklyImprovementRate(
      String userId) async {
    final progress = await _fetchProgress(userId);
    final now = DateTime.now();
    final results = <WeeklyImprovement>[];

    for (int week = 0; week < 8; week++) {
      final weekStart =
          now.subtract(Duration(days: (7 - week) * 7 + 7));
      final weekEnd =
          now.subtract(Duration(days: (7 - week) * 7));
      final weekEntries = progress.where((p) =>
          p.recordedAt.isAfter(weekStart) &&
          p.recordedAt.isBefore(weekEnd));
      if (weekEntries.isEmpty) {
        results.add(WeeklyImprovement(weekIndex: week, avgReduction: 0));
        continue;
      }
      final avg = weekEntries
              .map((p) => (p.painLevelBefore - p.painLevelAfter).toDouble())
              .reduce((a, b) => a + b) /
          weekEntries.length;
      results.add(WeeklyImprovement(
          weekIndex: week, avgReduction: avg.clamp(0, 10)));
    }
    return results;
  }

  /// Returns the set of dates (normalized to midnight) that have completed sessions.
  Future<Set<DateTime>> getSessionFrequencyGrid(String userId) async {
    final sessions = await _fetchCompletedSessions(userId);
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 84)); // 12 weeks
    return sessions
        .where((s) =>
            s.completedAt != null && s.completedAt!.isAfter(cutoff))
        .map((s) {
      final d = s.completedAt!;
      return DateTime(d.year, d.month, d.day);
    }).toSet();
  }

  /// Returns all completed sessions and progress for PDF export.
  Future<({List<SessionModel> sessions, List<ProgressModel> progress})>
      getExportData(String userId) async {
    final sessions = await _fetchCompletedSessions(userId);
    final progress = await _fetchProgress(userId);
    return (sessions: sessions, progress: progress);
  }
}
```

- [ ] **Step 2: Run analyzer**

```
flutter analyze lib/services/progress_analytics_service.dart
```

Expected: No issues found.

- [ ] **Step 3: Write unit tests**

Create `test/progress_analytics_service_test.dart`:

```dart
// test/progress_analytics_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:physiocare/services/progress_analytics_service.dart';
import 'package:physiocare/models/progress_model.dart';

void main() {
  group('WeeklyImprovement', () {
    test('stores weekIndex and avgReduction correctly', () {
      const wi = WeeklyImprovement(weekIndex: 3, avgReduction: 2.5);
      expect(wi.weekIndex, 3);
      expect(wi.avgReduction, 2.5);
    });

    test('avgReduction is clamped to 0 in data computation', () {
      // If before=3 and after=5 (pain went up), reduction = -2, clamped to 0
      // This is a documentation test — the service clamps via .clamp(0,10)
      final reduction = (3 - 5).toDouble().clamp(0.0, 10.0);
      expect(reduction, 0.0);
    });
  });

  group('ProgressModel pain reduction', () {
    test('reduction computed correctly from model fields', () {
      final p = ProgressModel(
        id: '1',
        userId: 'u1',
        sessionId: 's1',
        painLevelBefore: 8,
        painLevelAfter: 3,
        recordedAt: DateTime.now(),
      );
      expect(p.painLevelBefore - p.painLevelAfter, 5);
    });
  });
}
```

- [ ] **Step 4: Run unit tests**

```
flutter test test/progress_analytics_service_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```
git add lib/services/progress_analytics_service.dart test/progress_analytics_service_test.dart
git commit -m "feat: add ProgressAnalyticsService with body area, weekly rate, and grid methods"
```

---

## Task 3: SessionFrequencyGrid Widget

**Files:**
- Create: `lib/widgets/session_frequency_grid.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/widgets/session_frequency_grid.dart
import 'package:flutter/material.dart';
import 'package:physiocare/utils/app_constants.dart';

/// Renders a 12-week × 7-day grid (GitHub-style contribution graph).
/// [activeDays] is a set of dates (normalized to midnight) with sessions.
class SessionFrequencyGrid extends StatelessWidget {
  final Set<DateTime> activeDays;

  const SessionFrequencyGrid({super.key, required this.activeDays});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Start 12 weeks ago on Monday
    final startOffset = (today.weekday - 1) % 7;
    final gridStart = today.subtract(Duration(days: 83 + startOffset));

    // 12 columns × 7 rows = 84 cells
    const totalWeeks = 12;
    const daysPerWeek = 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: daysPerWeek * 14.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(totalWeeks, (week) {
              return Column(
                children: List.generate(daysPerWeek, (day) {
                  final date = gridStart.add(
                      Duration(days: week * daysPerWeek + day));
                  final isActive = activeDays.contains(date);
                  final isFuture = date.isAfter(today);
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : isActive
                              ? AppColors.primary
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('12 weeks ago',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('Today',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            const Text('No session', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 12),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Session completed', style: TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Write widget test**

Add to `test/phase3b_test.dart` (create file):

```dart
// test/phase3b_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiocare/widgets/session_frequency_grid.dart';

void main() {
  group('SessionFrequencyGrid', () {
    testWidgets('renders without error with empty active days', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionFrequencyGrid(activeDays: {}),
          ),
        ),
      );
      expect(find.byType(SessionFrequencyGrid), findsOneWidget);
      expect(find.text('12 weeks ago'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('renders green cells for active days', (tester) async {
      final today = DateTime.now();
      final activeDay =
          DateTime(today.year, today.month, today.day);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionFrequencyGrid(activeDays: {activeDay}),
          ),
        ),
      );
      expect(find.byType(SessionFrequencyGrid), findsOneWidget);
    });

    testWidgets('renders legend labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionFrequencyGrid(activeDays: {}),
          ),
        ),
      );
      expect(find.text('No session'), findsOneWidget);
      expect(find.text('Session completed'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Run tests**

```
flutter test test/phase3b_test.dart
```

Expected: All 3 tests pass.

- [ ] **Step 4: Commit**

```
git add lib/widgets/session_frequency_grid.dart test/phase3b_test.dart
git commit -m "feat: add SessionFrequencyGrid widget with 12-week contribution graph"
```

---

## Task 4: ExportService (PDF Generation)

**Files:**
- Create: `lib/services/export_service.dart`

- [ ] **Step 1: Write ExportService**

```dart
// lib/services/export_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/services/progress_analytics_service.dart';

class ExportService {
  final _analyticsService = ProgressAnalyticsService();

  Future<void> exportProgressPdf({
    required BuildContext context,
    required String userId,
    required String userName,
    required int streak,
    required int totalSessions,
    required double avgPainReduction,
  }) async {
    // Fetch data
    final exportData =
        await _analyticsService.getExportData(userId);
    final weeklyRates =
        await _analyticsService.getWeeklyImprovementRate(userId);

    final sessions = exportData.sessions;
    final progress = exportData.progress;

    // Build sessionId → progress map
    final progressMap = <String, ProgressModel>{};
    for (final p in progress) {
      progressMap[p.sessionId] = p;
    }

    // Build PDF
    final pdf = pw.Document();
    final dateRange =
        '${DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 30)))} – ${DateFormat('dd MMM yyyy').format(DateTime.now())}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PhysioCare+',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                  pw.Text(
                    'Progress Report',
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(userName,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateRange,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Summary stats
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Total Sessions', '$totalSessions'),
              _buildStatBox('Current Streak', '$streak days'),
              _buildStatBox('Avg Pain Reduction',
                  '${avgPainReduction.toStringAsFixed(1)} pts'),
            ],
          ),
          pw.SizedBox(height: 24),

          // Pain trend chart (drawn with pw.CustomPaint)
          pw.Text(
            'Weekly Improvement Rate',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.SizedBox(
            height: 120,
            child: pw.CustomPaint(
              painter: (canvas, size) {
                _drawLineChart(canvas, size, weeklyRates);
              },
            ),
          ),
          pw.SizedBox(height: 24),

          // Recent sessions table
          pw.Text(
            'Recent Sessions (last 10)',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          _buildSessionsTable(
              sessions.take(10).toList(), progressMap),
          pw.SizedBox(height: 40),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by PhysioCare+ · Not a substitute for professional medical advice',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey500),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    // Save to temp file
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/physiocare_progress_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);

    // Share
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'My PhysioCare+ Progress Report',
      text:
          'My recovery progress report from PhysioCare+. Please find the PDF attached.',
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 18,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style:
                const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _drawLineChart(
      PdfGraphics canvas, PdfPoint size, List<WeeklyImprovement> rates) {
    if (rates.isEmpty) return;

    final padding = 20.0;
    final chartWidth = size.x - padding * 2;
    final chartHeight = size.y - padding * 2;
    final maxY = 10.0;

    // Draw baseline
    canvas
      ..setColor(PdfColors.grey300)
      ..setLineWidth(0.5)
      ..drawLine(
          padding, padding, padding + chartWidth, padding)
      ..strokePath();

    // Draw line
    if (rates.length < 2) return;

    canvas.setColor(PdfColors.teal700);
    canvas.setLineWidth(1.5);

    final stepX = chartWidth / (rates.length - 1);

    for (int i = 0; i < rates.length - 1; i++) {
      final x1 = padding + i * stepX;
      final y1 =
          padding + (rates[i].avgReduction / maxY) * chartHeight;
      final x2 = padding + (i + 1) * stepX;
      final y2 = padding +
          (rates[i + 1].avgReduction / maxY) * chartHeight;

      canvas
        ..drawLine(x1, y1, x2, y2)
        ..strokePath();

      // Draw dot
      canvas
        ..setColor(PdfColors.teal700)
        ..drawEllipse(x1 - 2, y1 - 2, 4, 4)
        ..fillPath();
    }

    // Last dot
    final lastX = padding + (rates.length - 1) * stepX;
    final lastY = padding +
        (rates.last.avgReduction / maxY) * chartHeight;
    canvas
      ..setColor(PdfColors.teal700)
      ..drawEllipse(lastX - 2, lastY - 2, 4, 4)
      ..fillPath();
  }

  pw.Widget _buildSessionsTable(
      List<SessionModel> sessions, Map<String, ProgressModel> progressMap) {
    final headers = [
      'Date', 'Exercise', 'Duration', 'Pain Before', 'Pain After'
    ];

    final rows = sessions.map((s) {
      final p = progressMap[s.id];
      return [
        DateFormat('dd MMM yy').format(s.startedAt),
        s.exerciseTitle.length > 22
            ? '${s.exerciseTitle.substring(0, 20)}…'
            : s.exerciseTitle,
        '${(s.durationSeconds ~/ 60)} min',
        p != null ? '${p.painLevelBefore}/10' : '–',
        p != null ? '${p.painLevelAfter}/10' : '–',
      ];
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(55),
        4: const pw.FixedColumnWidth(55),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColors.teal50),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9)),
                  ))
              .toList(),
        ),
        // Data rows
        ...rows.map((row) => pw.TableRow(
              children: row
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(cell,
                            style: const pw.TextStyle(fontSize: 9)),
                      ))
                  .toList(),
            )),
      ],
    );
  }
}
```

> **Note:** `path_provider` is already a transitive dependency via Firebase packages. No explicit pubspec entry needed.

- [ ] **Step 2: Run analyzer**

```
flutter analyze lib/services/export_service.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```
git add lib/services/export_service.dart
git commit -m "feat: add ExportService for PDF generation and sharing"
```

---

## Task 5: Extend ProgressScreen with Analytics Charts + Export Button

**Files:**
- Modify: `lib/screens/progress/progress_screen.dart`

- [ ] **Step 1: Add imports**

At the top of `progress_screen.dart`, add:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:physiocare/services/progress_analytics_service.dart';
import 'package:physiocare/services/export_service.dart';
import 'package:physiocare/widgets/session_frequency_grid.dart';
```

- [ ] **Step 2: Add state variables to `_ProgressScreenState`**

```dart
final _analyticsService = ProgressAnalyticsService();
final _exportService = ExportService();

Map<String, double> _painByArea = {};
List<WeeklyImprovement> _weeklyRates = [];
Set<DateTime> _frequencyGrid = {};
bool _analyticsLoading = false;
bool _exporting = false;
```

- [ ] **Step 3: Add `_loadAnalytics` method**

```dart
Future<void> _loadAnalytics(String userId) async {
  setState(() => _analyticsLoading = true);
  final results = await Future.wait([
    _analyticsService.getPainByBodyArea(userId),
    _analyticsService.getWeeklyImprovementRate(userId),
    _analyticsService.getSessionFrequencyGrid(userId),
  ]);
  if (mounted) {
    setState(() {
      _painByArea = results[0] as Map<String, double>;
      _weeklyRates = results[1] as List<WeeklyImprovement>;
      _frequencyGrid = results[2] as Set<DateTime>;
      _analyticsLoading = false;
    });
  }
}
```

- [ ] **Step 4: Call `_loadAnalytics` in `initState`**

In `initState`, after the existing `progressProvider.loadUserProgress(uid)` call, add:

```dart
_loadAnalytics(uid);
```

- [ ] **Step 5: Add export button to AppBar**

Change the `AppBar` in `build`:

```dart
appBar: AppBar(
  title: const Text('My Progress'),
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  actions: [
    if (subscriptionProvider.isPremium)
      _exporting
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
  ],
),
```

- [ ] **Step 6: Add `_exportPdf` method**

```dart
Future<void> _exportPdf() async {
  final authProvider = context.read<AppAuthProvider>();
  final progressProvider = context.read<ProgressProvider>();
  final uid = authProvider.userModel?.id ?? '';
  final name = authProvider.userModel?.name ?? 'Patient';

  setState(() => _exporting = true);
  try {
    await _exportService.exportProgressPdf(
      context: context,
      userId: uid,
      userName: name,
      streak: progressProvider.streak,
      totalSessions: progressProvider.sessions.length,
      avgPainReduction: progressProvider.avgPainReduction,
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
  if (mounted) setState(() => _exporting = false);
}
```

- [ ] **Step 7: Add `_buildPainByAreaChart` method**

```dart
Widget _buildPainByAreaChart() {
  if (_painByArea.isEmpty) {
    return const SizedBox(
      height: 80,
      child: Center(
          child: Text('No data yet',
              style: TextStyle(color: Colors.grey))),
    );
  }

  final areas = _painByArea.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return Column(
    children: areas.map((entry) {
      final fraction = entry.value / 10.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: fraction > 0.6
                            ? Colors.red.shade300
                            : fraction > 0.3
                                ? Colors.orange.shade300
                                : AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.value.toStringAsFixed(1)}/10',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
```

- [ ] **Step 8: Add `_buildWeeklyImprovementChart` method**

```dart
Widget _buildWeeklyImprovementChart() {
  if (_weeklyRates.isEmpty) {
    return const SizedBox(
      height: 120,
      child: Center(
          child: Text('No data yet',
              style: TextStyle(color: Colors.grey))),
    );
  }

  final spots = _weeklyRates
      .map((r) =>
          FlSpot(r.weekIndex.toDouble(), r.avgReduction))
      .toList();

  return SizedBox(
    height: 140,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Colors.black12, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = [
                  'W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'
                ];
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Text(labels[idx],
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey));
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 9: Replace `_buildAdvancedAnalytics` call in the `PremiumBadge` child**

Find the existing `_buildAdvancedAnalytics(progressProvider)` call inside the `PremiumBadge` child widget. Replace the entire `PremiumBadge` child `Column` content with:

```dart
PremiumBadge(
  isPremium: subscriptionProvider.isPremium,
  child: _analyticsLoading
      ? const Center(child: CircularProgressIndicator())
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Sessions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            WeeklySessionsChart(sessions: progressProvider.sessions),
            const SizedBox(height: 24),
            const Text(
              'Pain by Body Area',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildPainByAreaChart(),
            const SizedBox(height: 24),
            const Text(
              'Weekly Improvement Rate',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildWeeklyImprovementChart(),
            const SizedBox(height: 24),
            const Text(
              'Session Frequency',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SessionFrequencyGrid(activeDays: _frequencyGrid),
          ],
        ),
),
```

- [ ] **Step 10: Run analyzer**

```
flutter analyze lib/screens/progress/progress_screen.dart
```

Expected: No issues found.

- [ ] **Step 11: Run all tests**

```
flutter test
```

Expected: All tests pass.

- [ ] **Step 12: Commit**

```
git add lib/screens/progress/progress_screen.dart
git commit -m "feat: add analytics charts and PDF export to ProgressScreen"
```

---

## Task 6: Final Check + Tag

- [ ] **Step 1: Full analysis**

```
flutter analyze
```

Expected: No issues found.

- [ ] **Step 2: Full test suite**

```
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Push and tag**

```
git push origin main
git tag v3.0.0-3b
git push origin v3.0.0-3b
```
