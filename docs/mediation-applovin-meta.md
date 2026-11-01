# 封筒貯金 AdMob メディエーション準備（AppLovin + Meta）

コード側（このリポ）で済んだこと:
- `gma_mediation_applovin` / `gma_mediation_meta` を pubspec に追加
- AppLovin 公式 SKAdNetwork ID 一式 + Meta 2件を Info.plist に統合
- PrivacyInfo のトラッキングドメインに AppLovin / Meta 系を追加
- バージョン 1.1.2+4（未アップロード・未提出）

隼人さん／ブラウザ作業が必要なこと:
1. AppLovin アカウント作成 (dash.applovin.com) → SDK Key / Report Key
   - 支払い: Account > Payments（Tipalti）。閾値 $100。日本個人は W-8 + 本人名義の銀行口座
2. Meta Audience Network: Business / Monetization Manager
   - 封筒貯金をプロパティ追加 → Banner / Interstitial の Placement ID
   - 支払い・税務・2FA。国際は PayPal/現地銀行 $25 または wire $100
3. AdMob コンソール:
   - メディエーショングループ（iOS・バナー / iOS・インタースティシャル、日本向け）
   - Bidding に AppLovin（インタースティシャル）と Meta（バナー＋インタースティシャル）を追加
   - ※AppLovin Bidding はバナー非対応。バナーは Meta が主、AppLovin はウォーターフォール枠も可
   - GDPR / 米国州規制の広告パートナーに AppLovin Corp. と Meta を追加
4. app-ads.txt（https://cedric1963y-lab.github.io/app-ads.txt）:
   - AppLovin: ダッシュボード Account > General > App-ads.txt Info の行を追加（アカウントID入り）
   - Meta: `facebook.com, <BUSINESS_OR_PROPERTY_ID>, DIRECT, c3e20eee3f780d68`
5. App Store Connect の「アプリのプライバシー」: 第三者広告の収集カテゴリは現状とほぼ同じ想定。提出前に確認のみ。
6. アカウントとメディエーション設定が終わったら、この 1.1.2 をビルドして審査提出。

期待効果: いま ~67% のフィルを、未充足リクエストを他社入札で埋めて上げる（特にバナーは Meta、全画面は AppLovin+Meta）。
