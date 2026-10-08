/// 金額の表示。円は整数だけで持つ。
String yen(int amount, {bool sign = false}) {
  final neg = amount < 0;
  final digits = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final body = '¥$buf';
  if (neg) return '−$body';
  if (sign && amount > 0) return '+$body';
  return body;
}

const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

String weekdayJa(DateTime d) => _weekdays[d.weekday - 1];

/// 10/23（金）
String mdW(DateTime d) => '${d.month}/${d.day}（${weekdayJa(d)}）';

/// 10/23
String md(DateTime d) => '${d.month}/${d.day}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
