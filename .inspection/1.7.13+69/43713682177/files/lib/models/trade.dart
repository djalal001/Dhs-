enum TradeSide { buy, sell }

enum TradeExecutionStatus {
  followedPlan,
  avoidedEntryBecauseFear,
  enteredEarly,
  entryConditionsNotMet,
  missedHigherTimeframeBounceArea,
  missedLowerTimeframeBounceArea,
  missedTrendlineFromCandleWicks,
  hesitationPartialSize,
  lateEntry,
  stopLossMoved,
  noBreakoutPositiveClose,
  exitedEarlyBecauseFearOfLosingProfit,
}

/// Whether the trader stuck to their strategy on a trade. Null means the
/// trader has not answered yet.
enum StrategyAdherence {
  followed,
  notFollowed;

  static StrategyAdherence? tryParse(Object? source) {
    for (final value in StrategyAdherence.values) {
      if (value.name == source) return value;
    }
    return null;
  }
}

class TradeExecutionJournalEntry {
  const TradeExecutionJournalEntry({required this.status});

  final TradeExecutionStatus status;

  Map<String, Object?> toJson() => {'status': status.name};

  static TradeExecutionJournalEntry? tryFromJson(Object? source) {
    final name = source is Map ? source['status'] : source;
    TradeExecutionStatus? status;
    if (name == 'enteredEarlyOrOutsidePlan' || name == 'enteredEarly') {
      // Migrate both the old flat label and the earlier phase-based label.
      status = TradeExecutionStatus.enteredEarly;
    } else {
      for (final value in TradeExecutionStatus.values) {
        if (value.name == name) {
          status = value;
          break;
        }
      }
    }
    return status == null ? null : TradeExecutionJournalEntry(status: status);
  }

  @override
  bool operator ==(Object other) =>
      other is TradeExecutionJournalEntry && other.status == status;

  @override
  int get hashCode => status.hashCode;
}

class TradeEntrySetup {
  const TradeEntrySetup({required this.reason, required this.timeframe});

  final String reason;
  final String timeframe;

  Map<String, Object?> toJson() => {'reason': reason, 'timeframe': timeframe};

  factory TradeEntrySetup.fromJson(Map<String, dynamic> json) =>
      TradeEntrySetup(
        reason: json['reason'] as String? ?? '',
        timeframe: json['timeframe'] as String? ?? '',
      );

  String get label => timeframe.isEmpty ? reason : '$reason $timeframe';

  @override
  bool operator ==(Object other) =>
      other is TradeEntrySetup &&
      other.reason == reason &&
      other.timeframe == timeframe;

  @override
  int get hashCode => Object.hash(reason, timeframe);
}

class TradeEntryConditionSetup {
  const TradeEntryConditionSetup({
    required this.optionKey,
    required this.timeframe,
    this.secondaryTimeframe,
  });

  final String optionKey;
  final String timeframe;
  /// Used by the combined Trendline + Supply Zone bounce condition.
  final String? secondaryTimeframe;

  Map<String, Object?> toJson() => {
    'optionKey': optionKey,
    'timeframe': timeframe,
    if (secondaryTimeframe != null) 'secondaryTimeframe': secondaryTimeframe,
  };

