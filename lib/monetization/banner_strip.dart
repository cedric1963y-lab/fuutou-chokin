import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ad_service.dart';

/// 画面下のアンカー型アダプティブバナー（幅は画面に合わせる）。
///
/// 高さは SDK が返したサイズを先に確保し、広告の読み込みで画面が跳ねないようにする。
/// 向きや幅が変わったときは破棄して読み直す。
///
/// Large 版は小さい iPhone で高さ 100 になり封筒カードがはみ出すため、
/// 標準のアンカー型（電話の縦向きでは 50 前後）を使う。
class BannerStrip extends StatefulWidget {
  const BannerStrip({super.key, required this.ads});

  final AdService ads;

  /// サイズ取得前、または取得に失敗したときの高さ（従来のバナーと同じ）。
  static const double fallbackHeight = 50;

  @override
  State<BannerStrip> createState() => _BannerStripState();
}

class _BannerStripState extends State<BannerStrip> {
  BannerAd? _ad;
  bool _loaded = false;
  Timer? _retry;
  AdSize? _size;
  int? _width;
  Orientation? _orientation;
  int _loadGen = 0;

  @override
  void initState() {
    super.initState();
    widget.ads.addListener(_onAdsChanged);
  }

  void _onAdsChanged() {
    if (!mounted) return;
    if (widget.ads.adFree) {
      _clearAd();
      setState(() {});
      return;
    }
    _maybeLoad();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_syncSize());
  }

  int _slotWidth(MediaQueryData mq) =>
      (mq.size.width - mq.padding.horizontal).truncate();

  Future<void> _syncSize() async {
    if (!mounted) return;
    final mq = MediaQuery.of(context);
    final orientation = mq.orientation;
    final width = _slotWidth(mq);
    if (width <= 0) return;
    if (_size != null && _width == width && _orientation == orientation) {
      if (_ad == null) _maybeLoad();
      return;
    }

    AdSize? size;
    try {
      // ignore: deprecated_member_use
      size = await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width);
    } catch (e) {
      debugPrint('adaptive banner size failed: $e');
    }
    if (!mounted) return;
    final now = MediaQuery.of(context);
    if (_slotWidth(now) != width || now.orientation != orientation) return;

    // SDK がサイズを返せなくても、幅いっぱいで高さ 50 の枠は確保して読み込む。
    size ??= AdSize(width: width, height: BannerStrip.fallbackHeight.toInt());

    final changed =
        _size == null ||
        _size!.width != size.width ||
        _size!.height != size.height ||
        _width != width ||
        _orientation != orientation;
    _width = width;
    _orientation = orientation;
    if (changed) {
      _clearAd();
      setState(() => _size = size);
      _maybeLoad();
    }
  }

  void _maybeLoad() {
    if (!mounted || !widget.ads.ready || widget.ads.adFree || _ad != null) {
      return;
    }
    final size = _size;
    if (size == null) return;

    final gen = ++_loadGen;
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: widget.ads.request(),
      listener: BannerAdListener(
        onAdLoaded: (a) {
          if (!mounted || gen != _loadGen || !identical(a, _ad)) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, err) {
          // 表示中の自動更新の失敗なら、そのまま次の更新を待つ。
          // （表示中の広告を破棄すると、プラットフォームビューが
          //   破棄済みの広告を探して落ちることがある）
          if (identical(a, _ad) && _loaded) return;
          _dropLater(a as BannerAd, gen);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  void _clearAd() {
    final ad = _ad;
    _ad = null;
    _loaded = false;
    _retry?.cancel();
    _retry = null;
    if (ad != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ad.dispose());
    }
  }

  void _dropLater(BannerAd a, int gen) {
    if (gen != _loadGen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => a.dispose());
      return;
    }
    if (identical(a, _ad)) {
      if (mounted) {
        setState(() {
          _ad = null;
          _loaded = false;
        });
      } else {
        _ad = null;
        _loaded = false;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => a.dispose());
    _retry?.cancel();
    if (mounted) _retry = Timer(const Duration(seconds: 45), _maybeLoad);
  }

  @override
  void dispose() {
    _retry?.cancel();
    widget.ads.removeListener(_onAdsChanged);
    _loadGen++;
    final ad = _ad;
    _ad = null;
    if (ad != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ad.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = _slotWidth(mq);
    if (width != _width || mq.orientation != _orientation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_syncSize());
      });
    }
    final height = (_size?.height.toDouble()) ?? BannerStrip.fallbackHeight;
    final ad = _ad;
    return Container(
      height: height,
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
