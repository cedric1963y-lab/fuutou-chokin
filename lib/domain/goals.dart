/// 貯金の目標（プレミアム）。例: 「旅行」10万円。
///
/// 目標ごとに別の袋を作るのではなく、「貯金」の袋の合計を
/// 上の目標から順にあてて、どこまで届いたかを見せる。
class SavingsGoal {
  SavingsGoal({
    required this.id,
    required this.name,
    required this.target,
    this.memo = '',
  });

  final String id;
  String name;

  /// 目標額（円）
  int target;
  String memo;

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'memo': memo,
      };

  static SavingsGoal fromJson(Map<String, dynamic> j) => SavingsGoal(
        id: j['id'] as String,
        name: j['name'] as String,
        target: (j['target'] as num).toInt(),
        memo: j['memo'] as String? ?? '',
      );
}

/// 目標ひとつ分の進み具合。
class GoalProgress {
  const GoalProgress(this.goal, this.covered);
  final SavingsGoal goal;

  /// この目標にあてられた額（0〜target）
  final int covered;

  int get remaining => goal.target - covered;
  bool get reached => goal.target > 0 && covered >= goal.target;

  /// 0.0〜1.0
  double get ratio => goal.target <= 0 ? 0 : (covered / goal.target).clamp(0.0, 1.0);
}

/// 貯金の合計 [saved] を、並び順に目標へあてる。
List<GoalProgress> fillGoals(List<SavingsGoal> goals, int saved) {
  var pool = saved < 0 ? 0 : saved;
  final out = <GoalProgress>[];
  for (final g in goals) {
    final need = g.target < 0 ? 0 : g.target;
    final take = pool >= need ? need : pool;
    pool -= take;
    out.add(GoalProgress(g, take));
  }
  return out;
}
