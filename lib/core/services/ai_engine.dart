import 'package:intl/intl.dart';

import '../models/ai_insight.dart';
import '../models/day_entry.dart';
import '../models/habit.dart';
import '../models/life_goal.dart';
import '../models/user_profile.dart';
import 'analytics_service.dart';

class AiEngine {
  AiEngine(this._analytics);

  final AnalyticsService _analytics;

  AiAnalysis analyze({
    required List<DayEntry> entries,
    required List<Habit> habits,
    required List<LifeGoal> goals,
    UserProfile? profile,
  }) {
    if (entries.isEmpty) {
      return _emptyAnalysis();
    }

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.length > 60 ? sorted.sublist(sorted.length - 60) : sorted;
    final last30 = recent.length > 30 ? recent.sublist(recent.length - 30) : recent;
    final last14 = recent.length > 14 ? recent.sublist(recent.length - 14) : recent;
    final last7 = recent.length > 7 ? recent.sublist(recent.length - 7) : recent;

    final positive = <AiInsight>[];
    final negative = <AiInsight>[];
    final advice = <AiInsight>[];
    final patterns = <AiInsight>[];
    final records = <AiInsight>[];

    _analyzeCorrelations(last30, positive, negative);
    _analyzeSleep(last30, last7, positive, negative, advice, profile);
    _analyzeMood(last30, last7, positive, negative, advice);
    _analyzeStress(last30, positive, negative, advice);
    _analyzeEnergy(last30, positive, negative);
    _analyzeProductivity(last30, last7, positive, negative, advice);
    _analyzeSport(last30, positive, negative, advice);
    _analyzeScreenTime(last30, negative, advice);
    _analyzeNutrition(last30, positive, negative, advice);
    _analyzeSteps(last30, positive, advice);
    _analyzeHabits(habits, positive, advice);
    _analyzeGoals(goals, advice);
    _analyzePatterns(recent, patterns);
    _analyzeRecords(recent, records);
    _analyzeWarnings(last14, negative);
    _generateAdvice(last30, sorted, advice, profile);

    final forecast = _buildForecast(sorted);
    final dimensions = _buildDimensions(last30, habits, goals);
    final healthScore = _calculateHealthScore(last30);
    final stabilityScore = _calculateStabilityScore(last14);
    final dayPersona = _buildDayPersona(last30.isNotEmpty ? last30.last : sorted.last);
    final summary = _buildSummary(last30, healthScore, stabilityScore, profile);

    return AiAnalysis(
      generatedAt: DateTime.now(),
      positive: positive,
      negative: negative,
      advice: advice,
      forecast: forecast,
      patterns: patterns,
      records: records,
      dimensions: dimensions,
      summary: summary,
      dayPersona: dayPersona,
      healthScore: healthScore,
      stabilityScore: stabilityScore,
    );
  }

  // ── Correlation analysis ──

  void _analyzeCorrelations(List<DayEntry> data, List<AiInsight> pos, List<AiInsight> neg) {
    if (data.length < 7) return;

    final pairs = [
      _CorrPair('sleep', 'productivity', data.map((e) => e.sleepHours), data.map((e) => e.productivityScore.toDouble())),
      _CorrPair('sport', 'mood', data.map((e) => e.sportMinutes.toDouble()), data.map((e) => e.mood.toDouble())),
      _CorrPair('steps', 'mood', data.map((e) => e.steps.toDouble()), data.map((e) => e.mood.toDouble())),
      _CorrPair('screen', 'productivity', data.map((e) => (e.screenMinutes + e.gameMinutes).toDouble()), data.map((e) => e.productivityScore.toDouble())),
      _CorrPair('stress', 'energy', data.map((e) => e.stress.toDouble()), data.map((e) => e.energy.toDouble())),
      _CorrPair('sleep', 'stress', data.map((e) => e.sleepHours), data.map((e) => e.stress.toDouble())),
      _CorrPair('water', 'energy', data.map((e) => e.waterLiters), data.map((e) => e.energy.toDouble())),
      _CorrPair('sport', 'sleep', data.map((e) => e.sportMinutes.toDouble()), data.map((e) => e.sleepHours)),
      _CorrPair('work', 'stress', data.map((e) => e.workMinutes.toDouble()), data.map((e) => e.stress.toDouble())),
      _CorrPair('study', 'mood', data.map((e) => e.studyMinutes.toDouble()), data.map((e) => e.mood.toDouble())),
    ];

    for (final pair in pairs) {
      final r = _analytics.correlation(pair.left, pair.right);
      if (r > 0.20) {
        pos.add(_corrInsight(pair.name, r, true));
      } else if (r < -0.18) {
        neg.add(_corrInsight(pair.name, r, false));
      }
    }
  }

  AiInsight _corrInsight(String name, double r, bool isPositive) {
    final conf = r.abs().clamp(0.40, 0.96);
    final texts = _corrTexts[name]!;
    return AiInsight(
      title: isPositive ? texts.$1 : texts.$2,
      description: isPositive ? texts.$3 : texts.$4,
      type: isPositive ? InsightType.positive : InsightType.negative,
      confidence: conf,
      category: _corrCategory[name],
    );
  }

