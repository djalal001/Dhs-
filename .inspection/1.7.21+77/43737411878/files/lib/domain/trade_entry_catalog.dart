import '../models/trade.dart';

class TradeEntryOption {
  const TradeEntryOption(this.key, this.ar, this.en);
  final String key;
  final String ar;
  final String en;
}

class TradeReviewGroup {
  const TradeReviewGroup({required this.titleAr, required this.titleEn, required this.options, this.noteAr, this.noteEn});
  final String titleAr;
  final String titleEn;
  final String? noteAr;
  final String? noteEn;
  final List<TradeEntryOption> options;
}

const tradeEntryTimeframes = <String>['1MIN', '2MIN', '3MIN', '5MIN', '15MIN', '30MIN', '1H', '4H'];

/// Formats the saved/selected label for an Entry Conditions choice.
/// Keep timeframes adjacent to their descriptions, without decorative dots.
String formatTradeEntryConditionSetupLabel({
  required TradeEntryConditionSetup setup,
  required String optionLabel,
  required bool arabic,
  TradeSide? side,
}) {
  if (setup.optionKey == 'bounceFromTrendlineAndSupplyZone') {
    final prefix = arabic ? 'ارتداد من' : 'Bounce from';
    return '$prefix Trend Line ${setup.timeframe} - Supply Zone ${setup.secondaryTimeframe ?? '—'}';
  }

  // Keep the option list's generic S/R wording until a direction is chosen.
  // Once selected, show the actual side-specific market level in the trade.
  if (setup.optionKey == 'bounceFromSrZone' && side != null) {
    final directionalLabel = arabic
        ? (side == TradeSide.buy
            ? 'ارتداد من منطقة دعم'
            : 'ارتداد من منطقة مقاومة')
        : (side == TradeSide.buy
            ? 'Bounce from support'
            : 'Bounce from resistance');
    return setup.timeframe.isEmpty
        ? directionalLabel
        : '$directionalLabel ${setup.timeframe}';
  }

  return setup.timeframe.isEmpty ? optionLabel : '$optionLabel ${setup.timeframe}';
}

const tradeEntryReasons = <TradeEntryOption>[
  TradeEntryOption('SBR', 'SBR', 'SBR'),
  TradeEntryOption('RBS', 'RBS', 'RBS'),
  TradeEntryOption('RFS', 'RFS', 'RFS'),
  TradeEntryOption('SFR', 'SFR', 'SFR'),
  TradeEntryOption('Trend Line SELL', 'Trend Line SELL', 'Trend Line SELL'),
  TradeEntryOption('Trend Line BREAKOUT SELL', 'Trend Line BREAKOUT SELL', 'Trend Line BREAKOUT SELL'),
  TradeEntryOption('Trend Line BUY', 'Trend Line BUY', 'Trend Line BUY'),
  TradeEntryOption('Trend Line BREAKOUT BUY', 'Trend Line BREAKOUT BUY', 'Trend Line BREAKOUT BUY'),
  TradeEntryOption('HNS', 'HNS', 'HNS'),
  TradeEntryOption('Supply Zone', 'Supply Zone', 'Supply Zone'),
];


/// Touch 2 is an optional qualifier available only for SBR and RBS.
/// It remains encoded in the existing reason string to keep saved trades,
/// backups, CSV exports and analytics fully backward-compatible.
const tradeEntryTouch2EligibleReasons = <String>{'SBR', 'RBS'};

String tradeEntryBaseReason(String reason) {
  for (final base in tradeEntryTouch2EligibleReasons) {
    if (reason == '$base Touch 2') return base;
  }
  return reason;
}

bool tradeEntryUsesTouch2(String reason) =>
    tradeEntryTouch2EligibleReasons.any((base) => reason == '$base Touch 2');

String tradeEntryReasonWithTouch2(String baseReason, bool touch2) =>
    touch2 && tradeEntryTouch2EligibleReasons.contains(baseReason)
        ? '$baseReason Touch 2'
        : baseReason;

const tradeConfirmationOptions = <TradeEntryOption>[
  TradeEntryOption('confirmBearishEngulfing', 'Bearish engulfing', 'Bearish engulfing'),
  TradeEntryOption('confirmBullishEngulfing', 'Bullish Engulfing', 'Bullish Engulfing'),
  TradeEntryOption('confirmHns', 'HNS', 'HNS'),
  TradeEntryOption('confirmBreakoutPullback', 'Breakout–Pullback', 'Breakout–Pullback'),
  TradeEntryOption('confirmEveningStar', 'Evening Star', 'Evening Star'),
  TradeEntryOption('confirmRejectKeyLevel', 'Reject ᴷᵉʸ ᴸᵉᵛᵉˡ', 'Reject Key Level'),
  TradeEntryOption('__custom__', 'مخصص — اكتب النوع', 'Custom — enter type'),
];

