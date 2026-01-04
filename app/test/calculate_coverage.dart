import 'dart:io';

// ignore_for_file: avoid_print

void main() async {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print(
      'Error: coverage/lcov.info not found. Run "flutter test --coverage" first.',
    );
    return;
  }

  final lines = await file.readAsLines();

  // Overall stats
  int totalLF = 0;
  int totalLH = 0;

  // Filtered stats (excluding generated files)
  int effectiveLF = 0;
  int effectiveLH = 0;

  // Directory breakdown
  final Map<String, _DirStats> dirStats = {};

  String? currentFile;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3).replaceAll('\\', '/');
    } else if (line.startsWith('LF:')) {
      final lf = int.parse(line.substring(3));
      totalLF += lf;

      if (currentFile != null) {
        final file = currentFile;
        final isGenerated =
            file.endsWith('.g.dart') ||
            file.endsWith('.freezed.dart') ||
            file.contains('/generated/');

        if (!isGenerated) {
          effectiveLF += lf;
          _updateDirStats(dirStats, file, lf, 0);
        }
      }
    } else if (line.startsWith('LH:')) {
      final lh = int.parse(line.substring(3));
      totalLH += lh;

      if (currentFile != null) {
        final file = currentFile;
        final isGenerated =
            file.endsWith('.g.dart') ||
            file.endsWith('.freezed.dart') ||
            file.contains('/generated/');

        if (!isGenerated) {
          effectiveLH += lh;
          _updateDirStats(dirStats, file, 0, lh);
        }
      }
    }
  }

  print('--- COVERAGE REPORT ---');
  print('Total (Raw): ${_calc(totalLH, totalLF)}% ($totalLH/$totalLF)');
  print(
    'Effective (No Generated): ${_calc(effectiveLH, effectiveLF)}% ($effectiveLH/$effectiveLF)',
  );
  print('\n--- BY DIRECTORY (Effective) ---');

  final sortedDirs = dirStats.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in sortedDirs) {
    final stats = entry.value;
    final percent = _calc(stats.lh, stats.lf);
    print('${entry.key.padRight(40)}: $percent% (${stats.lh}/${stats.lf})');
  }
}

void _updateDirStats(
  Map<String, _DirStats> stats,
  String path,
  int lf,
  int lh,
) {
  // Extract top-level dir (e.g., lib/screens, lib/widgets)
  final parts = path.split('/');
  String dir = 'root';
  if (parts.length > 2 && parts[0] == 'lib') {
    dir = 'lib/${parts[1]}';
  } else if (parts.length > 1 && parts[0] == 'test') {
    return; // Ignore test files if they appear in coverage
  }

  stats.putIfAbsent(dir, () => _DirStats());
  stats[dir]!.lf += lf;
  stats[dir]!.lh += lh;
}

String _calc(int hits, int total) {
  if (total == 0) return '0.00';
  return ((hits / total) * 100).toStringAsFixed(2);
}

class _DirStats {
  int lf = 0;
  int lh = 0;
}
