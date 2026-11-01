# ホーム画面ウィジェット（1.1.2）

- 拡張: `ios/FuutouWidget`（kind `FuutouEnvelopesWidget`）
- App Group: `group.jp.fuutouchokin.app`
- サイズ: 小=1（AppIntentで封筒選択） / 中=4 / 大=9
- データ: Flutter `HomeWidgetSync.publish` → App Group `envelopes_json` → WidgetKit
- ディープリンク: `fuutouchokin://envelope/<id>`（タップでその封筒の支出シート）
- 課金: 無料（広告なし・プレミアムゲートなし）
- Meta/AppLovin メディエーションは別途（このブランチの pubspec に依存はあるが、ウィジェット自体には広告なし）
