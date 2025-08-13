/// Command-line tool to parse availability strings into a CSV.
///
/// Input format (per line):
///   `availability segments...`\t`given/middle names`\t`surname`
///
/// Availability segments repeat as pairs of German and English descriptors, e.g.:
///   "19:00 - 21:30, Dienstag, 12.08. / Tuesday, August 12, 19:00 - 21:30, Freitag, 15.08. / Friday August 15, ..."
///
/// We extract only the German segments using this pattern:
///   HH:MM - HH:MM, (Dienstag|Freitag|Samstag|Tag des Herrn), DD.MM.
///
/// Output CSV columns:
///   Name,`DD.MM HH:MM DOW`,...
/// Where each message column contains 1 if the person is available for that slot, 0 otherwise.
///
/// Usage:
///   dart run scripts/parse_availability.dart --input /path/to/input.txt --output /path/to/output.csv
///   # or read from STDIN and write to STDOUT:
///   cat input.txt | dart run scripts/parse_availability.dart > availability.csv
library;

import 'dart:convert';
import 'dart:io';

/// Represents a single availability slot parsed from a German segment.
class AvailabilitySlot {
  AvailabilitySlot({
    required this.day,
    required this.month,
    required this.startMinutes,
    required this.endMinutes,
    required this.germanDayOfWeek,
  });

  final int day; // 1..31
  final int month; // 1..12
  final int startMinutes; // minutes since 00:00
  final int endMinutes; // minutes since 00:00
  final String germanDayOfWeek; // Dienstag, Freitag, Samstag, Tag des Herrn

  /// Canonical ID for this message slot for lookup and de-duplication.
  String get id =>
      '${_two(month)}.${_two(day)}-${_timeLabel(startMinutes)}-${_dowShort(germanDayOfWeek)}';

  /// Human-friendly label for CSV header.
  String get label =>
      '${_two(day)}.${_two(month)} ${_timeLabel(startMinutes)} ${_dowShort(germanDayOfWeek)}';

  /// Sort key by date then start time.
  int get sortKey => (month * 31 + day) * 1440 + startMinutes;
}

Future<void> main(List<String> args) async {
  final argMap = _parseArgs(args);
  final inputPath = argMap['--input'];
  final outputPath = argMap['--output'];

  final raw = await _readAll(inputPath);
  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // Regex to match German availability segments.
  final germanSegment = RegExp(
    r'(\d{2}):(\d{2})\s*-\s*(\d{2}):(\d{2}),\s*(Dienstag|Freitag|Samstag|Tag des Herrn),\s*(\d{1,2})\.(\d{2})\.',
  );

  // Collect all message slots across all lines to build stable CSV columns.
  final Map<String, AvailabilitySlot> idToSlot = {};

  // Each person's availability by message ID.
  final Map<String, Set<String>> personToMessageIds = {};

  for (final line in lines) {
    // Expect at least 2 tabs: [availability]\t[given/middle]\t[surname]
    final fields = line
        .split(RegExp(r'\t+'))
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    if (fields.isEmpty) continue;

    final availabilityBlob = fields.first;

    // Extract all German segments present in this line.
    final matches = germanSegment.allMatches(availabilityBlob).toList();
    if (matches.isEmpty) {
      // Skip non-availability lines (e.g., headers like M1...M12)
      continue;
    }

    // Build the person's name from the remaining fields (join all except first, but keep the last as surname).
    String name;
    if (fields.length >= 3) {
      final given = fields.sublist(1, fields.length - 1).join(' ');
      final surname = fields.last;
      name = ('$given $surname').replaceAll(RegExp(r'\s+'), ' ').trim();
    } else if (fields.length == 2) {
      name = fields[1];
    } else {
      name = 'Unknown';
    }

    final messageIds = personToMessageIds.putIfAbsent(name, () => <String>{});

    for (final m in matches) {
      final startH = int.parse(m.group(1)!);
      final startM = int.parse(m.group(2)!);
      final endH = int.parse(m.group(3)!);
      final endM = int.parse(m.group(4)!);
      final dowDe = m.group(5)!;
      final day = int.parse(m.group(6)!);
      final month = int.parse(m.group(7)!);

      final slot = AvailabilitySlot(
        day: day,
        month: month,
        startMinutes: startH * 60 + startM,
        endMinutes: endH * 60 + endM,
        germanDayOfWeek: dowDe,
      );

      idToSlot.putIfAbsent(slot.id, () => slot);
      messageIds.add(slot.id);
    }
  }

  // Sort unique message slots chronologically.
  final slots = idToSlot.values.toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  // Build CSV rows.
  final headers = <String>['Name', ...slots.map((s) => s.label)];
  final rows = <List<String>>[];
  rows.add(headers);

  final sortedPeople = personToMessageIds.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  for (final person in sortedPeople) {
    final ids = personToMessageIds[person]!;
    final row = <String>[person];
    for (final slot in slots) {
      row.add(ids.contains(slot.id) ? '1' : '0');
    }
    rows.add(row);
  }

  final csvString = _toCsv(rows);

  if (outputPath != null) {
    final file = File(outputPath);
    await file.writeAsString(csvString);
  } else {
    stdout.write(csvString);
  }
}

Future<String> _readAll(String? inputPath) async {
  if (inputPath != null) {
    return File(inputPath).readAsString();
  }
  // Read from STDIN
  final bytes =
      await stdin.fold<List<int>>(<int>[], (List<int> acc, List<int> data) {
    acc.addAll(data);
    return acc;
  });
  return const Utf8Decoder().convert(bytes);
}

Map<String, String?> _parseArgs(List<String> args) {
  final map = <String, String?>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--input' && i + 1 < args.length) {
      map['--input'] = args[++i];
    } else if (arg == '--output' && i + 1 < args.length) {
      map['--output'] = args[++i];
    }
  }
  return map;
}

String _toCsv(List<List<String>> rows) {
  final buffer = StringBuffer();
  for (final row in rows) {
    buffer.writeln(row.map(_csvEscape).join(','));
  }
  return buffer.toString();
}

String _csvEscape(String value) {
  final needsQuoting = value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  var v = value;
  if (value.contains('"')) {
    v = value.replaceAll('"', '""');
  }
  return needsQuoting ? '"$v"' : v;
}

String _two(int n) => n.toString().padLeft(2, '0');

String _timeLabel(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String _dowShort(String german) {
  switch (german) {
    case 'Dienstag':
      return 'Tue';
    case 'Freitag':
      return 'Fri';
    case 'Samstag':
      return 'Sat';
    case 'Tag des Herrn':
      return 'Sun';
    default:
      return german;
  }
}
