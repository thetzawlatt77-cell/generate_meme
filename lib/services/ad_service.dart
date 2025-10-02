import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  // Ad Unit IDs
  static const String _bannerAdUnitId = 'ca-app-pub-7326763160413413/9454523733';
  static const String _rewardedAdUnitId = 'ca-app-pub-7326763160413413/1576033711';
  static const String _nativeAdUnitId = 'ca-app-pub-7326763160413413/9734381871';

  // Test Ad Unit IDs (use these for testing)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Get appropriate ad unit ID based on environment
  String get bannerAdUnitId => _isTestMode ? _testBannerAdUnitId : _bannerAdUnitId;
  String get rewardedAdUnitId => _isTestMode ? _testRewardedAdUnitId : _rewardedAdUnitId;
  String get nativeAdUnitId => _isTestMode ? _testNativeAdUnitId : _nativeAdUnitId;

  final bool _isTestMode = false; // Set to false for production

  // Initialize Google Mobile Ads SDK
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      
      // Request configuration update for better ad loading
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          testDeviceIds: _isTestMode ? ['AE3967D6D5EB7B9A3A3B45BD0D56E643'] : null,
        ),
      );
      
      debugPrint('Google Mobile Ads initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Google Mobile Ads: $e');
      // Continue without ads - don't crash the app
    }
  }

  // Banner Ad Management
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  Future<void> loadBannerAd() async {
    try {
      if (_bannerAd != null) {
        _bannerAd!.dispose();
      }

      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: ${error.code} - ${error.message}');
            _isBannerAdLoaded = false;
            ad.dispose();
            
            // Retry loading after a delay for certain error codes
            if (error.code == 3) { // No fill error
              Future.delayed(const Duration(seconds: 30), () {
                if (_bannerAd == null) {
                  loadBannerAd();
                }
              });
            }
          },
          onAdOpened: (ad) => debugPrint('Banner ad opened'),
          onAdClosed: (ad) => debugPrint('Banner ad closed'),
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _isBannerAdLoaded = false;
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // Rewarded Ad Management
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Preload rewarded ad for better UX
  Future<void> preloadRewardedAd() async {
    if (!_isRewardedAdLoaded) {
      await loadRewardedAd();
    }
  }

  Future<void> loadRewardedAd() async {
    try {
      if (_rewardedAd != null) {
        _rewardedAd!.dispose();
      }

      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: ${error.code} - ${error.message}');
            _isRewardedAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _isRewardedAdLoaded = false;
    }
  }

  Future<bool> showRewardedAd() async {
    try {
      if (_rewardedAd == null || !_isRewardedAdLoaded) {
        await loadRewardedAd();
      }

      if (_rewardedAd == null) {
        return false;
      }

      bool adCompleted = false;

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          adCompleted = true;
        },
      );

      // Dispose the ad after showing
      _rewardedAd!.dispose();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;

      return adCompleted;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      return false;
    }
  }

  // Native Ad Management
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  NativeAd? get nativeAd => _nativeAd;
  bool get isNativeAdLoaded => _isNativeAdLoaded;

  Future<void> loadNativeAd() async {
    try {
      if (_nativeAd != null) {
        _nativeAd!.dispose();
      }

      _nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('Native ad loaded successfully');
            _isNativeAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Native ad failed to load: ${error.code} - ${error.message}');
            _isNativeAdLoaded = false;
            ad.dispose();
          },
          onAdOpened: (ad) => debugPrint('Native ad opened'),
          onAdClosed: (ad) => debugPrint('Native ad closed'),
        ),
      );

      await _nativeAd!.load();
    } catch (e) {
      debugPrint('Error loading native ad: $e');
      _isNativeAdLoaded = false;
    }
  }

  void disposeNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isNativeAdLoaded = false;
  }

  // Dispose all ads
  void disposeAll() {
    disposeBannerAd();
    disposeNativeAd();
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }
}
