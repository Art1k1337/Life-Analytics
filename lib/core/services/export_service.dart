import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/day_entry.dart';

class ExportService {
  static Future<XFile> exportCsv(List<DayEntry> entries) async {
    final buffer = StringBuffer();
    buffer.writeln('date,index,productivity,sleep,mood,steps,sport,work,study,game,screen,water,calories,weight,stress,energy,note');

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in sorted) {
      buffer.writeln(
        '${e.dayKey},${e.lifeIndex},${e.productivityScore},'
        '${e.sleepHours.toStringAsFixed(1)},${e.mood},${e.steps},'
        '${e.sportMinutes},${e.workMinutes},${e.studyMinutes},'
        '${e.gameMinutes},${e.screenMinutes},${e.waterLiters.toStringAsFixed(1)},'
        '${e.calories},${e.weightKg.toStringAsFixed(1)},'
        '${e.stress},${e.energy},"${e.note.replaceAll('"', '""')}"',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/life_analytics_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    return XFile(file.path);
  }

  static Future<XFile> exportJson(List<DayEntry> entries) async {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final data = sorted.map((e) => {
      'date': e.dayKey,
      'lifeIndex': e.lifeIndex,
      'productivity': e.productivityScore,
      'sleepHours': e.sleepHours,
      'mood': e.mood,
      'steps': e.steps,
      'sportMinutes': e.sportMinutes,
      'workMinutes': e.workMinutes,
      'studyMinutes': e.studyMinutes,
      'gameMinutes': e.gameMinutes,
      'screenMinutes': e.screenMinutes,
      'waterLiters': e.waterLiters,
      'calories': e.calories,
      'weightKg': e.weightKg,
      'stress': e.stress,
      'energy': e.energy,
      'note': e.note,
    }).toList();

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/life_analytics_${DateFormat('yyyyMMdd').format(DateTime.now())}.json');
    await file.writeAsString(json);
    return XFile(file.path);
  }

  static Future<void> shareCsv(List<DayEntry> entries) async {
    final file = await exportCsv(entries);
    await Share.shareXFiles([file], text: 'Life Analytics — экспорт данных');
  }

  static Future<void> shareJson(List<DayEntry> entries) async {
    final file = await exportJson(entries);
    await Share.shareXFiles([file], text: 'Life Analytics — экспорт данных');
  }
}
