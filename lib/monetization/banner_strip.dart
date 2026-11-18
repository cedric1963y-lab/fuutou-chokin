import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ad_service.dart';

/// 画面下のバナー（320x50）。読み込み前も高さを確保して、画面が跳ねないようにする。
class BannerStrip extends StatefulWidget {
  const BannerStrip({super.key, required this.ads});

  final AdService ads;
  static const double height = 54;

  @override
  State<BannerStrip> createState() => _BannerStripState();
}

class _BannerStripState extends State<BannerStrip> {
  BannerAd? _ad;
  bool _loaded = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    widget.ads.addListener(_maybeLoad);
    _maybeLoad();
  }

  void _maybeLoad() {
    if (!mounted || !widget.ads.ready || widget.ads.adFree || _ad != null) return;
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: widget.ads.request(),
      listener: BannerAdListener(
        onAdLoaded: (a) {
          if (!mounted || !identical(a, _ad)) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, err) {
          // 表示中の自動更新の失敗なら、そのまま次の更新を待つ。
          // （表示中の広告を破棄すると、プラットフォームビューが
          //   破棄済みの広告を探して落ちることがある）
          if (identical(a, _ad) && _loaded) return;
          _dropLater(a as BannerAd);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  /// まず画面から外し、そのフレームが終わってから破棄する。少し待って読み直す。
  void _dropLater(BannerAd a) {
    if (identical(a, _ad)) {
      if (mounted) {
        setState(() {
          _ad = null;
          _loaded = false;
        });
      } else {
        _ad = null;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => a.dispose());
    _retry?.cancel();
    if (mounted) _retry = Timer(const Duration(seconds: 45), _maybeLoad);
  }

  @override
  void dispose() {
    _retry?.cancel();
    widget.ads.removeListener(_maybeLoad);
    final ad = _ad;
    _ad = null;
    // AdWidget が木から外れたあと（次のフレーム）に破棄する
    if (ad != null) WidgetsBinding.instance.addPostFrameCallback((_) => ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    return Container(
      height: BannerStrip.height,
      width: double.infinity,
      color: const Color(0xFF4A3727),
      alignment: Alignment.center,
      child: _loaded && ad != null
          ? SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            )
          : null,
    );
  }
}
