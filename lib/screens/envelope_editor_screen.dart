import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/yen.dart';
import '../look/envelope_card.dart';
import '../look/kraft_paper.dart';
import '../look/kraft_theme.dart';

/// 袋の追加・予算・色・並び順。閉じるときに、変更があればたまに全画面広告。
class EnvelopeEditorScreen extends StatefulWidget {
  const EnvelopeEditorScreen({super.key});

  @override
  State<EnvelopeEditorScreen> createState() => _EnvelopeEditorScreenState();
}

class _EnvelopeEditorScreenState extends State<EnvelopeEditorScreen> {
  bool _changed = false;
  late final AppScope _scope;
  bool _scoped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scoped) {
      _scope = AppScope.of(context);
      _scoped = true;
      _scope.controller.addListener(_markChanged);
    }
  }

  void _markChanged() => _changed = true;

  @override
  void dispose() {
    _scope.controller.removeListener(_markChanged);
    if (_changed) {
      // 画面を閉じたあと（支出の入力中ではない）にだけ要求する
      Future<void>.delayed(const Duration(milliseconds: 350), _scope.ads.maybeShowInterstitial);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _scope.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('袋の編集'), backgroundColor: Kraft.paper),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-envelope',
        backgroundColor: Kraft.bar,
        foregroundColor: Colors.white,
        onPressed: () => showEnvelopeForm(context),
        icon: const Icon(Icons.add),
        label: const Text('袋を追加', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: KraftPaper(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            final l = c.ledger;
            final monthly = l.envelopes.fold(0, (s, e) => s + e.budget);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('長押しで並び替え。タップで名前・予算・色を変えられます。',
                            style: TextStyle(fontSize: 12.5, color: Kraft.inkSoft)),
                      ),
                      Text('毎月 ${yen(monthly)}',
                          style: const TextStyle(fontFamily: Kraft.display, fontSize: 17)),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                    itemCount: l.envelopes.length,
                    onReorderItem: c.reorderEnvelopes,
                    itemBuilder: (context, i) {
                      final e = l.envelopes[i];
                      return Card(
                        key: ValueKey(e.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: MiniEnvelope(tint: e.tint, size: 36, savings: e.isSavings),
                          title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(e.isSavings
                              ? '貯金の袋・毎月 ${yen(e.budget)}'
                              : '予算 ${yen(e.budget)}'
                                  '${e.carried != 0 ? '・繰越 ${yen(e.carried, sign: true)}' : ''}'),
                          trailing: const Icon(Icons.drag_handle),
                          onTap: () => showEnvelopeForm(context, envelope: e),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 袋ひとつの追加・編集シート。
Future<void> showEnvelopeForm(BuildContext context, {Envelope? envelope}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Kraft.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _EnvelopeForm(envelope: envelope),
  );
}

class _EnvelopeForm extends StatefulWidget {
  const _EnvelopeForm({this.envelope});
  final Envelope? envelope;

  @override
  State<_EnvelopeForm> createState() => _EnvelopeFormState();
}

class _EnvelopeFormState extends State<_EnvelopeForm> {
  late final TextEditingController _name;
  late final TextEditingController _budget;
  late EnvelopeTint _tint;

  @override
  void initState() {
    super.initState();
    final e = widget.envelope;
    _name = TextEditingController(text: e?.name ?? '');
    _budget = TextEditingController(text: e == null ? '' : '${e.budget}');
    _tint = e?.tint ?? EnvelopeTint.kraft;
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = AppScope.of(context).controller;
    final nav = Navigator.of(context);
    final name = _name.text.trim();
    final budget = int.tryParse(_budget.text) ?? 0;
    if (name.isEmpty) return;
    final e = widget.envelope;
    if (e == null) {
      await c.addEnvelope(name: name, budget: budget, tint: _tint);
    } else {
      await c.updateEnvelope(e, name: name, budget: budget, tint: _tint);
    }
    nav.pop();
  }

  Future<void> _delete() async {
    final c = AppScope.of(context).controller;
    final nav = Navigator.of(context);
    final e = widget.envelope!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('「${e.name}」を消しますか？'),
        content: const Text('この袋と、今の期間のこの袋の支出の記録が消えます。締めた期間の履歴は残ります。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('消す', style: TextStyle(color: Kraft.stamp))),
        ],
      ),
    );
    if (ok == true) {
      await c.removeEnvelope(e);
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.envelope;
    final isNew = e == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(isNew ? '袋を追加' : '袋を編集',
                      style: const TextStyle(fontFamily: Kraft.display, fontSize: 20)),
                  const Spacer(),
                  if (!isNew && !e.isSavings)
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline, color: Kraft.stamp),
                      label: const Text('消す', style: TextStyle(color: Kraft.stamp)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                maxLength: 10,
                decoration: const InputDecoration(labelText: '袋の名前'),
              ),
              if (isNew)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final n in envelopeNameIdeas)
                      ActionChip(
                        label: Text(n),
                        backgroundColor: const Color(0xFFFBF6EC),
                        onPressed: () => setState(() => _name.text = n),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _budget,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  labelText: e?.isSavings == true ? '毎月の貯金額（円）' : '毎月の予算（円）',
                  prefixText: '¥ ',
                ),
              ),
              const SizedBox(height: 14),
              const Text('封筒の色', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in EnvelopeTint.values)
                    GestureDetector(
                      onTap: () => setState(() => _tint = t),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: t == _tint ? Kraft.ink : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: MiniEnvelope(tint: t, size: 40),
                          ),
                          Text(Kraft.tintName(t), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: _save, child: Text(isNew ? '追加する' : '保存する')),
            ],
          ),
        ),
      ),
    );
  }
}