  static const _corrTexts = {
    'sleep': ('Сон → продуктивность', 'Недосып бьёт по продуктивности', 'Чем лучше сон — тем выше продуктивность. Связь подтверждена данными.', 'Дни с коротким сном показывают заметно ниже продуктивность.'),
    'sport': ('Спорт улучшает настроение', 'Спорт и настроение не связаны', 'Активные дни стабильно дают лучшее настроение.', 'Спорт пока не влияет на настроение — попробуй другие виды активности.'),
    'steps': ('Шаги поднимают настроение', 'Мало шагов — хуже настроение', 'Дни с 8000+ шагами связаны с лучшим настроением.', 'В дни с малым количеством шагов настроение ниже.'),
    'screen': ('Меньше экрана — выше фокус', 'Экранное время снижает концентрацию', 'В дни с ограничением экранного времени продуктивность выше.', 'Более 3 часов экрана коррелирует со снижением продуктивности.'),
    'stress': ('Стресс забирает энергию', 'Высокий стресс → мало энергии', 'В дни с низким стрессом энергия стабильно выше.', 'Рост стресса напрямую снижает уровень энергии.'),
    'sleep_stress': ('Сон снижает стресс', 'Мало сна повышает стресс', 'Хороший сон связан с более низким уровнем стресса.', 'Недосыпание коррелирует с ростом стресса.'),
    'water': ('Вода повышает энергию', 'Мало воды — мало энергии', 'Дни с нормальным потреблением воды показывают выше энергию.', 'Недостаток воды связан со снижением энергии.'),
    'sport_sleep': ('Спорт улучшает сон', 'Спорт не влияет на сон', 'В дни с физической активностью сон качественнее.', 'Спорт пока не улучшает сон — попробуй тренировки раньше.'),
    'work': ('Работа повышает стресс', 'Больше работы → больше стресса', 'Длинные рабочие дни связаны с ростом стресса.', 'Чрезмерная работа увеличивает стресс.'),
    'study': ('Учёба поднимает настроение', 'Учёба не влияет на настроение', 'Дни с учёбой связаны с лучшим настроением.', 'Учёба пока не даёт прироста настроения.'),
  };

  static const _corrCategory = {
    'sleep': InsightCategory.sleep,
    'sport': InsightCategory.sport,
    'steps': InsightCategory.steps,
    'screen': InsightCategory.screenTime,
    'stress': InsightCategory.stress,
    'sleep_stress': InsightCategory.sleep,
    'water': InsightCategory.nutrition,
    'sport_sleep': InsightCategory.sport,
    'work': InsightCategory.stress,
    'study': InsightCategory.productivity,
  };

  // ── Sleep analysis ──

  void _analyzeSleep(List<DayEntry> last30, List<DayEntry> last7,
      List<AiInsight> pos, List<AiInsight> neg, List<AiInsight> advice, UserProfile? profile) {
    if (last7.isEmpty) return;

    final avgSleep = last7.map((e) => e.sleepHours).fold<double>(0, (s, e) => s + e) / last7.length;
    final sleepValues = last7.map((e) => e.sleepHours).toList();
    final sleepStd = _stdDev(sleepValues);
    final optimalMin = profile != null && profile.age < 25 ? 7.5 : 7.0;
    final optimalMax = profile != null && profile.age < 25 ? 9.0 : 8.5;

    if (avgSleep >= optimalMin && avgSleep <= optimalMax) {
      pos.add(AiInsight(
        title: 'Оптимальный сон',
        description: 'Среднее за неделю — ${avgSleep.toStringAsFixed(1)} ч. Это в идеальном диапазоне.',
        type: InsightType.positive,
        confidence: 0.88,
        category: InsightCategory.sleep,
      ));
    } else if (avgSleep < 6) {
      neg.add(AiInsight(
        title: 'Критический недосып',
        description: 'Среднее за неделю — ${avgSleep.toStringAsFixed(1)} ч. Этосерьёзно снижает продуктивность, настроение и здоровье.',
        type: InsightType.negative,
        confidence: 0.92,
        category: InsightCategory.sleep,
      ));
      advice.add(AiInsight(
        title: 'Восстанови сон',
        description: 'Ложись на 30 минут раньше каждые 2 дня, пока не дойдёшь до 7 часов.',
        type: InsightType.advice,
        confidence: 0.85,
        category: InsightCategory.sleep,
      ));
    } else if (avgSleep < optimalMin) {
      neg.add(AiInsight(
        title: 'Сон ниже нормы',
        description: 'Среднее — ${avgSleep.toStringAsFixed(1)} ч. Оптимум для тебя: ${optimalMin.toStringAsFixed(1)}–${optimalMax.toStringAsFixed(1)} ч.',
        type: InsightType.negative,
        confidence: 0.78,
        category: InsightCategory.sleep,
      ));
    } else if (avgSleep > 9.5) {
      neg.add(AiInsight(
        title: 'Избыточный сон',
        description: 'Среднее — ${avgSleep.toStringAsFixed(1)} ч. Сон больше 9.5 часов может снижать энергию.',
        type: InsightType.negative,
        confidence: 0.65,
        category: InsightCategory.sleep,
      ));
    }

    if (sleepStd > 1.5) {
      neg.add(AiInsight(
        title: 'Нестабильный режим сна',
        description: 'Разброс сна ${sleepStd.toStringAsFixed(1)} ч. Нерегулярный сон хуже, чем короткий, но стабильный.',
        type: InsightType.negative,
        confidence: 0.80,
        category: InsightCategory.sleep,
      ));
      advice.add(AiInsight(
        title: 'Стабилизируй время сна',
        description: 'Ложись и вставай в одно и то же время ±30 минут, даже в выходные.',
        type: InsightType.advice,
        confidence: 0.82,
        category: InsightCategory.sleep,
      ));
    } else if (sleepStd < 0.5 && last7.length >= 5) {
      pos.add(AiInsight(
        title: 'Стабильный режим сна',
        description: 'Разброс менее 30 минут — отличная регулярность.',
        type: InsightType.positive,
        confidence: 0.85,
        category: InsightCategory.sleep,
      ));
    }
  }

  // ── Mood analysis ──