const tradeReverseSignalOptions = <TradeEntryOption>[
  TradeEntryOption(
    'negativeCloseAgainstDirection',
    'تشكل اغلاق سلبي لا يدعم الصفقة قبل الارتداد من منطقه الدخول',
    'A negative close formed before the bounce from the entry area and did not support the trade direction',
  ),
  TradeEntryOption(
    'strongRejectionWickAgainstDirection',
    'تشكّل نموذج رفض قوي بذيل طويل لا يدعم اتجاه الصفقة',
    'A strong rejection pattern with a long wick formed against the trade direction',
  ),
];

const tradeBounceZoneOptions = <TradeEntryOption>[
  TradeEntryOption('bounceFromSrZone', 'ارتداد من منطقة S/R', 'Bounce from an S/R zone'),
  TradeEntryOption('internalLiquiditySweep', 'سحب السعر للسيولة من منطقة داخلية', 'Price swept liquidity from an internal area'),
  TradeEntryOption('majorStructureLiquiditySweep', 'سحب السعر للسيولة من هيكل أساسي', 'Price swept liquidity from a major structure'),
  TradeEntryOption('bounceFromTrendline', 'ارتداد من ترند لاين', 'Bounce from a trendline'),
  TradeEntryOption('bounceFromTrendlineAndSupplyZone', 'ارتداد من ترند لاين و Supply Zone', 'Bounce from a trendline and Supply Zone'),
];

const tradeMoodOptions = <TradeEntryOption>[
  TradeEntryOption('moodUnknown', 'غير مسجلة', 'Not recorded'),
  TradeEntryOption('moodCalm', 'هادئ', 'Calm'),
  TradeEntryOption('moodConfident', 'واثق', 'Confident'),
  TradeEntryOption('moodAnxious', 'قلق', 'Anxious'),
  TradeEntryOption('moodImpulsive', 'مندفع', 'Impulsive'),
  TradeEntryOption('moodTired', 'متعب', 'Tired'),
  TradeEntryOption('moodUnsureAnalysis', 'غير واثق من التحليل', 'Unsure about the analysis'),
];

