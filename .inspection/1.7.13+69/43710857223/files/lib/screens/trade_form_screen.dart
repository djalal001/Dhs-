import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/trade_entry_catalog.dart';
import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../models/trading_account.dart';
import '../state/app_controller.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/decision_option_emoji.dart';

enum _TradeImageSlot { before, after, confirmation }

// Neutral grayscale tones for consistent trade-entry panels.
const _resultTone = Color(0xFFC4C4C4);
const _dataTone = Color(0xFFBEBEBE);
const _imagesTone = Color(0xFFA5A5A5);
const _behaviorTone = Color(0xFFB8B8B8);
const _decisionTone = Color(0xFFC8C8C8);
const _commitmentTone = Color(0xFFB0B0B0);
const _noEntryTone = Color(0xFF929292);
const _entryConditionsTone = Color(0xFFB0B0B0);
const _reverseSignalsTone = Color(0xFF929292);
const _bounceZoneTone = Color(0xFF808080);

Color _toneForMode(Color tone, bool isDark) {
  if (isDark) return tone;
  if (tone == _resultTone) return const Color(0xFFB8B0A5);
  if (tone == _dataTone) return const Color(0xFFC5BDB1);
  if (tone == _imagesTone) return const Color(0xFFA9A197);
  if (tone == _behaviorTone) return const Color(0xFFB7AFA3);
  if (tone == _decisionTone) return const Color(0xFFBDB3A4);
  if (tone == _commitmentTone) return const Color(0xFFA9A197);
  if (tone == _noEntryTone) return const Color(0xFF9B9286);
  if (tone == _entryConditionsTone) return const Color(0xFFA9A196);
  if (tone == _reverseSignalsTone) return const Color(0xFF928A7F);
  if (tone == _bounceZoneTone) return const Color(0xFF81796E);
  return tone;
}

class TradeFormScreen extends StatefulWidget {
  const TradeFormScreen({super.key, this.trade});
  final Trade? trade;

  @override
  State<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends State<TradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _market;
  late final TextEditingController _result;
  late final TextEditingController _expectedLoss;
  late final TextEditingController _risk;
  late final TextEditingController _rewardRisk;
  late String _accountId;
  TradeSide? _side;
  late String _mood;
  late DateTime _tradedAt;
  late List<TradeEntrySetup> _entrySetups;
  late List<TradeConfirmationSetup> _confirmationSetups;
  late List<TradeEntryConditionSetup> _reverseSignalSetups;
  late List<TradeEntryConditionSetup> _bounceZoneSetups;
  late Set<String> _executionReviewKeys;
  late Set<String> _noEntryReasons;
  String? _beforePath;
  String? _afterPath;
  String? _confirmationImagePath;
  bool _busy = false;
  bool _seededExpectedLoss = false;
  final _picker = ImagePicker();

