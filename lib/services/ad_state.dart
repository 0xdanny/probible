import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

var homeViewBannerAdIsLoaded = false;

class AdState {
  // iOS ad ids
  static const _iosHomeViewBannerAdId =
      'ca-app-pub-8043699384122234/3735513456';

  // Android ad ids
  static const _androidHomeViewBannerAdId =
      'ca-app-pub-8043699384122234/3735513456';

  String get homeViewbannerAdUnitId {
    if (Platform.isAndroid) {
      return _androidHomeViewBannerAdId;
    } else {
      return _iosHomeViewBannerAdId;
    }
  }

  final homeViewBannerAd = BannerAd(
    adUnitId: Platform.isAndroid
        ? _androidHomeViewBannerAdId
        : _iosHomeViewBannerAdId,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        ad.dispose();
        homeViewBannerAdIsLoaded = false;
      },
      onAdLoaded: (Ad ad) {
        homeViewBannerAdIsLoaded = true;
      },
    ),
  );
}
