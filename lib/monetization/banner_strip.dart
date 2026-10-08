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

  @override
  void initState() {
    super.initState();
    widget.ads.addListener(_maybeLoad);
    _maybeLoad();
  }

  void _maybeLoad() {
    if (!widget.ads.ready || _ad != null) return;
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: widget.ads.request(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, err) {
          a.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    widget.ads.removeListener(_maybeLoad);
    _ad?.dispose();
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
