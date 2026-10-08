# 封筒貯金 袋分け貯金

給料日にお金を封筒（袋）に分けてやりくりする「封筒貯金・袋分け貯金」の iPhone アプリ。
封筒ごとの予算と残り、すばやい支出入力、給料日の締め（残りを繰り越す／貯金へ移す）、期間ごとの履歴と貯金の合計。

- Bundle ID: `jp.fuutouchokin.app` / 1.0.0+1 / iPhone のみ / 日本語 / ホーム画面名「封筒貯金」
- データは端末内（shared_preferences）だけ。アカウント・サーバー・銀行連携なし
- **無料・広告のみ**（Google AdMob）。アプリ内課金・サブスクなし
  - バナー: メイン3画面（封筒／貯金と履歴／設定）の下
  - 全画面: 給料日の締めのあと、袋の編集を閉じたときだけ。4分以上あけ、起動60秒以内は出さない。支出の入力では出さない
  - 起動後: UMP 同意 → ATT → SDK 初期化。ATT 未許可・同意なしは非パーソナライズ広告
  - ID: release は本番（`lib/monetization/ad_ids.dart`、`ios/Flutter/Release.xcconfig`）、debug / profile はGoogle公式テストID
- 給料日: 1〜30日・月末。土日祝なら前の平日（日本の祝日・振替休日・国民の休日を計算）

## 構成

```
lib/domain        封筒・支出・締め（Ledger）、給料日（PaydayRule）、祝日、金額表示
lib/persistence   端末内保存
lib/state         画面から使う状態（LedgerController）
lib/monetization  AdMob（同意・ATT・バナー・全画面の間隔）
lib/look          クラフト紙のテーマ、封筒カード、コイン
lib/screens       封筒一覧・支出入力・給料日の袋分け・貯金と履歴・設定・袋の編集・はじめての設定
lib/showcase.dart ストア撮影用の見本データ（debug のみ）
```

## 開発

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
flutter pub get && flutter analyze && flutter test
```

## ストア用スクリーンショット

```sh
tool/capture_app_store_screenshots.sh ~/Downloads/fuutou-screenshots-raw
```

## ページ

`docs/` を GitHub Pages で公開: https://cedric1963y-lab.github.io/fuutou-chokin/ （サポート / privacy.html / terms.html）

アイコンは `tool/make_icon.py`（深緑の地に茶封筒2枚、開いた封筒から¥のコイン）。フォントは Kiwi Maru（SIL OFL 1.1）。