const tradeReviewGroups = <TradeReviewGroup>[
  TradeReviewGroup(
    titleAr: 'مخالفات التنفيذ',
    titleEn: 'Execution violations',
    options: [
      TradeEntryOption('enteredEarly', 'دخلت مبكرًا.', 'Entered early.'),
      TradeEntryOption('hesitationPartialSize', 'بسبب التردد لم أفتح صفقة بالحجم الكامل.', 'I hesitated and did not open the full position size.'),
      TradeEntryOption('lateEntry', 'دخلت متأخرًا.', 'Entered late.'),
      TradeEntryOption('stopLossReducedWithoutReason', 'تغيير وقف الخسارة لتقليل المخاطرة دون سبب منطقي.', 'Reduced stop-loss risk without a logical reason.'),
      TradeEntryOption('stopLossIncreasedWithoutReason', 'تغيير وقف الخسارة لزيادة المخاطرة دون سبب منطقي.', 'Increased stop-loss risk without a logical reason.'),
      TradeEntryOption('exitedEarlyBecauseFearOfLosingProfit', 'لم أحترم الهدف، خرجت مبكرًا بسبب خوف ضياع الأرباح.', 'Exited early out of fear of giving back profit.'),
    ],
  ),
  TradeReviewGroup(
    titleAr: 'جودة التحليل والإعداد',
    titleEn: 'Analysis & setup quality',
    options: [
      TradeEntryOption('missedHigherTimeframeBounceArea', 'لم أنتبه لمنطقة ارتداد في الفريم الأكبر.', 'Missed a higher-timeframe bounce area.'),
      TradeEntryOption('missedLowerTimeframeBounceArea', 'لم أنتبه لمنطقة ارتداد في الفريم الأصغر.', 'Missed a lower-timeframe bounce area.'),
      TradeEntryOption('missedTrendlineFromCandleWicks', 'لم أنتبه لاحتمالية رسم الترند لاين من ذيول الشموع.', 'Missed the possibility of drawing the trendline from candle wicks.'),
      TradeEntryOption('noBreakoutPositiveClose', 'الكسر والإغلاق الإيجابي منخفض القوة.', 'Breakout and positive close lacked strength.'),
      TradeEntryOption('noTrendlineSupportsEntryZone', 'لا يوجد ترند لاين يدعم منطقة الدخول.', 'No trendline supported the entry zone.'),
      TradeEntryOption('missedHigherTimeframeTrendlineIntegration', 'لم أدمج ترند الفريم الأكبر (1h–4h) مع تحليلي.', 'Did not integrate the higher-timeframe (1h–4h) trendline into the analysis.'),
    ],
  ),
  TradeReviewGroup(
    titleAr: 'قرارات الدخول وإدارة المخاطرة',
    titleEn: 'Entry & risk-management decisions',
    noteAr: 'هذه قرارات تحتاج إلى تقييم بحسب خطة التداول؛ اختيارها لا يعني أنها مخالفة أو خطأ.',
    noteEn: 'These decisions should be evaluated against your trading plan; selecting one does not automatically mean it was a mistake.',
    options: [
      TradeEntryOption('stopLossIncreasedForLiquiditySafety', 'زيادة المخاطرة لسبب منطقي: سيولة عالية مع وجود منطقة أمان أبعد قليلًا.', 'Increased risk for a logical reason: high liquidity with a safer area slightly farther away.'),
      TradeEntryOption('stopLossReducedForNegativeClose', 'تقليل المخاطرة لسبب منطقي: إغلاق سلبي لا يدعم اتجاه الصفقة.', 'Reduced risk for a logical reason: a negative close did not support the trade direction.'),
      TradeEntryOption('partialSizeAwaitingDeepCorrection', 'لم أفتح الحجم الكامل انتظارًا لتصحيح أعمق لمنطقة الدخول.', 'Did not open full size while waiting for a deeper retracement into the entry zone.'),
    ],
  ),
];

const tradeCommitmentOptions = <TradeEntryOption>[
  TradeEntryOption('breakevenStopToEntry', 'التزمت بخطة نقل وقف الخسارة إلى نقطة الدخول وخرجت بتعادل.', 'Moved the stop to entry as planned and exited breakeven.'),
  TradeEntryOption('manualExitNearTarget', 'خرجت يدويًا وفق الخطة عندما وصل السعر إلى شبه الهدف.', 'Exited manually as planned when price approached the target.'),
  TradeEntryOption('autoExitAtTarget', 'خرجت تلقائيًا وفق الخطة عندما وصل السعر إلى الهدف المحدد.', 'Exited automatically as planned at the defined target.'),
  TradeEntryOption('enteredDespiteFear', 'التزمت بشروط الدخول رغم شعوري بالخوف من الخسارة.', 'Followed the entry conditions despite feeling fear of loss.'),
  TradeEntryOption('fullPlanCompliance', 'التزمت بالخطة كاملة دون مخالفة.', 'Followed the complete plan without deviation.'),
];

const tradeNoEntryOptions = <TradeEntryOption>[
  TradeEntryOption('fearRepeatLossAfterLoss', 'الخوف من تكرار الخسارة بعد خسارة سابقة.', 'Fear of repeating a loss after a previous losing trade.'),
  TradeEntryOption('fearGivingBackProfit', 'الخوف من خسارة الأرباح بعد صفقة رابحة.', 'Fear of giving back profit after a winning trade.'),
  TradeEntryOption('fearLossNoHistory', 'الخوف من الخسارة دون وجود ربح أو خسارة سابقة.', 'Fear of loss without a prior win or loss.'),
  TradeEntryOption('hesitationUnclearScenario', 'التردد بسبب عدم وضوح السيناريو.', 'Hesitation because the scenario was unclear.'),
  TradeEntryOption('waitedDeeperRetestDespiteConfirmation', 'انتظرت إعادة اختبار أعمق للمنطقة رغم ظهور تأكيد الدخول.', 'Waited for a deeper retest despite an entry confirmation.'),
];

String tradeEntryLabel(String key, {required bool arabic}) {
  for (final option in [...tradeEntryReasons, ...tradeConfirmationOptions, ...tradeMoodOptions, ...tradeCommitmentOptions, ...tradeNoEntryOptions, ...tradeReviewGroups.expand((group) => group.options)]) {
    if (option.key == key) return arabic ? option.ar : option.en;
  }
  return key;
}
