import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/feedback/rating_ask.dart';

void main() {
  final now = DateTime(2026, 11, 2, 20, 0);
  bool ok({
    DateTime? openedAt,
    int launches = 5,
    String? firstDay = '2026-10-30',
    String? askedFor,
    int? lastAd,
  }) =>
      RatingAsk.shouldAsk(
        now: now,
        openedAt: openedAt ?? now.subtract(const Duration(minutes: 3)),
        launches: launches,
        firstDay: firstDay,
        askedFor: askedFor,
        lastInterstitialMs: lastAd,
      );

  test('条件がそろえばお願いできる', () => expect(ok(), isTrue));
  test('起動3回未満は出さない', () => expect(ok(launches: 2), isFalse));
  test('初めて使った日は出さない', () => expect(ok(firstDay: '2026-11-02'), isFalse));
  test('起動直後（60秒未満）は出さない',
      () => expect(ok(openedAt: now.subtract(const Duration(seconds: 20))), isFalse));
  test('全画面広告の2分以内は出さない', () {
    final ms = now.subtract(const Duration(seconds: 50)).millisecondsSinceEpoch;
    expect(ok(lastAd: ms), isFalse);
    final old = now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
    expect(ok(lastAd: old), isTrue);
  });
  test('同じバージョンでは1回だけ', () => expect(ok(askedFor: RatingAsk.version), isFalse));
  test('テストでは締めの後でも出さない（広告はいつも通り）', () async {
    expect(await const RatingAsk().afterPaydayClosed(5), isFalse);
  });
}
