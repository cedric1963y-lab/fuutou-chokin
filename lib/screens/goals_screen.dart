import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../domain/goals.dart';
import '../domain/yen.dart';
import '../look/kraft_paper.dart';
import '../look/kraft_theme.dart';

/// 貯金の目標の一覧と並び替え（プレミアム）。
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).controller;
    return Scaffold(
      appBar: AppBar(title: const Text('貯金の目標'), backgroundColor: Kraft.paper),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Kraft.bar,
        foregroundColor: Colors.white,
        onPressed: () => showGoalForm(context),
        icon: const Icon(Icons.add),
        label: const Text('目標を追加', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: KraftPaper(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            final progress = c.goalProgress;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: Text(
                    '「${c.ledger.savings.name}」の合計 ${yen(c.ledger.totalSaved)} を、上の目標から順にあてています。長押しで並び替えできます。',
                    style: const TextStyle(fontSize: 12.5, color: Kraft.inkSoft),
                  ),
                ),
                Expanded(
                  child: progress.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: Text('「旅行 10万円」「車検 8万円」など、\n貯めたいものを追加してみましょう。',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Kraft.inkSoft, height: 1.6)),
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                          itemCount: progress.length,
                          onReorderItem: c.moveGoal,
                          itemBuilder: (context, i) {
                            final p = progress[i];
                            return Padding(
                              key: ValueKey(p.goal.id),
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GoalTile(
                                progress: p,
                                onTap: () => showGoalForm(context, goal: p.goal),
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

/// 目標ひとつ分のカード（履歴画面でも使う）。
class GoalTile extends StatelessWidget {
  const GoalTile({super.key, required this.progress, this.onTap});
  final GoalProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(p.reached ? Icons.emoji_events : Icons.flag_outlined,
                      size: 20, color: p.reached ? Kraft.coinDeep : Kraft.inkSoft),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(p.goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  Text(yen(p.goal.target),
                      style: const TextStyle(fontSize: 13, color: Kraft.inkSoft, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: p.ratio,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE6D6B8),
                  color: p.reached ? Kraft.coin : Kraft.leaf,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${(p.ratio * 100).floor()}%',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                    p.reached ? '達成しました！' : 'あと ${yen(p.remaining)}',
                    style: TextStyle(
                      fontFamily: Kraft.display,
                      fontSize: 16,
                      color: p.reached ? Kraft.coinDeep : Kraft.ink,
                    ),
                  ),
                ],
              ),
              if (p.goal.memo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(p.goal.memo, style: const TextStyle(fontSize: 12, color: Kraft.inkSoft)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const goalNameIdeas = ['旅行', '車検', '引っ越し', '家電', '帰省', '誕生日', '入学準備', '推し活'];

Future<void> showGoalForm(BuildContext context, {SavingsGoal? goal}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Kraft.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _GoalForm(goal: goal),
  );
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({this.goal});
  final SavingsGoal? goal;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _memo;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _name = TextEditingController(text: g?.name ?? '');
    _target = TextEditingController(text: g == null ? '' : '${g.target}');
    _memo = TextEditingController(text: g?.memo ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = AppScope.of(context).controller;
    final nav = Navigator.of(context);
    final name = _name.text.trim();
    final target = int.tryParse(_target.text) ?? 0;
    if (name.isEmpty || target <= 0) return;
    final g = widget.goal;
    if (g == null) {
      await c.addGoal(name: name, target: target, memo: _memo.text);
    } else {
      await c.updateGoal(g, name: name, target: target, memo: _memo.text);
    }
    nav.pop();
  }

  Future<void> _delete() async {
    final c = AppScope.of(context).controller;
    final nav = Navigator.of(context);
    final g = widget.goal!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('「${g.name}」の目標を消しますか？'),
        content: const Text('目標だけが消えます。貯金の金額や記録はそのままです。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('消す', style: TextStyle(color: Kraft.stamp))),
        ],
      ),
    );
    if (ok == true) {
      await c.removeGoal(g);
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.goal == null;
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
                  Text(isNew ? '目標を追加' : '目標を編集',
                      style: const TextStyle(fontFamily: Kraft.display, fontSize: 20)),
                  const Spacer(),
                  if (!isNew)
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
                maxLength: 14,
                decoration: const InputDecoration(labelText: '何のために貯める？'),
              ),
              if (isNew)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final n in goalNameIdeas)
                      ActionChip(
                        label: Text(n),
                        backgroundColor: const Color(0xFFFBF6EC),
                        onPressed: () => setState(() => _name.text = n),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(labelText: '目標の金額（円）', prefixText: '¥ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memo,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'メモ（任意）', hintText: '例: 来年の夏までに'),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: _save, child: Text(isNew ? '追加する' : '保存する')),
            ],
          ),
        ),
      ),
    );
  }
}