  factory TradeEntryConditionSetup.fromJson(Map<String, dynamic> json) =>
      TradeEntryConditionSetup(
        optionKey: json['optionKey'] as String? ?? '',
        timeframe: json['timeframe'] as String? ?? '',
        secondaryTimeframe: json['secondaryTimeframe'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is TradeEntryConditionSetup &&
      other.optionKey == optionKey &&
      other.timeframe == timeframe &&
      other.secondaryTimeframe == secondaryTimeframe;

  @override
  int get hashCode => Object.hash(optionKey, timeframe, secondaryTimeframe);
}

class TradeConfirmationSetup {
  const TradeConfirmationSetup({required this.type, required this.timeframe});

  final String type;
  final String timeframe;

  Map<String, Object?> toJson() => {'type': type, 'timeframe': timeframe};

  factory TradeConfirmationSetup.fromJson(Map<String, dynamic> json) =>
      TradeConfirmationSetup(
        type: json['type'] as String? ?? '',
        timeframe: json['timeframe'] as String? ?? '',
      );

  String get label => timeframe.isEmpty ? type : '$type $timeframe';

  @override
  bool operator ==(Object other) =>
      other is TradeConfirmationSetup &&
      other.type == type &&
      other.timeframe == timeframe;

  @override
  int get hashCode => Object.hash(type, timeframe);
}

class Trade {
  const Trade({
    required this.id,
    required this.accountId,
    required this.market,
    required this.reason,
    required this.result,
    required this.riskPercent,
    required this.side,
    required this.confirmation,
    required this.sequence,
    required this.mood,
    required this.tradedAt,
    this.entryTimeframe,
    this.entrySetups = const [],
    this.confirmationSetups = const [],
    this.reverseSignalSetups = const [],
    this.bounceZoneSetups = const [],
    this.executionJournal = const [],
    this.executionReviewKeys = const [],
    this.noEntryReasons = const [],
    this.beforeImagePath,
    this.afterImagePath,
    this.confirmationImagePath,
    this.expectedLoss,
    this.notes = '',
    this.strategyAdherence,
  });

  final String id;
  final String accountId;
  final String market;
  final String reason;
  final double result;
  final double riskPercent;
  final TradeSide side;
  final String confirmation;
  final String sequence;
  final String mood;
  final DateTime tradedAt;
  final String? entryTimeframe;
  final List<TradeEntrySetup> entrySetups;
  final List<TradeConfirmationSetup> confirmationSetups;
  /// Conditions that opposed the trade direction at the entry area.
  final List<TradeEntryConditionSetup> reverseSignalSetups;
  /// Price-action / structure conditions around the bounce area.
  final List<TradeEntryConditionSetup> bounceZoneSetups;
  final List<TradeExecutionJournalEntry> executionJournal;
  /// Windows trade-entry review selections: execution decisions and plan commitment.
  final List<String> executionReviewKeys;
  /// Windows trade-entry reasons for not taking a setup.
  final List<String> noEntryReasons;
  final String? beforeImagePath;
  final String? afterImagePath;
  final String? confirmationImagePath;
  final double? expectedLoss;
  final String notes;
  final StrategyAdherence? strategyAdherence;

  Trade withStrategyAdherence(StrategyAdherence value) => Trade(
    id: id,
    accountId: accountId,
    market: market,
    reason: reason,
    result: result,
    riskPercent: riskPercent,
    side: side,
    confirmation: confirmation,
    sequence: sequence,
    mood: mood,
    tradedAt: tradedAt,
    entryTimeframe: entryTimeframe,
    entrySetups: entrySetups,
    confirmationSetups: confirmationSetups,
    reverseSignalSetups: reverseSignalSetups,
    bounceZoneSetups: bounceZoneSetups,
    executionJournal: executionJournal,
    executionReviewKeys: executionReviewKeys,
    noEntryReasons: noEntryReasons,
    beforeImagePath: beforeImagePath,
    afterImagePath: afterImagePath,
    confirmationImagePath: confirmationImagePath,
    expectedLoss: expectedLoss,
    notes: notes,
    strategyAdherence: value,
  );

  /// Migrates the single reason/timeframe fields from older app versions.
  List<TradeEntrySetup> get effectiveEntrySetups {
    if (entrySetups.isNotEmpty) return entrySetups;
    if (reason.isEmpty) return const [];
    return [TradeEntrySetup(reason: reason, timeframe: entryTimeframe ?? '')];
  }

  String get entrySetupSummary =>
      effectiveEntrySetups.map((setup) => setup.label).join('، ');

  /// Migrates the old single confirmation field when no structured setups exist.
  List<TradeConfirmationSetup> get effectiveConfirmationSetups {
    if (confirmationSetups.isNotEmpty) return confirmationSetups;
    if (confirmation.isEmpty) return const [];
    return [TradeConfirmationSetup(type: confirmation, timeframe: '')];
  }

  String get confirmationSetupSummary =>
      effectiveConfirmationSetups.map((setup) => setup.label).join('، ');

  Map<String, Object?> toJson() => {
    'id': id,
    'accountId': accountId,
    'market': market,
    'reason': reason,
    'result': result,
    'riskPercent': riskPercent,
    'side': side.name,
    'confirmation': confirmation,
    'sequence': sequence,
    'mood': mood,
    'tradedAt': tradedAt.toIso8601String(),
    'entryTimeframe': entryTimeframe,
    'entrySetups': effectiveEntrySetups.map((setup) => setup.toJson()).toList(),
    'confirmationSetups': confirmationSetups
        .map((setup) => setup.toJson())
        .toList(),
    'reverseSignalSetups': reverseSignalSetups
        .map((setup) => setup.toJson())
        .toList(),
    'bounceZoneSetups': bounceZoneSetups
        .map((setup) => setup.toJson())
        .toList(),
    'executionJournal': executionJournal
        .map((entry) => entry.toJson())
        .toList(),
    'executionReviewKeys': executionReviewKeys,
    'noEntryReasons': noEntryReasons,
    'beforeImagePath': beforeImagePath,
    'afterImagePath': afterImagePath,
    'confirmationImagePath': confirmationImagePath,
    'expectedLoss': expectedLoss,
    'notes': notes,
    'strategyAdherence': strategyAdherence?.name,
  };

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
    id: json['id'] as String,
    accountId: json['accountId'] as String? ?? '',
    market: json['market'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    result: _finiteNumber(json['result']),
    riskPercent: _finiteNumber(json['riskPercent']),
    side: TradeSide.values.firstWhere(
      (value) => value.name == json['side'],
      orElse: () => TradeSide.buy,
    ),
    confirmation: json['confirmation'] as String? ?? '',
    sequence: json['sequence'] as String? ?? '',
    mood: json['mood'] as String? ?? '',
    tradedAt:
        DateTime.tryParse(json['tradedAt'] as String? ?? '') ?? DateTime.now(),
    entryTimeframe: json['entryTimeframe'] as String?,
    entrySetups:
        (json['entrySetups'] as List<dynamic>?)
            ?.whereType<Map>()
            .map(
              (value) =>
                  TradeEntrySetup.fromJson(Map<String, dynamic>.from(value)),
            )
            .toList() ??
        const [],
    confirmationSetups:
        (json['confirmationSetups'] as List<dynamic>?)
            ?.whereType<Map>()
            .map(
              (value) => TradeConfirmationSetup.fromJson(
                Map<String, dynamic>.from(value),
              ),
            )
            .toList() ??
        const [],
    reverseSignalSetups: _entryConditionSetupsFromJson(json['reverseSignalSetups']),
    bounceZoneSetups: _entryConditionSetupsFromJson(json['bounceZoneSetups']),
    executionJournal: _executionJournalFromJson(json['executionJournal']),
    executionReviewKeys: _stringListFromJson(json['executionReviewKeys']),
    noEntryReasons: _stringListFromJson(json['noEntryReasons']),
    beforeImagePath: json['beforeImagePath'] as String?,
    afterImagePath: json['afterImagePath'] as String?,
    confirmationImagePath: json['confirmationImagePath'] as String?,
    expectedLoss: _optionalFiniteNonNegativeNumber(json['expectedLoss']),
    notes: json['notes'] as String? ?? '',
    strategyAdherence: StrategyAdherence.tryParse(json['strategyAdherence']),
  );
}

List<TradeEntryConditionSetup> _entryConditionSetupsFromJson(Object? source) {
  if (source is! List) return const [];
  return source
      .whereType<Map>()
      .map((value) => TradeEntryConditionSetup.fromJson(
            Map<String, dynamic>.from(value),
          ))
      .where((value) => value.optionKey.isNotEmpty && value.timeframe.isNotEmpty)
      .toList(growable: false);
}

List<TradeExecutionJournalEntry> _executionJournalFromJson(Object? source) {
  if (source is! List) return const [];
  final entries = <TradeExecutionJournalEntry>{};
  for (final value in source) {
    final entry = TradeExecutionJournalEntry.tryFromJson(value);
    if (entry != null) entries.add(entry);
  }
  return entries.toList(growable: false);
}

double _finiteNumber(Object? value) {
  final parsed = value is num ? value.toDouble() : 0.0;
  return parsed.isFinite ? parsed : 0.0;
}

double? _optionalFiniteNonNegativeNumber(Object? value) {
  if (value is! num) return null;
  final parsed = value.toDouble();
  return parsed.isFinite && parsed >= 0 ? parsed : null;
}

List<String> _stringListFromJson(Object? source) {
  if (source is! List) return const [];
  return source.whereType<String>().map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList(growable: false);
}
