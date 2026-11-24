// Command-line tool: printing to stdout is intended.
// ignore_for_file: avoid_print

import 'dart:io';

import 'src/report.dart';

/// Regenerates `REPORT.md` in every run folder under `results/` (or the
/// folders given) and the `results/README.md` index.
///
///     dart run tool/report.dart                # all runs + index
///     dart run tool/report.dart results/<run>  # one run
void main(List<String> args) {
  final resultsDir = Directory('results');
  final folders = args.isEmpty
      ? runFolders(resultsDir)
      : [for (final path in args) Directory(path)];

  for (final folder in folders) {
    final data = RunData.load(folder);
    File('${folder.path}/REPORT.md').writeAsStringSync(renderReport(data));
    print('Wrote ${folder.path}/REPORT.md');
  }

  if (resultsDir.existsSync()) {
    final all = [for (final f in runFolders(resultsDir)) RunData.load(f)];
    File('${resultsDir.path}/README.md').writeAsStringSync(renderIndex(all));
    print('Wrote ${resultsDir.path}/README.md');
  }
}