  void _analyzeMood(List<DayEntry> last30, List<DayEntry> last7,
      List<AiInsight> pos, List<AiInsight> neg, List<AiInsight> advice) {
    if (last7.isEmpty) return;

    final avgMood = last7.map((e) => e.mood).fold<double>(0, (s, e) => s + e) / last7.length;
    final moodTrend = _trend(last7.map((e) => e.mood.toDouble()).toList());

    if (avgMood >= 8) {
      pos.add(AiInsight(
        title: 'Отличное настроение',
        description: 'Среднее за неделю — ${avgMood.toStringAsFixed(1)}/10. Ты в ресурсном состоянии.',
        type: InsightType.positive,
        confidence: 0.85,
        category: InsightCategory.mood,
      ));
    } else if (avgMood <= 4) {
      neg.add(AiInsight(
        title: 'Настроение на дне',
        description: 'Среднее за неделю — ${avgMood.toStringAsFixed(1)}/10. Обрати внимание на отдых и восстановление.',
        type: InsightType.negative,
        confidence: 0.88,
        category: InsightCategory.mood,
      ));
    }

    if (moodTrend < -0.3) {
      neg.add(AiInsight(
        title: 'Настроение падает',
        description: 'Тренд за неделю отрицательный. Найди время для того, что приносит радость.',
        type: InsightType.negative,
        confidence: 0.75,
        category: InsightCategory.mood,
      ));
    } else if (moodTrend > 0.3) {
      pos.add(AiInsight(
        title: 'Настроение растёт',
        description: 'Позитивная динамика за неделю. Продолжай в том же духе!',
        type: InsightType.positive,
        confidence: 0.78,
        category: InsightCategory.mood,
      ));
    }

    // Weekend vs weekday mood
    if (last30.length >= 14) {
      final weekdayMood = <double>[];
      final weekendMood = <double>[];
      for (final e in last30) {
        if (e.date.weekday >= 6) {
          weekendMood.add(e.mood.toDouble());
        } else {
          weekdayMood.add(e.mood.toDouble());
        }
      }
      if (weekdayMood.isNotEmpty && weekendMood.isNotEmpty) {
        final wdAvg = weekdayMood.fold<double>(0, (s, e) => s + e) / weekdayMood.length;
        final weAvg = weekendMood.fold<double>(0, (s, e) => s + e) / weekendMood.length;
        if (weAvg - wdAvg > 2) {
          advice.add(AiInsight(
            title: 'Будни тяжелее выходных',
            description: 'Настроение в будни на ${(weAvg - wdAvg).round()} пунктов ниже. Подумай, как добавить отдых в рабочие дни.',
            type: InsightType.pattern,
            confidence: 0.72,
            category: InsightCategory.mood,
          ));
        }
      }
    }
  }

  // ── Stress analysis ──

  void _analyzeStress(List<DayEntry> last30, List<AiInsight> pos, List<AiInsight> neg, List<AiInsight> advice) {
    if (last30.length < 5) return;

    final avgStress = last30.map((e) => e.stress).fold<double>(0, (s, e) => s + e) / last30.length;
    final stressTrend = _trend(last30.take(14).map((e) => e.stress.toDouble()).toList());

    if (avgStress >= 7) {
      neg.add(AiInsight(
        title: 'Хронический стресс',
        description: 'Средний стресс ${avgStress.toStringAsFixed(1)}/10. Высокий стресс снижает иммунитет и продуктивность.',
        type: InsightType.negative,
        confidence: 0.87,
        category: InsightCategory.stress,
      ));
      advice.add(AiInsight(
        title: 'Снизь стресс',
        description: 'Попробуй 10 минут дыхательных упражнений перед сном или короткую прогулку в обед.',
        type: InsightType.advice,
        confidence: 0.80,
        category: InsightCategory.stress,
      ));
    } else if (avgStress <= 3) {
      pos.add(AiInsight(
        title: 'Низкий стресс',
        description: 'Средний стресс ${avgStress.toStringAsFixed(1)}/10. Ты в спокойном состоянии.',
        type: InsightType.positive,
        confidence: 0.82,
        category: InsightCategory.stress,
      ));
    }

    if (stressTrend > 0.4) {
      neg.add(AiInsight(
        title: 'Стресс растёт',
        description: 'Последние дни стресс нарастает. Важно вовремя сделать паузу.',
        type: InsightType.negative,
        confidence: 0.73,
        category: InsightCategory.stress,
      ));
    }
  }

  // ── Energy analysis ──

  void _analyzeEnergy(List<DayEntry> last30, List<AiInsight> pos, List<AiInsight> neg) {
    if (last30.length < 5) return;

    final avgEnergy = last30.map((e) => e.energy).fold<double>(0, (s, e) => s + e) / last30.length;

    if (avgEnergy >= 8) {
      pos.add(AiInsight(
        title: 'Высокая энергия',
        description: 'Средняя энергия ${avgEnergy.toStringAsFixed(1)}/10. Отличный ресурс для целей.',
        type: InsightType.positive,
        confidence: 0.83,
        category: InsightCategory.energy,
      ));
    } else if (avgEnergy <= 4) {
      neg.add(AiInsight(
        title: 'Энергия на нуле',
        description: 'Средняя энергия ${avgEnergy.toStringAsFixed(1)}/10. Проверь сон, питание и уровень стресса.',
        type: InsightType.negative,
        confidence: 0.86,
        category: InsightCategory.energy,
      ));
    }
  }

  // ── Productivity analysis ──

  void _analyzeProductivity(List<DayEntry> last30, List<DayEntry> last7,
      List<AiInsight> pos, List<AiInsight> neg, List<AiInsight> advice) {
    if (last7.isEmpty) return;

    final avgProd = last7.map((e) => e.productivityScore).fold<double>(0, (s, e) => s + e) / last7.length;
    final prodTrend = _trend(last7.map((e) => e.productivityScore.toDouble()).toList());
    final avgWork = last7.map((e) => e.workStudyMinutes).fold<double>(0, (s, e) => s + e) / last7.length;

    if (avgProd >= 70) {
      pos.add(AiInsight(
        title: 'Высокая продуктивность',
        description: 'Средний балл за неделю — ${avgProd.round()}/100.',
        type: InsightType.positive,
        confidence: 0.84,
        category: InsightCategory.productivity,
      ));
    } else if (avgProd < 30) {
      neg.add(AiInsight(
        title: 'Низкая продуктивность',
        description: 'Средний балл — ${avgProd.round()}/100. Работа/учёба занимают мало времени.',
        type: InsightType.negative,
        confidence: 0.80,
        category: InsightCategory.productivity,
      ));
    }

    if (prodTrend < -0.5) {
      neg.add(AiInsight(
        title: 'Продуктивность падает',
        description: 'Отрицательная динамика. Возможно, нужен отдых или смена фокуса.',
        type: InsightType.negative,
        confidence: 0.72,
        category: InsightCategory.productivity,
      ));
    }

    if (avgWork > 0 && avgWork < 120) {
      advice.add(AiInsight(
        title: 'Увеличь время на работу',
        description: 'Среднее — ${(avgWork / 60).toStringAsFixed(1)} ч/день. Попробуй технику Pomodoro: 25 мин работы + 5 мин отдыха.',
        type: InsightType.advice,
        confidence: 0.75,
        category: InsightCategory.productivity,
      ));
    }
  }

