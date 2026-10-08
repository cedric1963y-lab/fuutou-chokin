import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/yen.dart';
import '../look/envelope_card.dart';
import '../look/kraft_theme.dart';

/// 支出の記録（新規）または修正。ここでは広告を出さない。
Future<void> openSpendSheet(
  BuildContext context, {
  String? envelopeId,
  Spend? editing,
  int? initialAmount,
  String? initialMemo,
}) async {
  final scope = AppScope.of(context);
  final c = scope.controller;
  final messenger = ScaffoldMessenger.of(context);
  final saved = await showModalBottomSheet<_SheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Kraft.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => AppScope(
      controller: scope.controller,
      ads: scope.ads,
      showcase: scope.showcase,
      child: _SpendSheet(
        envelopeId: editing?.envelopeId ?? envelopeId,
        editing: editing,
        initialAmount: editing?.amount ?? initialAmount,
        initialMemo: editing?.memo ?? initialMemo,
      ),
    ),
  );
  if (saved == null) return;
  messenger.hideCurrentSnackBar();
  if (saved.deleted != null) {
    final gone = saved.deleted!;
    messenger.showSnackBar(SnackBar(
      content: const Text('記録を消しました'),
      action: SnackBarAction(label: '元に戻す', onPressed: () => c.restoreSpend(gone)),
    ));
    return;
  }
  final s = saved.spend!;
  final env = c.ledger.byId(s.envelopeId);
  if (env == null) return;
  final left = c.ledger.balanceOf(env);
  messenger.showSnackBar(SnackBar(
    content: Text('${env.name}から ${yen(s.amount)}・のこり ${yen(left)}'),
    action: editing == null
        ? SnackBarAction(label: '取り消す', onPressed: () => c.removeSpend(s))
        : null,
  ));
}

class _SheetResult {
  _SheetResult({this.spend, this.deleted});
  final Spend? spend;
  final Spend? deleted;
}

class _SpendSheet extends StatefulWidget {
  const _SpendSheet({this.envelopeId, this.editing, this.initialAmount, this.initialMemo});
  final String? envelopeId;
  final Spend? editing;
  final int? initialAmount;
  final String? initialMemo;

  @override
  State<_SpendSheet> createState() => _SpendSheetState();
}

class _SpendSheetState extends State<_SpendSheet> {
  late String _digits;
  String? _envId;
  late DateTime _on;
  late final TextEditingController _memo;

  @override
  void initState() {
    super.initState();
    _digits = widget.initialAmount?.toString() ?? '';
    _envId = widget.envelopeId;
    _memo = TextEditingController(text: widget.initialMemo ?? '');
    _on = widget.editing?.on ?? DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppScope.of(context).controller;
    _envId ??= c.ledger.envelopes.first.id;
    if (widget.editing == null) _on = c.today;
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_digits) ?? 0;

  void _press(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == 'del') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
      } else {
        if (_digits.isEmpty && (k == '0' || k == '00')) return;
        if (_digits.length + k.length > 8) return;
        _digits += k;
      }
    });
  }

  Future<void> _save() async {
    final c = AppScope.of(context).controller;
    final nav = Navigator.of(context);
    if (_amount <= 0 || _envId == null) return;
    if (widget.editing != null) {
      await c.updateSpend(widget.editing!,
          envelopeId: _envId, amount: _amount, on: _on, memo: _memo.text);
      nav.pop(_SheetResult(spend: widget.editing));
    } else {
      final s = await c.addSpend(
          envelopeId: _envId!, amount: _amount, on: _on, memo: _memo.text);
      nav.pop(_SheetResult(spend: s));
    }
  }

  Future<void> _pickDate() async {
    final c = AppScope.of(context).controller;
    final first = c.ledger.periodStart;
    final picked = await showDatePicker(
      context: context,
      initialDate: _on.isBefore(first) ? first : _on,
      firstDate: first.subtract(const Duration(days: 62)),
      lastDate: c.today.add(const Duration(days: 31)),
    );
    if (picked != null) setState(() => _on = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).controller;
    final l = c.ledger;
    final env = l.byId(_envId ?? '') ?? l.envelopes.first;
    final leftNow = l.balanceOf(env) + (widget.editing?.envelopeId == env.id ? widget.editing!.amount : 0);
    final after = leftNow - _amount;
    final isToday = dateOnly(_on) == c.today;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Kraft.line, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 0),
              child: Row(
                children: [
                  Text(widget.editing == null ? 'どの袋から出した？' : '記録を直す',
                      style: const TextStyle(fontFamily: Kraft.display, fontSize: 19)),
                  const Spacer(),
                  if (widget.editing != null)
                    IconButton(
                      tooltip: '消す',
                      icon: const Icon(Icons.delete_outline, color: Kraft.stamp),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        await c.removeSpend(widget.editing!);
                        nav.pop(_SheetResult(deleted: widget.editing));
                      },
                    ),
                  IconButton(
                    tooltip: '閉じる',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 74,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                children: [
                  for (final e in l.envelopes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _EnvChip(
                        envelope: e,
                        selected: e.id == env.id,
                        onTap: () => setState(() => _envId = e.id),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MiniEnvelope(tint: env.tint, size: 34, savings: env.isSavings),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _digits.isEmpty ? '¥0' : yen(_amount),
                            style: TextStyle(
                              fontFamily: Kraft.display,
                              fontSize: 46,
                              height: 1.1,
                              color: _digits.isEmpty ? Kraft.line : Kraft.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${env.name}ののこり ${yen(leftNow)} → ${yen(after)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: after < 0 ? Kraft.stamp : Kraft.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.event, size: 18),
                        label: Text(isToday ? '今日 ${md(_on)}' : mdW(_on)),
                        onPressed: _pickDate,
                        backgroundColor: const Color(0xFFFBF6EC),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _memo,
                          maxLength: 30,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'メモ（なくてもOK）',
                            counterText: '',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Keypad(onKey: _press),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: FilledButton(
                onPressed: _amount > 0 ? _save : null,
                child: Text(widget.editing == null ? '${env.name}から出す' : '直す'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvChip extends StatelessWidget {
  const _EnvChip({required this.envelope, required this.selected, required this.onTap});
  final Envelope envelope;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Kraft.tint(envelope.tint);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFFBF6EC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Kraft.ink : Kraft.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniEnvelope(tint: envelope.tint, size: 24, savings: envelope.isSavings),
            const SizedBox(width: 6),
            Text(envelope.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Kraft.ink,
                  fontSize: selected ? 15 : 14,
                )),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['00', '0', 'del'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (final r in rows)
            Row(
              children: [
                for (final k in r)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Material(
                        color: k == 'del' ? const Color(0xFFE9D9BC) : const Color(0xFFFBF6EC),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onKey(k),
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: k == 'del'
                                  ? const Icon(Icons.backspace_outlined, color: Kraft.ink)
                                  : Text(k,
                                      style: const TextStyle(
                                          fontFamily: Kraft.display,
                                          fontSize: 24,
                                          color: Kraft.ink)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
