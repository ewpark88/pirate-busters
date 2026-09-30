import 'dart:io';

import 'package:sim_runner/sim_runner.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(usage);
    return;
  }
  final SimOptions options;
  try {
    options = SimOptions.parse(arguments);
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln(usage);
    exitCode = 64;
    return;
  }
  final watch = Stopwatch()..start();
  final report = await runAll(options);
  stdout
    ..writeln(
      '${options.left.name} vs ${options.right.name}, '
      '${options.jobs} jobs, ${watch.elapsed.inSeconds}s',
    )
    ..write(report.text());
  final csv = options.csv;
  if (csv != null) File(csv).writeAsStringSync(report.csv());
  if (report.warnings.isNotEmpty) exitCode = 1;
}