  // ── Sport analysis ──

  void _analyzeSport(List<DayEntry> last30, List<AiInsight> pos, List<AiInsight> neg, List<AiInsight> advice) {
    if (last30.length < 7) return;

    final sportDays = last30.where((e) => e.sportMinutes >= 20).length;

    if (sportDays >= 20) {
      pos.add(AiInsight(
        title: 'Спортивный стиль жизни',
        description: '$sportDays из ${last30.length} дней с активностью. Отличная регулярность!',
        type: InsightType.positive,
        confidence: 0.90,
        category: InsightCategory.sport,
      ));
    } else if (sportDays < 5) {
      neg.add(AiInsight(
        title: 'Мало движения',
        description: 'Всего $sportDays дней с активностью за месяц. ВОЗ рекомендует 150 мин/неделю.',
        type: InsightType.negative,
        confidence: 0.82,
        category: InsightCategory.sport,
      ));
      advice.add(AiInsight(
        title: 'Начни с малого',
        description: 'Хотя бы 20 минут быстрой ходьбы 3 раза в неделю уже дадут эффект.',
        type: InsightType.advice,
        confidence: 0.78,
        category: InsightCategory.sport,
      ));
    }
  }

  // ── Screen time analysis ──

  void _analyzeScreenTime(List<DayEntry> last30, List<AiInsight> neg, List<AiInsight> advice) {
    if (last30.length < 5) return;

    final avgScreen = last30.map((e) => e.screenMinutes + e.gameMinutes).fold<double>(0, (s, e) => s + e) / last30.length;

    if (avgScreen > 300) {
      neg.add(AiInsight(
        title: 'Экранное время зашкаливает',
        description: 'Среднее — ${(avgScreen / 60).toStringAsFixed(1)} ч/день. Более 5 часов экрана снижает концентрацию и сон.',
        type: InsightType.negative,
        confidence: 0.85,
        category: InsightCategory.screenTime,
      ));
      advice.add(AiInsight(
        title: 'Поставь лимит экрана',
        description: 'Используй встроенный таймер экранного времени. Начни с лимита 3 часа.',
        type: InsightType.advice,
        confidence: 0.80,
        category: InsightCategory.screenTime,
      ));
    } else if (avgScreen > 180) {
      neg.add(AiInsight(
        title: 'Экранное время выше нормы',
        description: 'Среднее — ${(avgScreen / 60).toStringAsFixed(1)} ч/день. Оптимум — до 3 часов.',
        type: InsightType.negative,
        confidence: 0.72,
        category: InsightCategory.screenTime,
      ));
    }
  }

  // ── Nutrition analysis ──

  void _analyzeNutrition(List<DayEntry> last30, List<AiInsight> pos, List<AiInsight> neg, List<AiInsight> advice) {
    if (last30.length < 5) return;

    final avgWater = last30.map((e) => e.waterLiters).fold<double>(0, (s, e) => s + e) / last30.length;
    final avgCalories = last30.map((e) => e.calories).fold<double>(0, (s, e) => s + e) / last30.length;

    if (avgWater >= 2.0) {
      pos.add(AiInsight(
        title: 'Достаточно воды',
        description: 'Среднее — ${avgWater.toStringAsFixed(1)} л/день. Хорошая гидратация.',
        type: InsightType.positive,
        confidence: 0.80,
        category: InsightCategory.nutrition,
      ));
    } else if (avgWater < 1.2) {
      neg.add(AiInsight(
        title: 'Мало воды',
        description: 'Среднее — ${avgWater.toStringAsFixed(1)} л/день. Рекомендуется 1.5–2.5 л.',
        type: InsightType.negative,
        confidence: 0.78,
        category: InsightCategory.nutrition,
      ));
      advice.add(AiInsight(
        title: 'Пей больше воды',
        description: 'Держи бутылку воды на столе. Стакан каждый час — и норма будет выполнена.',
        type: InsightType.advice,
        confidence: 0.75,
        category: InsightCategory.nutrition,
      ));
    }

    if (avgCalories > 0) {
      if (avgCalories > 3000) {
        neg.add(AiInsight(
          title: 'Калории выше нормы',
          description: 'Среднее — ${avgCalories.round()} ккал/день. Избыток калорий снижает энергию.',
          type: InsightType.negative,
          confidence: 0.70,
          category: InsightCategory.nutrition,
        ));
      } else if (avgCalories < 1200) {
        neg.add(AiInsight(
          title: 'Калории ниже нормы',
          description: 'Среднее — ${avgCalories.round()} ккал/день. Недостаток питания снижает энергию и настроение.',
          type: InsightType.negative,
          confidence: 0.72,
          category: InsightCategory.nutrition,
        ));
      }
    }
  }

  // ── Steps analysis ──

  void _analyzeSteps(List<DayEntry> last30, List<AiInsight> pos, List<AiInsight> advice) {
    if (last30.length < 5) return;

    final avgSteps = last30.map((e) => e.steps).fold<double>(0, (s, e) => s + e) / last30.length;

    if (avgSteps >= 10000) {
      pos.add(AiInsight(
        title: '10 000 шагов в день',
        description: 'Среднее — ${avgSteps.round()} шагов. Отличная активность!',
        type: InsightType.positive,
        confidence: 0.88,
        category: InsightCategory.steps,
      ));
    } else if (avgSteps < 4000) {
      advice.add(AiInsight(
        title: 'Больше ходи',
        description: 'Среднее — ${avgSteps.round()} шагов. Попробуй ходить пешком до магазина или на остановку.',
        type: InsightType.advice,
        confidence: 0.76,
        category: InsightCategory.steps,
      ));
    }
  }

  // ── Habits analysis ──

