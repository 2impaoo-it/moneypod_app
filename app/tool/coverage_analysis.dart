import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    // ignore: avoid_print
    print('lcov.info not found');
    return;
  }

  final lines = file.readAsLinesSync();
  int totalLines = 0;
  int hitLines = 0;

  final Map<String, _Coverage> dirCoverage = {};

  String? currentFile;
  int fileFound = 0;
  int fileHit = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileFound = 0;
      fileHit = 0;
    } else if (line.startsWith('LF:')) {
      fileFound = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      fileHit = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      if (currentFile != null) {
        totalLines += fileFound;
        hitLines += fileHit;

        // Group by directory
        // currentFile is potentially absolute or relative.

        String dir = 'other';
        if (currentFile.contains('/repositories/')) {
          dir = 'repositories';
        } else if (currentFile.contains('/bloc/') ||
            currentFile.contains('/cubit/')) {
          dir = 'bloc';
        } else if (currentFile.contains('/services/')) {
          dir = 'services';
        } else if (currentFile.contains('/models/')) {
          dir = 'models';
        } else if (currentFile.contains('/widgets/')) {
          dir = 'widgets';
        } else if (currentFile.contains('/screens/')) {
          dir = 'screens';
        }

        dirCoverage.putIfAbsent(dir, () => _Coverage(0, 0));
        dirCoverage[dir]!.found += fileFound;
        dirCoverage[dir]!.hit += fileHit;
      }
    }
  }

  final overall = totalLines > 0
      ? (hitLines / totalLines * 100).toStringAsFixed(2)
      : '0.00';
  // ignore: avoid_print
  print('Overall Coverage: $overall% ($hitLines / $totalLines)');

  // ignore: avoid_print
  print('\nCoverage by Directory:');
  dirCoverage.forEach((dir, cov) {
    final pct = cov.found > 0
        ? (cov.hit / cov.found * 100).toStringAsFixed(2)
        : '0.00';
    // ignore: avoid_print
    print('- $dir: $pct% (${cov.hit} / ${cov.found})');
  });
}

class _Coverage {
  int found;
  int hit;
  _Coverage(this.found, this.hit);
}