  bool get _ar => AppStrings.isArabic(context);
  String _copy(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    final trade = widget.trade;
    _market = TextEditingController(text: trade?.market ?? '');
    _result = TextEditingController(text: trade?.result.toString() ?? '');
    _expectedLoss = TextEditingController(text: trade?.expectedLoss?.toString() ?? '');
    _risk = TextEditingController(text: trade?.riskPercent.toStringAsFixed(2) ?? '');
    _rewardRisk = TextEditingController();
    _accountId = trade?.accountId ?? '';
    _side = trade?.side;
    _mood = trade?.mood.isNotEmpty == true ? trade!.mood : 'moodUnknown';
    _tradedAt = trade?.tradedAt ?? DateTime.now();
    _entrySetups = [...?trade?.effectiveEntrySetups];
    _confirmationSetups = [...?trade?.effectiveConfirmationSetups];
    _reverseSignalSetups = [...?trade?.reverseSignalSetups];
    _bounceZoneSetups = [...?trade?.bounceZoneSetups];
    _executionReviewKeys = {...?trade?.executionReviewKeys};
    _noEntryReasons = {...?trade?.noEntryReasons};
    _beforePath = trade?.beforeImagePath;
    _afterPath = trade?.afterImagePath;
    _confirmationImagePath = trade?.confirmationImagePath;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_accountId.isEmpty && app.accounts.isNotEmpty) {
      _accountId = app.selectedAccountId ?? app.accounts.first.id;
    }
    if (!_seededExpectedLoss && widget.trade != null) {
      _seededExpectedLoss = true;
      final balance = _accountBalanceBeforeTrade(app);
      final trade = widget.trade!;
      final amount = trade.expectedLoss ??
          (trade.result >= 0 && balance > 0
              ? balance * trade.riskPercent / 100
              : 0);
      _expectedLoss.text = trade.expectedLoss != null || amount > 0
          ? amount.toString()
          : '';
    }
    _updateComputedFields();
  }

  @override
  void dispose() {
    _market.dispose();
    _result.dispose();
    _expectedLoss.dispose();
    _risk.dispose();
    _rewardRisk.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  TradingAccount? get _account {
    final app = AppScope.of(context);
    for (final item in app.accounts) {
      if (item.id == _accountId) return item;
    }
    return app.accounts.firstOrNull;
  }

  double _accountBalanceBeforeTrade(AppController app) {
    TradingAccount? account;
    for (final candidate in app.accounts) {
      if (candidate.id == _accountId) {
        account = candidate;
        break;
      }
    }
    if (account == null) return 0;
    final selectedAccount = account;
    return app.trades
        .where((trade) => trade.accountId == selectedAccount.id &&
            trade.id != widget.trade?.id && trade.tradedAt.isBefore(_tradedAt))
        .fold<double>(selectedAccount.startingBalance, (balance, trade) {
      final next = balance + trade.result;
      return next.isFinite ? next : balance;
    });
  }

  void _updateComputedFields() {
    final app = AppScope.of(context);
    final balance = _accountBalanceBeforeTrade(app);
    var parsedLoss = _parse(_expectedLoss);
    final result = _parse(_result);
    final isLosingResult = result != null && result < 0;
    if (isLosingResult &&
        _expectedLoss.text.trim().isNotEmpty &&
        (widget.trade == null ||
            parsedLoss == null ||
            !parsedLoss.isFinite ||
            parsedLoss < 0)) {
      _expectedLoss.clear();
      parsedLoss = null;
    }
    final recordedLoss = parsedLoss != null &&
            parsedLoss.isFinite &&
            parsedLoss >= 0
        ? parsedLoss
        : null;
    // For a losing trade with no previously recorded planned risk, use the
    // realized loss as the risk amount for derived percentages and R-multiple.
    // It is not added to the trade result or stored as a second cash loss.
    final loss = isLosingResult &&
            (recordedLoss == null || recordedLoss == 0)
        ? result!.abs()
        : recordedLoss;
    final risk = loss == null || loss < 0
        ? null
        : loss == 0
            ? 0.0
            : balance > 0
                ? loss / balance * 100
                : null;
    _risk.text = risk != null && risk.isFinite ? risk.toStringAsFixed(2) : '';
    _rewardRisk.text = loss != null && loss > 0 && result != null && result.isFinite
        ? (result / loss).toStringAsFixed(2)
        : '';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tradedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_tradedAt));
    if (time == null || !mounted) return;
    setState(() {
      _tradedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _updateComputedFields();
    });
  }

  Future<void> _pickImage(_TradeImageSlot slot) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
      if (picked == null || !mounted) return;
      setState(() => _busy = true);
      final saved = await AppScope.of(context).persistImage(picked.path);
      if (!mounted) return;
      setState(() {
        switch (slot) {
          case _TradeImageSlot.before:
            _beforePath = saved;
          case _TradeImageSlot.after:
            _afterPath = saved;
          case _TradeImageSlot.confirmation:
            _confirmationImagePath = saved;
        }
        _busy = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<String?> _showChoiceSheet({
    required String title,
    required List<TradeEntryOption> options,
    String? selectedKey,
  }) {
    final tokens = TdTokens.of(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.surface1,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * .72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(title, style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: tokens.lineSubtle),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.key == selectedKey;
                    return ListTile(
                      dense: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      selected: isSelected,
                      selectedTileColor: tokens.accent.withValues(alpha: .14),
                      title: Text(_ar ? option.ar : option.en, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
                      trailing: Icon(isSelected ? Icons.check_circle : Icons.chevron_left, size: 19, color: isSelected ? tokens.accent : tokens.text3),
                      onTap: () => Navigator.pop(sheetContext, option.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showTimeframeSheet({required String title, String? selectedFrame}) => _showChoiceSheet(
        title: title,
        selectedKey: selectedFrame,
        options: [for (final frame in tradeEntryTimeframes) TradeEntryOption(frame, frame, frame)],
      );

  Future<TradeEntryConditionSetup?> _showEntryConditionSetup({
    required String title,
    required List<TradeEntryOption> options,
    TradeEntryConditionSetup? current,
  }) async {
    final optionKey = await _showChoiceSheet(
      title: title,
      options: options,
      selectedKey: current?.optionKey,
    );
    if (optionKey == null || !mounted) return null;

    final isTrendlineAndSupplyZone =
        optionKey == 'bounceFromTrendlineAndSupplyZone';
    final primaryTimeframe = await _showTimeframeSheet(
      title: isTrendlineAndSupplyZone
          ? _copy('فريم ترند لاين', 'Trendline timeframe')
          : _copy('الفريم الزمني', 'Timeframe'),
      selectedFrame: current?.timeframe,
    );
    if (primaryTimeframe == null || !mounted) return null;

    String? supplyZoneTimeframe;
    if (isTrendlineAndSupplyZone) {
      // The combined condition intentionally opens a second timeframe sheet
      // immediately after the Trendline timeframe has been selected.
      supplyZoneTimeframe = await _showTimeframeSheet(
        title: _copy('فريم Supply Zone', 'Supply Zone timeframe'),
        selectedFrame: current?.secondaryTimeframe,
      );
      if (supplyZoneTimeframe == null || !mounted) return null;
    }

    return TradeEntryConditionSetup(
      optionKey: optionKey,
      timeframe: primaryTimeframe,
      secondaryTimeframe: supplyZoneTimeframe,
    );
  }

  Future<bool?> _showTouch2Sheet({required String baseReason, bool selected = false}) {
    final tokens = TdTokens.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: tokens.surface1,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(
                  _copy('تفصيل $baseReason — اختياري', '$baseReason detail — optional'),
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                key: ValueKey('touch2-choice-$baseReason'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                selected: selected,
                selectedTileColor: tokens.accent.withValues(alpha: .14),
                leading: Icon(Icons.touch_app_outlined, color: selected ? tokens.accent : tokens.text2),
                title: const Text('Touch 2'),
                trailing: Icon(
                  selected ? Icons.check_circle : Icons.chevron_left,
                  size: 19,
                  color: selected ? tokens.accent : tokens.text3,
                ),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: ValueKey('skip-touch2-$baseReason'),
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: Text(_copy('تخطي والمتابعة إلى الفريمات', 'Skip and choose timeframe')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showEntryReasonSheet({String? currentReason, bool editing = false}) async {
    final currentBase = currentReason == null ? null : tradeEntryBaseReason(currentReason);
    final baseReason = await _showChoiceSheet(
      title: editing
          ? _copy('تعديل سبب الدخول', 'Edit entry reason')
          : _copy('سبب الدخول', 'Entry reason'),
      options: tradeEntryReasons,
      selectedKey: currentBase,
    );
    if (baseReason == null || !mounted) return null;
    if (!tradeEntryTouch2EligibleReasons.contains(baseReason)) return baseReason;

    final touch2 = await _showTouch2Sheet(
      baseReason: baseReason,
      selected: currentReason != null &&
          currentBase == baseReason &&
          tradeEntryUsesTouch2(currentReason),
    );
    if (touch2 == null || !mounted) return null;
    return tradeEntryReasonWithTouch2(baseReason, touch2);
  }

  Future<String?> _showCustomConfirmationDialog({String initialValue = ''}) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_copy('تأكيد مخصص', 'Custom confirmation')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: _copy('اكتب نوع التأكيد', 'Enter confirmation type')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr(context, 'cancel'))),
          FilledButton(onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(dialogContext, text);
          }, child: Text(tr(context, 'confirm'))),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _addEntrySetup() async {
    final reason = await _showEntryReasonSheet();
    if (reason == null || !mounted) return;
    final timeframe = await _showTimeframeSheet(title: _copy('الفريم الزمني', 'Timeframe'));
    if (timeframe == null || !mounted) return;
    setState(() {
      if (!_entrySetups.any((item) => item.reason == reason && item.timeframe == timeframe)) {
        _entrySetups.add(TradeEntrySetup(reason: reason, timeframe: timeframe));
      }
    });
  }

  Future<void> _addConfirmationSetup() async {
    final type = await _showChoiceSheet(title: _copy('تأكيد الدخول', 'Entry confirmation'), options: tradeConfirmationOptions);
    if (type == null || !mounted) return;
    String finalType = type;
    if (type == '__custom__') {
      final custom = await _showCustomConfirmationDialog();
      if (custom == null || !mounted) return;
      finalType = custom;
    }
    final timeframe = await _showTimeframeSheet(title: _copy('فريم التأكيد', 'Confirmation timeframe'));
    if (timeframe == null || !mounted) return;
    setState(() {
      if (!_confirmationSetups.any((item) => item.type == finalType && item.timeframe == timeframe)) {
        _confirmationSetups.add(TradeConfirmationSetup(type: finalType, timeframe: timeframe));
      }
    });
  }

  Future<void> _editEntrySetup(TradeEntrySetup current) async {
    final reason = await _showEntryReasonSheet(currentReason: current.reason, editing: true);
    if (reason == null || !mounted) return;
    final timeframe = await _showTimeframeSheet(
      title: _copy('تعديل الفريم الزمني', 'Edit timeframe'),
      selectedFrame: current.timeframe,
    );
    if (timeframe == null || !mounted) return;
    setState(() {
      final index = _entrySetups.indexOf(current);
      if (index < 0) return;
      final replacement = TradeEntrySetup(reason: reason, timeframe: timeframe);
      if (_entrySetups.asMap().entries.any((entry) => entry.key != index && entry.value == replacement)) {
        _entrySetups.removeAt(index);
      } else {
        _entrySetups[index] = replacement;
      }
    });
  }

  Future<void> _editConfirmationSetup(TradeConfirmationSetup current) async {
    final type = await _showChoiceSheet(
      title: _copy('تعديل تأكيد الدخول', 'Edit entry confirmation'),
      options: tradeConfirmationOptions,
      selectedKey: tradeConfirmationOptions.any((item) => item.key == current.type) ? current.type : '__custom__',
    );
    if (type == null || !mounted) return;
    String finalType = type;
    if (type == '__custom__') {
      final custom = await _showCustomConfirmationDialog(initialValue: current.type == '__custom__' ? '' : current.type);
      if (custom == null || !mounted) return;
      finalType = custom;
    }
    final timeframe = await _showTimeframeSheet(
      title: _copy('تعديل فريم التأكيد', 'Edit confirmation timeframe'),
      selectedFrame: current.timeframe,
    );
    if (timeframe == null || !mounted) return;
    setState(() {
      final index = _confirmationSetups.indexOf(current);
      if (index < 0) return;
      final replacement = TradeConfirmationSetup(type: finalType, timeframe: timeframe);
      if (_confirmationSetups.asMap().entries.any((entry) => entry.key != index && entry.value == replacement)) {
        _confirmationSetups.removeAt(index);
      } else {
        _confirmationSetups[index] = replacement;
      }
    });
  }

  Future<void> _addReverseSignalSetup() async {
    final setup = await _showEntryConditionSetup(
      title: _copy('إشارات عكسية', 'Opposing signals'),
      options: tradeReverseSignalOptions,
    );
    if (setup == null || !mounted) return;
    setState(() {
      if (!_reverseSignalSetups.contains(setup)) _reverseSignalSetups.add(setup);
    });
  }

  Future<void> _editReverseSignalSetup(TradeEntryConditionSetup current) async {
    final setup = await _showEntryConditionSetup(
      title: _copy('تعديل الإشارة العكسية', 'Edit opposing signal'),
      options: tradeReverseSignalOptions,
      current: current,
    );
    if (setup == null || !mounted) return;
    setState(() {
      final index = _reverseSignalSetups.indexOf(current);
      if (index < 0) return;
      if (_reverseSignalSetups.asMap().entries.any(
        (entry) => entry.key != index && entry.value == setup,
      )) {
        _reverseSignalSetups.removeAt(index);
      } else {
        _reverseSignalSetups[index] = setup;
      }
    });
  }

  Future<void> _addBounceZoneSetup() async {
    final setup = await _showEntryConditionSetup(
      title: _copy('منطقة الارتداد', 'Bounce area'),
      options: tradeBounceZoneOptions,
    );
    if (setup == null || !mounted) return;
    setState(() {
      if (!_bounceZoneSetups.contains(setup)) _bounceZoneSetups.add(setup);
    });
  }

  Future<void> _editBounceZoneSetup(TradeEntryConditionSetup current) async {
    final setup = await _showEntryConditionSetup(
      title: _copy('تعديل منطقة الارتداد', 'Edit bounce area'),
      options: tradeBounceZoneOptions,
      current: current,
    );
    if (setup == null || !mounted) return;
    setState(() {
      final index = _bounceZoneSetups.indexOf(current);
      if (index < 0) return;
      if (_bounceZoneSetups.asMap().entries.any(
        (entry) => entry.key != index && entry.value == setup,
      )) {
        _bounceZoneSetups.removeAt(index);
      } else {
        _bounceZoneSetups[index] = setup;
      }
    });
  }

  void _removeReverseSignalSetup(TradeEntryConditionSetup setup) =>
      setState(() => _reverseSignalSetups.remove(setup));

  void _removeBounceZoneSetup(TradeEntryConditionSetup setup) =>
      setState(() => _bounceZoneSetups.remove(setup));

  void _removeEntrySetup(TradeEntrySetup setup) => setState(() => _entrySetups.remove(setup));
  void _removeConfirmationSetup(TradeConfirmationSetup setup) => setState(() => _confirmationSetups.remove(setup));

  void _toggleSet(Set<String> values, String key, bool selected) {
    setState(() {
      if (selected) {
        values.add(key);
      } else {
        values.remove(key);
      }
    });
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? tr(context, 'requiredField') : null;

  String? _number(String? value, {double? min}) {
    if (value == null || value.trim().isEmpty) return tr(context, 'requiredField');
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || (min != null && parsed < min)) return tr(context, 'invalidNumber');
    return null;
  }

  String? _expectedLossValidator(String? value) {
    // The result itself supplies the realized loss when it is negative, so
    // this separate planned-loss field is intentionally not required then.
    final result = _parse(_result);
    if (result != null && result < 0) return null;
    final invalid = _number(value, min: 0);
    if (invalid != null) return invalid;
    final loss = _parse(_expectedLoss) ?? 0;
    if (result != 0 && loss <= 0) return tr(context, 'expectedLossNeeded');
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_side == null) {
      _showValidationMessage(_copy('حدد اتجاه الصفقة: شراء أو بيع.', 'Choose the trade direction: buy or sell.'));
      return;
    }
    if (_entrySetups.isEmpty) {
      _showValidationMessage(_copy('أضف سبب دخول واحدًا على الأقل مع الفريم الزمني.', 'Add at least one entry reason with its timeframe.'));
      return;
    }
    if (_confirmationSetups.isEmpty) {
      _showValidationMessage(_copy('أضف تأكيد دخول واحدًا على الأقل مع فريمه الزمني.', 'Add at least one entry confirmation with its timeframe.'));
      return;
    }
    final app = AppScope.of(context);
    if (app.accounts.isEmpty) return;
    final balance = _accountBalanceBeforeTrade(app);
    final result = _parse(_result)!;
    final parsedLoss = _parse(_expectedLoss);
    final recordedLoss = parsedLoss != null &&
            parsedLoss.isFinite &&
            parsedLoss >= 0
        ? parsedLoss
        : null;
    final loss = result < 0 &&
            (recordedLoss == null || recordedLoss == 0)
        ? result.abs()
        : recordedLoss ?? 0.0;
    final risk = loss == 0 ? 0.0 : (balance > 0 ? loss / balance * 100 : null);
    if (risk == null || !risk.isFinite) {
      _showValidationMessage(tr(context, 'riskBalanceUnavailable'));
      return;
    }
    final setups = [..._entrySetups];
    final confirmations = [..._confirmationSetups];
    final trade = Trade(
      id: widget.trade?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      accountId: app.accounts.any((item) => item.id == _accountId) ? _accountId : (app.selectedAccountId ?? app.accounts.first.id),
      market: _market.text.trim().toUpperCase(),
      reason: setups.first.reason,
      result: result,
      riskPercent: risk,
      // Keep this optional when the loss amount was derived solely from the
      // realized result. Existing or explicitly entered planned risk is kept.
      expectedLoss: recordedLoss ?? (result < 0 ? null : loss),
      side: _side!,
      confirmation: '',
      confirmationSetups: confirmations,
      reverseSignalSetups: [..._reverseSignalSetups],
      bounceZoneSetups: [..._bounceZoneSetups],
      executionJournal: widget.trade?.executionJournal ?? const [],
      executionReviewKeys: _executionReviewKeys.toList(growable: false),
      noEntryReasons: _noEntryReasons.toList(growable: false),
      sequence: widget.trade?.sequence ?? '',
      mood: _mood,
      tradedAt: _tradedAt,
      entryTimeframe: setups.first.timeframe,
      entrySetups: setups,
      beforeImagePath: _beforePath,
      afterImagePath: _afterPath,
      confirmationImagePath: _confirmationImagePath,
      notes: widget.trade?.notes ?? '',
      strategyAdherence: widget.trade?.strategyAdherence,
    );
    Navigator.of(context).pop(trade);
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tokens = TdTokens.of(context);
    final softenedTokens = tokens.copyWith(
      lineSubtle: tokens.lineSubtle.withValues(alpha: .78),
      lineStrong: tokens.lineStrong.withValues(alpha: .68),
    );
    final baseTheme = Theme.of(context);
    final defaultFieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: softenedTokens.lineSubtle),
    );
    final focusedFieldBorder = defaultFieldBorder.copyWith(
      borderSide: BorderSide(
        color: tokens.accent.withValues(alpha: .82),
        width: 1.3,
      ),
    );
    if (app.accounts.isEmpty) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(tr(context, 'addFirstAccount'))));
    }
    if (!app.accounts.any((item) => item.id == _accountId)) {
      _accountId = app.selectedAccountId ?? app.accounts.first.id;
    }
    final account = _account ?? app.accounts.first;
    return Theme(
      data: baseTheme.copyWith(
        dividerColor: softenedTokens.lineSubtle,
        inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
          border: defaultFieldBorder,
          enabledBorder: defaultFieldBorder,
          focusedBorder: focusedFieldBorder,
          disabledBorder: defaultFieldBorder,
        ),
        chipTheme: baseTheme.chipTheme.copyWith(
          side: BorderSide(color: softenedTokens.lineStrong),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: baseTheme.outlinedButtonTheme.style?.copyWith(
            side: WidgetStatePropertyAll(
              BorderSide(color: softenedTokens.lineStrong),
            ),
          ),
        ),
        extensions: [softenedTokens],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, widget.trade == null ? 'addTrade' : 'editTrade')),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: softenedTokens.lineSubtle)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 15, color: tokens.text2),
                    const SizedBox(width: 6),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium)),
                  ]),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 34),
                children: [
                  _sectionCard(
                    context,
                    title: _copy('النتيجة والمخاطرة', 'Result & risk'),
                    icon: Icons.query_stats_outlined,
                    tone: _resultTone,
                    gradientColors: const [Color(0xFF303030), Color(0xFF292929), Color(0xFF222222), Color(0xFF1B1B1B)],
                    borderTone: const Color(0xFF484848),
                    children: [
                      Row(children: [
                        Expanded(child: _numericField(controller: _result, key: const ValueKey('trade-result-input'), label: _copy('الربح / الخسارة', 'Profit / loss'), suffix: account.currency, validator: _number, signed: true, onChanged: (_) => setState(_updateComputedFields))),
                        const SizedBox(width: 10),
                        Expanded(child: _numericField(controller: _expectedLoss, key: const ValueKey('trade-expected-loss-input'), label: _copy('الخسارة المتوقعة', 'Expected loss'), suffix: account.currency, validator: _expectedLossValidator, readOnly: (_parse(_result) ?? 0) < 0, onChanged: (_) => setState(_updateComputedFields))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _readoutField(controller: _risk, key: const ValueKey('trade-risk-input'), label: _copy('نسبة المخاطرة', 'Risk %'), suffix: '%')),
                        const SizedBox(width: 10),
                        Expanded(child: _readoutField(controller: _rewardRisk, key: const ValueKey('trade-reward-risk-input'), label: _copy('العائد / المخاطرة', 'Reward / risk'), suffix: 'R')),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: _copy('بيانات الصفقة', 'Trade details'),
                    icon: Icons.receipt_long_outlined,
                    tone: _dataTone,
                    gradientColors: const [Color(0xFF323232), Color(0xFF2B2B2B), Color(0xFF232323), Color(0xFF1C1C1C)],
                    borderTone: const Color(0xFF505050),
                    tint: .15,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              key: const ValueKey('trade-market-input'),
                              controller: _market,
                              validator: _required,
                              maxLength: 24,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: _copy('السوق / الرمز', 'Market / symbol'),
                                prefixIcon: const Icon(Icons.show_chart_outlined, size: 18),
                                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 40),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
                                  child: Text(
                                    _copy('الاتجاه', 'Direction'),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: TdTokens.of(context).text2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child: _TradeDirectionSelector(
                                    key: const ValueKey('trade-direction-selector'),
                                    side: _side,
                                    buyLabel: _copy('شراء', 'Buy'),
                                    sellLabel: _copy('بيع', 'Sell'),
                                    onChanged: (value) => setState(() => _side = value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _setupSelectionBlock(
                        title: _copy('سبب الدخول', 'Entry reason'),
                        setups: _entrySetups.map((item) => (label: item.reason, timeframe: item.timeframe, item: item)).toList(),
                        onAdd: _addEntrySetup,
                        onRemove: (item) => _removeEntrySetup(item as TradeEntrySetup),
                        onEdit: (item) => _editEntrySetup(item as TradeEntrySetup),
                        addKey: const ValueKey('add-entry-setup'),
                      ),
                      const SizedBox(height: 16),
                      _setupSelectionBlock(
                        title: _copy('تأكيد الدخول', 'Entry confirmation'),
                        setups: _confirmationSetups.map((item) => (label: _confirmationLabel(item.type), timeframe: item.timeframe, item: item)).toList(),
                        onAdd: _addConfirmationSetup,
                        onRemove: (item) => _removeConfirmationSetup(item as TradeConfirmationSetup),
                        onEdit: (item) => _editConfirmationSetup(item as TradeConfirmationSetup),
                        addKey: const ValueKey('add-confirmation-setup'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: const ValueKey('trade-mood-dropdown'),
                        initialValue: tradeMoodOptions.any((item) => item.key == _mood) ? _mood : 'moodUnknown',
                        decoration: InputDecoration(labelText: _copy('الحالة النفسية', 'Mindset'), prefixIcon: const Icon(Icons.psychology_outlined)),
                        items: [for (final item in tradeMoodOptions) DropdownMenuItem(value: item.key, child: Text(_ar ? item.ar : item.en))],
                        onChanged: (value) => setState(() => _mood = value ?? 'moodUnknown'),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text('${_copy('تاريخ ووقت الصفقة', 'Trade date & time')}: ${shortDate(_tradedAt)} · ${TimeOfDay.fromDateTime(_tradedAt).format(context)}'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), alignment: AlignmentDirectional.centerStart),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: _copy('ظروف الدخول', 'Entry conditions'),
                    icon: Icons.radar_rounded,
                    tone: _entryConditionsTone,
                    gradientColors: const [Color(0xFF2D2D2D), Color(0xFF282828), Color(0xFF222222), Color(0xFF1B1B1B)],
                    borderTone: const Color(0xFF484848),
                    tint: .12,
                    children: [
                      _behaviorExpansion(
                        title: _copy('إشارات عكسية', 'Opposing signals'),
                        count: _reverseSignalSetups.length,
                        tone: _reverseSignalsTone,
                        child: _entryConditionSelectionBlock(
                          setups: _reverseSignalSetups,
                          options: tradeReverseSignalOptions,
                          onAdd: _addReverseSignalSetup,
                          onRemove: (setup) => _removeReverseSignalSetup(setup as TradeEntryConditionSetup),
                          onEdit: (setup) => _editReverseSignalSetup(setup as TradeEntryConditionSetup),
                          addKey: const ValueKey('add-reverse-signal-setup'),
                          tone: _reverseSignalsTone,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _behaviorExpansion(
                        title: _copy('منطقة الارتداد', 'Bounce area'),
                        count: _bounceZoneSetups.length,
                        tone: _bounceZoneTone,
                        child: _entryConditionSelectionBlock(
                          setups: _bounceZoneSetups,
                          options: tradeBounceZoneOptions,
                          onAdd: _addBounceZoneSetup,
                          onRemove: (setup) => _removeBounceZoneSetup(setup as TradeEntryConditionSetup),
                          onEdit: (setup) => _editBounceZoneSetup(setup as TradeEntryConditionSetup),
                          addKey: const ValueKey('add-bounce-zone-setup'),
                          tone: _bounceZoneTone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildBehaviorCard(context),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: _copy('صور الصفقة', 'Trade images'),
                    icon: Icons.photo_library_outlined,
                    tone: _imagesTone,
                    gradientColors: const [Color(0xFF292929), Color(0xFF222222), Color(0xFF1B1B1B)],
                    borderTone: const Color(0xFF444444),
                    children: [
                      Row(children: [
                        Expanded(child: ImageAttachmentTile(label: _copy('قبل الدخول', 'Before entry'), path: _beforePath, onTap: () => _pickImage(_TradeImageSlot.before), onRemove: _beforePath == null ? null : () => setState(() => _beforePath = null))),
                        const SizedBox(width: 10),
                        Expanded(child: ImageAttachmentTile(label: _copy('بعد الدخول', 'After entry'), path: _afterPath, onTap: () => _pickImage(_TradeImageSlot.after), onRemove: _afterPath == null ? null : () => setState(() => _afterPath = null))),
                      ]),
                      const SizedBox(height: 12),
                      ImageAttachmentTile(key: const ValueKey('confirmation-image-attachment'), label: _copy('تأكيد الدخول', 'Entry confirmation'), path: _confirmationImagePath, onTap: () => _pickImage(_TradeImageSlot.confirmation), onRemove: _confirmationImagePath == null ? null : () => setState(() => _confirmationImagePath = null)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const ValueKey('save-trade-button'),
                    onPressed: _busy ? null : _save,
                    icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                    label: Text(tr(context, 'save')),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ],
              ),
              if (_busy) Positioned.fill(child: ColoredBox(color: tokens.scrim.withValues(alpha: .26), child: const Center(child: CircularProgressIndicator()))),
            ],
          ),
        ),
      ),
    );
  }

  String _confirmationLabel(String type) {
    final known = tradeConfirmationOptions.where((item) => item.key == type).firstOrNull;
    if (known != null) return _ar ? known.ar : known.en;
    return type;
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? tone,
    Color? borderTone,
    List<Color>? gradientColors,
    double tint = .10,
  }) {
    final tokens = TdTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTone = tone == null ? null : _toneForMode(tone, isDark);
    final resolvedBorderTone = borderTone == null || tone == null
        ? resolvedTone
        : _toneForMode(borderTone, isDark);
    final content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: resolvedTone == null ? tokens.surface3 : resolvedTone.withValues(alpha: isDark ? .16 : .11),
            borderRadius: BorderRadius.circular(10),
            border: resolvedTone == null ? null : Border.all(color: resolvedTone.withValues(alpha: .18)),
          ),
          child: Icon(icon, size: 18, color: resolvedTone ?? tokens.accent),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 16),
      ...children,
    ]);

    if (resolvedTone == null) {
      return AppCard(padding: const EdgeInsets.all(16), sheen: false, child: content);
    }
    Widget sectionContent = content;
    if (identical(tone, _dataTone) || tone == _dataTone) {
      final baseTheme = Theme.of(context);
      final fieldFill = isDark
          ? const Color(0xFF222222)
          : Color.alphaBlend(_toneForMode(_dataTone, isDark).withValues(alpha: .10), tokens.inset);
      final fieldBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? const Color(0xFF494949).withValues(alpha: .78)
              : tokens.lineSubtle.withValues(alpha: .78),
        ),
      );
      sectionContent = Theme(
        data: baseTheme.copyWith(
          inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: fieldFill,
            enabledBorder: fieldBorder,
            border: fieldBorder,
            focusedBorder: fieldBorder.copyWith(
              borderSide: BorderSide(
                color: _toneForMode(_dataTone, isDark).withValues(alpha: .82),
                width: 1.3,
              ),
            ),
          ),
        ),
        child: content,
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(resolvedTone!.withValues(alpha: isDark ? tint : tint * .58), tokens.surface1),
        gradient: !isDark || gradientColors == null
            ? null
            : LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: gradientColors,
                stops: gradientColors.length == 4
                    ? const [0, .32, .68, 1]
                    : null,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resolvedBorderTone!.withValues(alpha: isDark ? .28 : .20)),
      ),
      child: sectionContent,
    );
  }

  Widget _numericField({required TextEditingController controller, required Key key, required String label, required String suffix, required String? Function(String?) validator, bool signed = false, bool readOnly = false, ValueChanged<String>? onChanged}) => TextFormField(
        key: key,
        controller: controller,
        validator: validator,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: signed),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.start,
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      );

  Widget _readoutField({required TextEditingController controller, required Key key, required String label, required String suffix}) => TextFormField(
        key: key,
        controller: controller,
        readOnly: true,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(labelText: label, suffixText: suffix, filled: true, fillColor: TdTokens.of(context).inset),
      );

  Widget _fieldLabel(String label) => Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700));

  Widget _setupSelectionBlock({
    required String title,
    required List<({String label, String timeframe, Object item})> setups,
    required Future<void> Function() onAdd,
    required void Function(Object) onRemove,
    required void Function(Object) onEdit,
    required Key addKey,
  }) {
    final tokens = TdTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: _fieldLabel(title)), Text('${setups.length}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tokens.text3, fontWeight: FontWeight.w700))]),
      if (setups.isNotEmpty) ...[
        const SizedBox(height: 9),
        Wrap(spacing: 7, runSpacing: 7, children: [
          for (final setup in setups)
            InputChip(
              label: Text('${setup.label} ${setup.timeframe.isEmpty ? _copy('دون فريم', 'No timeframe') : setup.timeframe}'),
              onPressed: () => onEdit(setup.item),
              onDeleted: () => onRemove(setup.item),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              deleteIconColor: tokens.text3,
              backgroundColor: tokens.surface2,
              side: BorderSide(color: tokens.lineStrong.withValues(alpha: .78)),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              visualDensity: VisualDensity.compact,
            ),
        ]),
      ],
      const SizedBox(height: 8),
      Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(key: addKey, onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: Text(_copy('إضافة اختيار', 'Add selection')), style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact))),
    ]);
  }

  Widget _entryConditionSelectionBlock({
    required List<TradeEntryConditionSetup> setups,
    required List<TradeEntryOption> options,
    required Future<void> Function() onAdd,
    required void Function(Object) onRemove,
    required void Function(Object) onEdit,
    required Key addKey,
    required Color tone,
  }) {
    final tokens = TdTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTone = _toneForMode(tone, isDark);
    String optionLabel(String key) => options
        .where((option) => option.key == key)
        .map((option) => _ar ? option.ar : option.en)
        .firstOrNull ?? key;

    String setupLabel(TradeEntryConditionSetup setup) =>
        formatTradeEntryConditionSetupLabel(
          setup: setup,
          optionLabel: optionLabel(setup.optionKey),
          arabic: _ar,
          side: _side,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (setups.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final setup in setups)
                InputChip(
                  key: ValueKey('entry-condition-${setup.optionKey}-${setup.timeframe}-${setup.secondaryTimeframe ?? ''}'),
                  label: Text(setupLabel(setup)),
                  onPressed: () => onEdit(setup),
                  onDeleted: () => onRemove(setup),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  deleteIconColor: tokens.text3,
                  backgroundColor: Color.alphaBlend(resolvedTone.withValues(alpha: .09), tokens.surface2),
                  side: BorderSide(color: resolvedTone.withValues(alpha: .24)),
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: addKey,
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(_copy('إضافة اختيار', 'Add selection')),
            style: OutlinedButton.styleFrom(
              foregroundColor: resolvedTone,
              side: BorderSide(color: resolvedTone.withValues(alpha: .34)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBehaviorCard(BuildContext context) {
    final tokens = TdTokens.of(context);
    final decisionCount = tradeReviewGroups
        .expand((group) => group.options)
        .where((option) => _executionReviewKeys.contains(option.key))
        .length;
    final noEntryCount = _noEntryReasons.length;
    return _sectionCard(
      context,
      title: _copy('التصرفات', 'Trading behavior'),
      icon: Icons.fact_check_outlined,
      tone: _behaviorTone,
      gradientColors: const [Color(0xFF303030), Color(0xFF292929), Color(0xFF222222), Color(0xFF1B1B1B)],
      borderTone: const Color(0xFF4A4A4A),
      tint: .14,
      children: [
        _behaviorExpansion(
          title: _copy('القرارات', 'Decisions'),
          count: decisionCount,
          tone: _decisionTone,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final group in tradeReviewGroups) ...[
              Padding(padding: const EdgeInsets.only(top: 9, bottom: 5), child: Text(_ar ? group.titleAr : group.titleEn, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: tokens.text2))),
              for (final option in group.options) _selectionRow(option, _executionReviewKeys, keyPrefix: 'review', accent: _decisionTone),
            ],
          ]),
        ),
        const SizedBox(height: 8),
        _behaviorExpansion(
          title: _copy('الالتزام', 'Plan commitment'),
          count: tradeCommitmentOptions.where((item) => _executionReviewKeys.contains(item.key)).length,
          tone: _commitmentTone,
          child: Column(children: [for (final option in tradeCommitmentOptions) _selectionRow(option, _executionReviewKeys, keyPrefix: 'review', accent: _commitmentTone)]),
        ),
        const SizedBox(height: 8),
        _behaviorExpansion(
          title: _copy('أسباب عدم الدخول', 'Reasons for not entering'),
          count: noEntryCount,
          tone: _noEntryTone,
          child: Column(children: [for (final option in tradeNoEntryOptions) _selectionRow(option, _noEntryReasons, keyPrefix: 'no-entry', accent: _noEntryTone)]),
        ),
      ],
    );
  }

  Widget _behaviorExpansion({required String title, required int count, required Color tone, required Widget child, Widget? leading}) {
    final tokens = TdTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTone = _toneForMode(tone, isDark);
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(resolvedTone.withValues(alpha: isDark ? .14 : .08), tokens.surface2),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: resolvedTone.withValues(alpha: isDark ? .26 : .20)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          title: Row(children: [if (leading != null) ...[leading, const SizedBox(width: 7)], Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: count > 0 ? resolvedTone.withValues(alpha: .16) : tokens.surface3, borderRadius: BorderRadius.circular(20), border: Border.all(color: resolvedTone.withValues(alpha: count > 0 ? .30 : .16))), child: Text('$count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: count > 0 ? resolvedTone : tokens.text3, fontWeight: FontWeight.w800)))]),
          children: [child],
        ),
      ),
    );
  }

  Widget _selectionRow(TradeEntryOption option, Set<String> selected, {required String keyPrefix, required Color accent}) {
    final tokens = TdTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedAccent = _toneForMode(accent, isDark);
    final isSelected = selected.contains(option.key);
    final hasReviewArtwork = tradeReviewOptionEmojiAssets.containsKey(option.key);
    return InkWell(
      key: ValueKey('$keyPrefix-${option.key}'),
      onTap: () => _toggleSet(selected, option.key, !isSelected),
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          AnimatedContainer(duration: const Duration(milliseconds: 120), width: 21, height: 21, margin: EdgeInsetsDirectional.only(top: 1, end: hasReviewArtwork ? 6 : 9), decoration: BoxDecoration(color: isSelected ? resolvedAccent : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: isSelected ? resolvedAccent : tokens.lineStrong.withValues(alpha: .78), width: 1.2)), child: isSelected
              ? Icon(
                  Icons.check,
                  size: 15,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF181818)
                      : Colors.white,
                )
              : null),
          if (hasReviewArtwork) ...[
            const SizedBox(width: 2),
            TradeReviewOptionEmoji(
              key: ValueKey('review-art-${option.key}'),
              optionKey: option.key,
              size: 28,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(_ar ? option.ar : option.en, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isSelected ? tokens.text1 : tokens.text2, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, height: 1.45))),
        ]),
      ),
    );
  }
}

class _TradeDirectionSelector extends StatelessWidget {
  const _TradeDirectionSelector({
    super.key,
    required this.side,
    required this.buyLabel,
    required this.sellLabel,
    required this.onChanged,
  });

  final TradeSide? side;
  final String buyLabel;
  final String sellLabel;
  final ValueChanged<TradeSide?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget segment({
      required TradeSide value,
      required String label,
    }) {
      final selected = side == value;
      return Expanded(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('trade-direction-${value.name}'),
            onTap: () => onChanged(selected ? null : value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              height: 40,
              alignment: Alignment.center,
              color: selected ? scheme.secondaryContainer : Colors.transparent,
              child: Semantics(
                button: true,
                selected: selected,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : tokens.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    const radius = BorderRadius.all(Radius.circular(24));
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Row(
            children: [
              segment(value: TradeSide.buy, label: buyLabel),
              Container(width: 1, height: 40, color: tokens.lineStrong),
              segment(value: TradeSide.sell, label: sellLabel),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: tokens.lineStrong, width: 1.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