  void _analyzeHabits(List<Habit> habits, List<AiInsight> pos, List<AiInsight> advice) {
    if (habits.isEmpty) return;

    final now = DateTime.now();
    final activeHabits = habits.where((h) => h.totalCompletions >= 4).toList();
    final streaks = habits.map((h) => h.streak(now)).toList();
    final maxStreak = streaks.isEmpty ? 0 : streaks.reduce((a, b) => a > b ? a : b);

    if (activeHabits.length >= 3) {
      pos.add(AiInsight(
        title: 'Сильная система привычек',
        description: '${activeHabits.length} привычек с 4+ выполнениями. Система работает!',
        type: InsightType.positive,
        confidence: 0.85,
        category: InsightCategory.habits,
      ));
    }

    if (maxStreak >= 7) {
      pos.add(AiInsight(
        title: 'Серия $maxStreak дней',
        description: 'Максимальная серия без пропусков — $maxStreak дней. Отличная дисциплина!',
        type: InsightType.record,
        confidence: 0.90,
        category: InsightCategory.habits,
      ));
    }

    final brokenHabits = habits.where((h) => h.totalCompletions >= 3 && h.streak(now) == 0).toList();
    if (brokenHabits.isNotEmpty) {
      advice.add(AiInsight(
        title: 'Верни привычку',
        description: '"${brokenHabits.first.title}" — пропущена. Начни снова сегодня, не откладывай.',
        type: InsightType.advice,
        confidence: 0.72,
        category: InsightCategory.habits,
      ));
    }
  }

  // ── Goals analysis ──

  void _analyzeGoals(List<LifeGoal> goals, List<AiInsight> advice) {
    if (goals.isEmpty) return;

    final active = goals.where((g) => !g.achieved).toList();
    final achieved = goals.where((g) => g.achieved).toList();

    if (achieved.isNotEmpty) {
      advice.add(AiInsight(
        title: '${achieved.length} целей достигнуто',
        description: 'Поставь новые цели, чтобы сохранить мотивацию.',
        type: InsightType.goal,
        confidence: 0.80,
        category: InsightCategory.goals,
      ));
    }

    for (final goal in active.take(2)) {
      if (goal.progress < 0.3 && goal.dueDate.difference(DateTime.now()).inDays < 14) {
        advice.add(AiInsight(
          title: 'Цель "${goal.title}" под угрозой',
          description: 'Прогресс ${(goal.progress * 100).round()}%, а дедлайн через ${goal.dueDate.difference(DateTime.now()).inDays} дн.',
          type: InsightType.goal,
          confidence: 0.78,
          category: InsightCategory.goals,
        ));
      }
    }
  }

  // ── Pattern analysis ──

