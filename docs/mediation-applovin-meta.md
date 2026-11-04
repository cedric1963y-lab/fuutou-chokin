# 封筒貯金 AdMob メディエーション準備（AppLovin + Meta）

※コードはブランチ `feature/mediation-applovin-meta` に退避。`feature/home-widget`（1.1.2 ウィジェット提出用）には含めない。

コード側で済んだこと（mediation ブランチ）:
- `gma_mediation_applovin` / `gma_mediation_meta` を pubspec に追加
- AppLovin 公式 SKAdNetwork ID 一式 + Meta 2件を Info.plist に統合
- PrivacyInfo のトラッキングドメインに AppLovin / Meta 系を追加

隼人さん／ブラウザ作業が必要なこと:
1. AppLovin アカウント作成 (dash.applovin.com) → SDK Key / Report Key
2. Meta Audience Network: Business / Monetization Manager
3. AdMob コンソールでメディエーショングループ設定
4. app-ads.txt 更新
5. アカウント準備ができたら mediation ブランチを取り込んで別バージョンで提出
