import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

class HiveService {
  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(AppConstants.analysisHistoryBox);
    await Hive.openBox<String>(AppConstants.preferencesBox);
  }

  Box<String> get analysisHistory => Hive.box<String>(AppConstants.analysisHistoryBox);
}