  void _analyzePatterns(List<DayEntry> data, List<AiInsight> patterns) {
    if (data.length < 14) return;

    // Weekday vs weekend
    final weekday = <DayEntry>[];
    final weekend = <DayEntry>[];
    for (final e in data) {
      if (e.date.weekday >= 6) {
        weekend.add(e);
      } else {
        weekday.add(e);
      }
    }

    if (weekday.length >= 5 && weekend.length >= 3) {
      final wdProd = weekday.map((e) => e.productivityScore).fold<double>(0, (s, e) => s + e) / weekday.length;
      final weProd = weekend.map((e) => e.productivityScore).fold<double>(0, (s, e) => s + e) / weekend.length;

      if (wdProd - weProd > 15) {
        patterns.add(AiInsight(
          title: 'Выходные менее продуктивны',
          description: 'В будни продуктивность на ${(wdProd - weProd).round()} пунктов выше.',
          type: InsightType.pattern,
          confidence: 0.70,
          category: InsightCategory.productivity,
        ));
      }
    }

    // Best day of week
    final dayOfWeekScores = <int, List<double>>{};
    for (final e in data) {
      dayOfWeekScores.putIfAbsent(e.date.weekday, () => []).add(e.lifeIndex.toDouble());
    }
    var bestDay = 0;
    var bestAvg = 0.0;
    dayOfWeekScores.forEach((day, scores) {
      final avg = scores.fold<double>(0, (s, e) => s + e) / scores.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestDay = day;
      }
    });
    if (bestDay > 0) {
      final dayNames = ['', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
      patterns.add(AiInsight(
        title: 'Лучший день — ${dayNames[bestDay]}',
        description: 'Средний индекс ${bestAvg.round()} баллов.',
        type: InsightType.pattern,
        confidence: 0.68,
        category: InsightCategory.general,
      ));
    }

    // Worst day of week
    var worstDay = 0;
    var worstAvg = 100.0;
    dayOfWeekScores.forEach((day, scores) {
      final avg = scores.fold<double>(0, (s, e) => s + e) / scores.length;
      if (avg < worstAvg) {
        worstAvg = avg;
        worstDay = day;
      }
    });
    if (worstDay > 0 && worstDay != bestDay) {
      final dayNames = ['', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
      patterns.add(AiInsight(
        title: 'Сложный день — ${dayNames[worstDay]}',
        description: 'Средний индекс ${worstAvg.round()} баллов. Попробуй снизить нагрузку.',
        type: InsightType.pattern,
        confidence: 0.65,
        category: InsightCategory.general,
      ));
    }

    // Consecutive bad days detection
    _detectBadStreaks(data, patterns);
  }

  void _detectBadStreaks(List<DayEntry> data, List<AiInsight> patterns) {
    var maxBadStreak = 0;
    var currentBadStreak = 0;
    for (final e in data) {
      if (e.lifeIndex < 40) {
        currentBadStreak++;
        if (currentBadStreak > maxBadStreak) maxBadStreak = currentBadStreak;
      } else {
        currentBadStreak = 0;
      }
    }
    if (maxBadStreak >= 3) {
      patterns.add(AiInsight(
        title: 'Серия из $maxBadStreak сложных дней',
        description: 'Обнаружен затяжной спад. Это сигнал для отдыха или смены обстановки.',
        type: InsightType.negative,
        confidence: 0.82,
        category: InsightCategory.general,
      ));
    }
  }

  // ── Records analysis ──

  void _analyzeRecords(List<DayEntry> data, List<AiInsight> records) {
    if (data.length < 7) return;

    final last7 = data.length > 7 ? data.sublist(data.length - 7) : data;
    final prev = data.length > 7 ? data.sublist(0, data.length - 7) : <DayEntry>[];

    if (prev.isNotEmpty) {
      final bestRecent = last7.reduce((a, b) => a.lifeIndex >= b.lifeIndex ? a : b);
      final bestPrev = prev.reduce((a, b) => a.lifeIndex >= b.lifeIndex ? a : b);

      if (bestRecent.lifeIndex > bestPrev.lifeIndex) {
        records.add(AiInsight(
          title: 'Новый рекорд!',
          description: 'Индекс ${bestRecent.lifeIndex} — лучший результат за всё время.',
          type: InsightType.record,
          confidence: 0.92,
          category: InsightCategory.general,
        ));
      }
    }

    // Best mood day
    final bestMoodDay = data.reduce((a, b) => a.mood >= b.mood ? a : b);
    if (bestMoodDay.mood >= 9) {
      records.add(AiInsight(
        title: 'Лучшее настроение',
        description: '${bestMoodDay.mood}/10 — ${DateFormat('dd.MM').format(bestMoodDay.date)}.',
        type: InsightType.record,
        confidence: 0.85,
        category: InsightCategory.mood,
      ));
    }

    // Most steps
    final bestStepsDay = data.reduce((a, b) => a.steps >= b.steps ? a : b);
    if (bestStepsDay.steps >= 15000) {
      records.add(AiInsight(
        title: 'Рекорд шагов',
        description: '${bestStepsDay.steps} шагов — ${DateFormat('dd.MM').format(bestStepsDay.date)}.',
        type: InsightType.record,
        confidence: 0.88,
        category: InsightCategory.steps,
      ));
    }
  }

  // ── Warnings ──

  void _analyzeWarnings(List<DayEntry> last14, List<AiInsight> neg) {
    if (last14.length < 3) return;

    final last3 = last14.length > 3 ? last14.sublist(last14.length - 3) : last14;

    if (last3.every((e) => e.sleepHours < 6)) {
      neg.add(const AiInsight(
        title: '3 дня без нормального сна',
        description: 'Продолжительный недосып ведёт к спаду продуктивности и настроения. Ляг сегодня на час раньше.',
        type: InsightType.negative,
        confidence: 0.85,
        category: InsightCategory.sleep,
      ));
    }

    if (last3.every((e) => e.mood <= 4)) {
      neg.add(const AiInsight(
        title: 'Настроение ниже нормы 3 дня',
        description: 'Прогулка, спорт или отдых могут помочь переломить тренд.',
        type: InsightType.negative,
        confidence: 0.78,
        category: InsightCategory.mood,
      ));
    }

    if (last3.every((e) => (e.screenMinutes + e.gameMinutes) > 300)) {
      neg.add(const AiInsight(
        title: 'Экранное время выше нормы 3 дня',
        description: 'Более 5 часов в день — поставь лимит или замени активностью.',
        type: InsightType.negative,
        confidence: 0.72,
        category: InsightCategory.screenTime,
      ));
    }

    if (last3.every((e) => e.stress >= 8)) {
      neg.add(const AiInsight(
        title: 'Стресс на максимуме 3 дня',
        description: 'Критический уровень стресса. Нужен отдых или разговор с близким.',
        type: InsightType.negative,
        confidence: 0.88,
        category: InsightCategory.stress,
      ));
    }

    if (last3.every((e) => e.energy <= 3)) {
      neg.add(const AiInsight(
        title: 'Энергия на нуле 3 дня',
        description: 'Проверь сон, питание и физическую активность.',
        type: InsightType.negative,
        confidence: 0.83,
        category: InsightCategory.energy,
      ));
    }
  }

  // ── Advice generation ──

  void _generateAdvice(List<DayEntry> last30, List<DayEntry> all,
      List<AiInsight> advice, UserProfile? profile) {
    if (last30.isEmpty) return;

    final avgIndex = last30.map((e) => e.lifeIndex).fold<double>(0, (s, e) => s + e) / last30.length;
    final name = profile?.name.trim();

    if (avgIndex >= 75) {
      advice.add(AiInsight(
        title: 'Закрепи удачный режим',
        description: 'Средний индекс ${avgIndex.round()} — это хороший результат. Сохрани текущие привычки.',
        type: InsightType.advice,
        confidence: 0.82,
        category: InsightCategory.general,
      ));
    } else if (avgIndex >= 55) {
      advice.add(AiInsight(
        title: 'Есть потенциал для роста',
        description: 'Средний индекс ${avgIndex.round()}. Сфокусируйся на сне и активности — это даст быстрый эффект.',
        type: InsightType.advice,
        confidence: 0.78,
        category: InsightCategory.general,
      ));
    } else {
      advice.add(AiInsight(
        title: 'Начни с двух рычагов',
        description: 'Сон 7+ часов и минус 45 минут экранного времени — это самые быстрые улучшения.',
        type: InsightType.advice,
        confidence: 0.80,
        category: InsightCategory.general,
      ));
    }

    if (name != null && name.isNotEmpty) {
      advice.add(AiInsight(
        title: '$name, заполняй день вечером',
        description: 'Короткая вечерняя отметка помогает точнее подбирать рекомендации.',
        type: InsightType.advice,
        confidence: 0.76,
        category: InsightCategory.general,
      ));
    }

    // Profile-specific advice
    if (profile != null) {
      if (profile.age < 20) {
        advice.add(AiInsight(
          title: 'Сон важен для роста',
          description: 'В твоём возрасте нужно 8–10 часов сна. Мозг формируется во сне.',
          type: InsightType.advice,
          confidence: 0.85,
          category: InsightCategory.sleep,
        ));
      }

      final bmi = profile.weightKg / ((profile.heightCm / 100) * (profile.heightCm / 100));
      if (bmi > 0) {
        if (bmi > 30) {
          advice.add(AiInsight(
            title: 'Индекс массы тела повышен',
            description: 'BMI ${bmi.toStringAsFixed(1)}. Регулярная активность и контроль калорий помогут.',
            type: InsightType.advice,
            confidence: 0.75,
            category: InsightCategory.nutrition,
          ));
        } else if (bmi < 18.5) {
          advice.add(AiInsight(
            title: 'Индекс массы тела низкий',
            description: 'BMI ${bmi.toStringAsFixed(1)}. Убедись, что получаешь достаточно калорий.',
            type: InsightType.advice,
            confidence: 0.73,
            category: InsightCategory.nutrition,
          ));
        }
      }
    }
  }

  // ── Forecast ──

  List<AiInsight> _buildForecast(List<DayEntry> sorted) {
    final forecast = <AiInsight>[];

    if (sorted.length >= 7) {
      final last7 = sorted.sublist(sorted.length - 7);
      final prev7 = sorted.length >= 14
          ? sorted.sublist(sorted.length - 14, sorted.length - 7)
          : <DayEntry>[];

      final last7Avg = last7.map((e) => e.lifeIndex).fold<double>(0, (s, e) => s + e) / last7.length;

      if (prev7.isNotEmpty) {
        final prev7Avg = prev7.map((e) => e.lifeIndex).fold<double>(0, (s, e) => s + e) / prev7.length;
        final diff = last7Avg - prev7Avg;

        if (diff > 5) {
          forecast.add(AiInsight(
            title: 'Неделя лучше прошлой',
            description: 'Индекс вырос на ${diff.round()} пунктов. Тренд положительный!',
            type: InsightType.forecast,
            confidence: 0.75,
          ));
        } else if (diff < -5) {
          forecast.add(AiInsight(
            title: 'Неделя хуже прошлой',
            description: 'Индекс упал на ${diff.abs().round()} пунктов. Время восстановить режим.',
            type: InsightType.forecast,
            confidence: 0.72,
          ));
        } else {
          forecast.add(const AiInsight(
            title: 'Неделя стабильна',
            description: 'Индекс держится на том же уровне. Стабильность — хороший знак.',
            type: InsightType.forecast,
            confidence: 0.68,
          ));
        }
      }

      final slope = _linearSlope(last7.map((e) => e.lifeIndex.toDouble()).toList());
      final projected = (last7Avg + slope * 7).round().clamp(0, 100);
      forecast.add(AiInsight(
        title: 'Прогноз на следующую неделю',
        description: 'При текущем темпе индекс будет около $projected.',
        type: InsightType.forecast,
        confidence: 0.62,
      ));

      // Sleep forecast
      final sleepSlope = _linearSlope(last7.map((e) => e.sleepHours).toList());
      final avgSleep = last7.map((e) => e.sleepHours).fold<double>(0, (s, e) => s + e) / last7.length;
      final projectedSleep = (avgSleep + sleepSlope * 7).clamp(3, 12);
      if (sleepSlope.abs() > 0.1) {
        forecast.add(AiInsight(
          title: sleepSlope > 0 ? 'Сон улучшается' : 'Сон ухудшается',
          description: 'Прогноз: ${projectedSleep.toStringAsFixed(1)} часов.',
          type: InsightType.forecast,
          confidence: 0.60,
          category: InsightCategory.sleep,
        ));
      }
    } else {
      final avg = sorted.map((e) => e.lifeIndex).fold<double>(0, (s, e) => s + e) / sorted.length;
      forecast.add(AiInsight(
        title: 'Прогноз недели',
        description: avg >= 70
            ? 'Если текущий ритм сохранится, неделя останется в зелёной зоне.'
            : 'Без восстановления сна и активности неделя может остаться в жёлтой зоне.',
        type: InsightType.forecast,
        confidence: 0.68,
      ));
    }

    return forecast;
  }

  // ── Dimension scores ──

  List<DimensionScore> _buildDimensions(List<DayEntry> last30, List<Habit> habits, List<LifeGoal> goals) {
    if (last30.isEmpty) return [];

    final dims = <DimensionScore>[];

    // Sleep dimension
    final avgSleep = last30.map((e) => e.sleepHours).fold<double>(0, (s, e) => s + e) / last30.length;
    final sleepScore = _sleepDimensionScore(avgSleep);
    dims.add(DimensionScore(
      label: 'Сон',
      score: sleepScore,
      maxScore: 100,
      icon: 'bedtime',
      detail: '${avgSleep.toStringAsFixed(1)} ч/день',
    ));

    // Mood dimension
    final avgMood = last30.map((e) => e.mood).fold<double>(0, (s, e) => s + e) / last30.length;
    dims.add(DimensionScore(
      label: 'Настроение',
      score: avgMood * 10,
      maxScore: 100,
      icon: 'sentiment_satisfied',
      detail: '${avgMood.toStringAsFixed(1)}/10',
    ));

    // Productivity dimension
    final avgProd = last30.map((e) => e.productivityScore).fold<double>(0, (s, e) => s + e) / last30.length;
    dims.add(DimensionScore(
      label: 'Продуктивность',
      score: avgProd,
      maxScore: 100,
      icon: 'trending_up',
      detail: '${avgProd.round()}/100',
    ));

    // Energy dimension
    final avgEnergy = last30.map((e) => e.energy).fold<double>(0, (s, e) => s + e) / last30.length;
    dims.add(DimensionScore(
      label: 'Энергия',
      score: avgEnergy * 10,
      maxScore: 100,
      icon: 'bolt',
      detail: '${avgEnergy.toStringAsFixed(1)}/10',
    ));

    // Stress dimension (inverted)
    final avgStress = last30.map((e) => e.stress).fold<double>(0, (s, e) => s + e) / last30.length;
    dims.add(DimensionScore(
      label: 'Стресс',
      score: (10 - avgStress) * 10,
      maxScore: 100,
      icon: 'psychology',
      detail: '${avgStress.toStringAsFixed(1)}/10',
    ));

    // Sport dimension
    final avgSport = last30.map((e) => e.sportMinutes).fold<double>(0, (s, e) => s + e) / last30.length;
    dims.add(DimensionScore(
      label: 'Активность',
      score: (avgSport / 60 * 100).clamp(0, 100),
      maxScore: 100,
      icon: 'fitness_center',
      detail: '${avgSport.round()} мин/день',
    ));

    // Steps dimension
    final avgSteps = last30.map((e) => e.steps).fold<double>(0, (s, e) => s + e) / last30.length;
    dims.add(DimensionScore(
      label: 'Шаги',
      score: (avgSteps / 10000 * 100).clamp(0, 100),
      maxScore: 100,
      icon: 'directions_walk',
      detail: '${avgSteps.round()} шагов/день',
    ));

    // Habits dimension
    if (habits.isNotEmpty) {
      final now = DateTime.now();
      final avgStreak = habits.map((h) => h.streak(now)).fold<double>(0, (s, e) => s + e) / habits.length;
      dims.add(DimensionScore(
        label: 'Привычки',
        score: (avgStreak / 14 * 100).clamp(0, 100),
        maxScore: 100,
        icon: 'check_circle',
        detail: 'Серия ${(avgStreak).round()} дн',
      ));
    }

    return dims;
  }

  double _sleepDimensionScore(double hours) {
    if (hours >= 7 && hours <= 8.5) return 100;
    if (hours >= 6.5 && hours < 7) return 80;
    if (hours > 8.5 && hours <= 9) return 75;
    if (hours >= 6 && hours < 6.5) return 60;
    if (hours > 9 && hours <= 10) return 55;
    if (hours >= 5 && hours < 6) return 40;
    if (hours < 5) return 20;
    return 50;
  }

  // ── Health & Stability scores ──

  int _calculateHealthScore(List<DayEntry> last30) {
    if (last30.isEmpty) return 0;

    var score = 0.0;
    final count = last30.length;

    final avgSleep = last30.map((e) => e.sleepHours).fold<double>(0, (s, e) => s + e) / count;
    final avgMood = last30.map((e) => e.mood).fold<double>(0, (s, e) => s + e) / count;
    final avgEnergy = last30.map((e) => e.energy).fold<double>(0, (s, e) => s + e) / count;
    final avgSport = last30.map((e) => e.sportMinutes).fold<double>(0, (s, e) => s + e) / count;
    final avgSteps = last30.map((e) => e.steps).fold<double>(0, (s, e) => s + e) / count;
    final avgWater = last30.map((e) => e.waterLiters).fold<double>(0, (s, e) => s + e) / count;
    final avgStress = last30.map((e) => e.stress).fold<double>(0, (s, e) => s + e) / count;

    score += _sleepDimensionScore(avgSleep) * 0.25;
    score += avgMood * 10 * 0.20;
    score += avgEnergy * 10 * 0.15;
    score += (avgSport / 60 * 100).clamp(0, 100) * 0.10;
    score += (avgSteps / 10000 * 100).clamp(0, 100) * 0.10;
    score += (avgWater / 2.5 * 100).clamp(0, 100) * 0.10;
    score += (10 - avgStress) * 10 * 0.10;

    return score.round().clamp(0, 100);
  }

  int _calculateStabilityScore(List<DayEntry> last14) {
    if (last14.length < 3) return 50;

    final indices = last14.map((e) => e.lifeIndex.toDouble()).toList();
    final stdDev = _stdDev(indices);
    final stability = (100 - stdDev * 2).clamp(0, 100);
    return stability.round();
  }

  // ── Day persona ──

  String _buildDayPersona(DayEntry entry) {
    final parts = <String>[];

    if (entry.lifeIndex >= 80) {
      parts.add('productivity rockstar');
    } else if (entry.lifeIndex >= 60) {
      parts.add('стабильный день');
    } else if (entry.lifeIndex >= 40) {
      parts.add('день на паузе');
    } else {
      parts.add('сложный день');
    }

    if (entry.mood >= 8) {
      parts.add('отличное настроение');
    } else if (entry.mood <= 4) {
      parts.add('настроение на нуле');
    }

    if (entry.sportMinutes >= 60) {
      parts.add('активный');
    }

    if (entry.sleepHours >= 8) {
      parts.add('выспавшийся');
    } else if (entry.sleepHours < 6) {
      parts.add('не выспался');
    }

    return parts.join(' · ');
  }

  // ── Summary ──

  String _buildSummary(List<DayEntry> last30, int healthScore, int stabilityScore, UserProfile? profile) {
    if (last30.isEmpty) return 'Недостаточно данных для анализа.';

    final name = profile?.name.trim();
    final greeting = name != null && name.isNotEmpty ? '$name, ' : '';
    final avgIndex = last30.map((e) => e.lifeIndex).fold<double>(0, (s, e) => s + e) / last30.length;

    String healthLabel;
    if (healthScore >= 80) {
      healthLabel = 'отличное';
    } else if (healthScore >= 65) {
      healthLabel = 'хорошее';
    } else if (healthScore >= 50) {
      healthLabel = 'нормальное';
    } else {
      healthLabel = 'ниже нормы';
    }

    String stabilityLabel;
    if (stabilityScore >= 80) {
      stabilityLabel = 'стабильный';
    } else if (stabilityScore >= 60) {
      stabilityLabel = 'умеренно стабильный';
    } else {
      stabilityLabel = 'нестабильный';
    }

    return '$greeting твоё здоровье $healthLabel (индекс ${avgIndex.round()}), ритм $stabilityLabel. '
        'Анализ обновлен ${DateFormat('dd.MM HH:mm').format(DateTime.now())}.';
  }

  // ── Helpers ──

  double _stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.fold<double>(0, (s, e) => s + e) / values.length;
    final variance = values.fold<double>(0, (s, e) => s + (e - mean) * (e - mean)) / values.length;
    return _sqrt(variance);
  }

  double _trend(List<double> values) {
    if (values.length < 3) return 0;
    final slope = _linearSlope(values);
    final mean = values.fold<double>(0, (s, e) => s + e) / values.length;
    return mean == 0 ? 0 : slope / mean;
  }

  double _linearSlope(List<double> values) {
    final n = values.length;
    if (n < 2) return 0;
    var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0;
    for (var i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return 0;
    return (n * sumXY - sumX * sumY) / denom;
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    var guess = value / 2;
    for (var i = 0; i < 12; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  AiAnalysis _emptyAnalysis() {
    return AiAnalysis(
      generatedAt: DateTime.now(),
      positive: const [],
      negative: const [],
      advice: const [
        AiInsight(
          title: 'Нужны первые данные',
          description: 'Заполни хотя бы один день, и AI Engine начнет искать связи и давать рекомендации.',
          type: InsightType.advice,
          confidence: 0.95,
        ),
      ],
      forecast: const [],
      patterns: const [],
      records: const [],
      dimensions: const [],
      summary: 'Недостаточно данных для анализа.',
      dayPersona: 'Нет данных',
      healthScore: 0,
      stabilityScore: 0,
    );
  }
}

class _CorrPair {
  const _CorrPair(this.name, this.label, this.left, this.right);

  final String name;
  final String label;
  final Iterable<num> left;
  final Iterable<num> right;
}
