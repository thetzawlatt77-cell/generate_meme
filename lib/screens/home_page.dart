import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/meme.dart';
import '../models/meme_text.dart';
import '../services/meme_service.dart';
import '../services/save_limit_service.dart';
import '../utils/capture.dart';
import '../utils/watermark.dart';
import '../widgets/draggable_meme_text.dart';
import '../theme.dart';
import 'meme_grid_screen.dart'; // Import grid screen
import '../services/ad_service.dart'; // Import ad service

class MemeController extends ChangeNotifier {
  final MemeService _memeService = MemeService();
  final Uuid _uuid = const Uuid();

  List<Meme> _templates = [];
  Meme? _currentMeme;
  List<MemeText> _overlays = [];
  bool _isLoading = false;
  Size _canvasSize = Size.zero;
  String? _selectedTextId;

  List<Meme> get templates => _templates;
  Meme? get currentMeme => _currentMeme;
  List<MemeText> get overlays => _overlays;
  bool get isLoading => _isLoading;
  Size get canvasSize => _canvasSize;
  String? get selectedTextId => _selectedTextId;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Check if it's the first launch of the day
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // Get YYYY-MM-DD
    final lastLaunchDate = prefs.getString('last_launch_date');
    
    if (lastLaunchDate != today) {
      // First launch of the day - use the special start meme
      _currentMeme = Meme(
        id: 'daily_start',
        name: 'Daily Start Meme',
        url: 'https://i.imgflip.com/30b1gx.jpg',
        width: 500,
        height: 500,
      );
      _addDefaultTexts();
      
      // Update the last launch date
      await prefs.setString('last_launch_date', today);
    }

    // Always fetch templates for the grid screen
    try {
      _templates = await _memeService.fetchMemes();
      if (_templates.isNotEmpty && lastLaunchDate == today) {
        // Only set random meme if it's not the first launch of the day
        _currentMeme = _memeService.randomMeme(_templates);
        _addDefaultTexts();
      }
    } catch (e) {
      debugPrint('Error fetching memes: $e');
      // Use a fallback image if templates fail to load
      if (_currentMeme == null) {
        _currentMeme = Meme(
          id: 'fallback',
          name: 'Default Meme',
          url: 'https://i.imgflip.com/30b1gx.jpg',
          width: 500,
          height: 500,
        );
        _addDefaultTexts();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void nextMeme() {
    if (_templates.isNotEmpty) {
      _currentMeme = _memeService.randomMeme(_templates);
      notifyListeners();
    }
  }

  void setCurrentMeme(Meme meme) {
    _currentMeme = meme;
    notifyListeners();
  }

  void addText([String? preset]) {
    if (_canvasSize == Size.zero) return;

    final text = preset ?? 'NEW TEXT';
    final centerX = _canvasSize.width / 2;
    final centerY = _canvasSize.height / 2;

    final memeText = MemeText(
      id: _uuid.v4(),
      text: text,
      offset: Offset(centerX - 50, centerY - 16), // Approximate center
    );

    _overlays.add(memeText);
    notifyListeners();
  }

  void updateText(String id, MemeText changes) {
    final index = _overlays.indexWhere((text) => text.id == id);
    if (index != -1) {
      _overlays[index] = changes;
      notifyListeners();
    }
  }

  void removeText(String id) {
    _overlays.removeWhere((text) => text.id == id);
    notifyListeners();
  }

  void setCanvasSize(Size size) {
    _canvasSize = size;
    notifyListeners();
  }

  void selectText(String id) {
    _selectedTextId = id;
    notifyListeners();
  }

  void clearSelection() {
    _selectedTextId = null;
    notifyListeners();
  }

  void reset() {
    _overlays.clear();
    _selectedTextId = null;
    notifyListeners();
  }

  /// Manually set the daily start meme (for testing or special occasions)
  Future<void> setDailyStartMeme() async {
    _currentMeme = Meme(
      id: 'daily_start',
      name: 'Daily Start Meme',
      url: 'https://i.imgflip.com/30b1gx.jpg',
      width: 500,
      height: 500,
    );
    _addDefaultTexts();
    notifyListeners();
  }

  void _addDefaultTexts() {
    if (_canvasSize == Size.zero) return;

    final topText = MemeText(
      id: _uuid.v4(),
      text: 'TOP TEXT',
      offset: Offset(_canvasSize.width / 2 - 50, 20),
    );

    final bottomText = MemeText(
      id: _uuid.v4(),
      text: 'BOTTOM TEXT',
      offset: Offset(_canvasSize.width / 2 - 60, _canvasSize.height - 60),
    );

    _overlays = [topText, bottomText];
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MemeController _controller;
  late ConfettiController _confettiController;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final TextEditingController _textInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MemeController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _controller.init();
    
    // Load banner ad and listen for changes
    AdService.instance.loadBannerAd().then((_) {
      if (mounted) setState(() {}); // Rebuild UI when banner ad loads
    });
    
    // Preload rewarded ad for better UX
    AdService.instance.preloadRewardedAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _textInputController.dispose();
    AdService.instance.disposeBannerAd();
    super.dispose();
  }

  Future<void> _saveImage() async {
    try {
      // Check if user can save without watching ads
      final canSaveFree = await SaveLimitService.canSaveWithoutAd();
      final saveLimitInfo = await SaveLimitService.getSaveLimitInfo();
      
      bool adCompleted = true; // Default to true for free saves
      
      if (!canSaveFree) {
        // User has used all free saves, must watch ad
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You\'ve used all ${saveLimitInfo['maxFreeSaves']} free saves today!\n'
                'Watch an ad to save more memes.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Show rewarded ad
        adCompleted = await AdService.instance.showRewardedAd();
        
        if (!adCompleted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ad not completed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        // User can save for free, show info about remaining saves
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Free save! ${saveLimitInfo['remainingSaves']} saves remaining today.\n'
                'Resets in ${saveLimitInfo['timeUntilReset']}.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Capture the image
      final imageBytes = await CaptureUtils.capturePng(_repaintBoundaryKey);

      // Add watermark/trademark
      final watermarkedBytes = await WatermarkUtils.addWatermark(
        imageBytes,
        watermarkPath: 'assets/images/logo512.png',
        opacity: 0.7,
        size: 0.12, // 12% of image size
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.all(12),
      );

      // Check permissions for Android <= 28
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 28) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to save images'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }

      // Save to gallery
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await SaverGallery.saveImage(
        watermarkedBytes,
        fileName: 'meme_$timestamp.png',
        skipIfExists: false,
      );

      if (result.isSuccess && mounted) {
        // Increment save count
        await SaveLimitService.incrementSaveCount();
        
        // Show success message with updated info
        final updatedInfo = await SaveLimitService.getSaveLimitInfo();
        final message = canSaveFree 
            ? 'Saved! ${updatedInfo['remainingSaves']} free saves left today.'
            : 'Saved! Watch ads for more saves.';
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
          _confettiController.play();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onChooseMeme() async {
    HapticFeedback.lightImpact();
    
    if (_controller.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading meme templates...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_controller.templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No meme templates available. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemeGridScreen(
          memes: _controller.templates,
          onMemeSelected: (selectedMeme) {
            _controller.setCurrentMeme(selectedMeme);
          },
        ),
      ),
    );
  }

  void _onAddText() {
    final text = _textInputController.text.trim();
    if (text.isNotEmpty) {
      _controller.addText(text);
      _textInputController.clear();
    } else {
      _controller.addText('TOP TEXT');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
           appBar: AppBar(
             backgroundColor: Colors.white,
             title: Text(
               'Meme Generator',
               style: TextStyle(
                 color: AppTheme.primaryBlue,
                 fontSize: 24,
                 fontWeight: FontWeight.bold,
               ),
             ),
           ),
          body: Container(
        decoration: BoxDecoration(
         // gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Controls row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    // Button row
                    Row(
                      children: [
                      
                        Expanded(
                          child: GestureDetector(
                            onTap:()=>_onChooseMeme(),
                            child: Container(
                              padding:EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                 color: Colors.blue.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(50)
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.select_all,color: AppTheme.primaryBlue,),
                                  SizedBox(width: 5,),
                                  Text('Choose Image',style: TextStyle(color: AppTheme.primaryBlue,fontWeight: FontWeight.bold),),
                                ],
                              ),
                            ),
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Text input row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textInputController,
                            decoration:  InputDecoration(
                              hintText: 'Add text...',
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                   borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3),)
                              ),
                              border:OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
                              ),
                              suffixIcon: Icon(Icons.add),
                            ),
                            onSubmitted: (_) => _onAddText(),
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),

              // Canvas area
              Expanded(
                child: Padding(

                  padding: const EdgeInsets.all(16),
                  child: _controller.currentMeme != null
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                final meme = _controller.currentMeme!;
                                final aspectRatio = meme.width / meme.height;

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _controller.setCanvasSize(Size(
                                    constraints.maxWidth,
                                    constraints.maxWidth / aspectRatio,
                                  ));
                                });

                                return AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: RepaintBoundary(
                                    key: _repaintBoundaryKey,
                                    child: Stack(
                                      children: [
                                        // Meme image
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: CachedNetworkImage(
                                            key: ValueKey(meme.id),
                                            imageUrl: meme.url,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                color: Colors.white,
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.error,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Text overlays
                                        ..._controller.overlays.map(
                                          (memeText) => DraggableMemeText(
                                            key: ValueKey(memeText.id),
                                            memeText: memeText,
                                            canvasSize: Size(
                                              constraints.maxWidth,
                                              constraints.maxWidth / aspectRatio,
                                            ),
                                            onChanged: (updatedText) {
                                              _controller.updateText(
                                                updatedText.id,
                                                updatedText,
                                              );
                                            },
                                            onDelete: (id) {
                                              _controller.removeText(id);
                                            },
                                            isSelected: _controller.selectedTextId == memeText.id,
                                            onSelect: (id) {
                                              _controller.selectText(id);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                ),
              ),

                     // Bottom action row
                     Padding(
                       padding: EdgeInsets.only(
                         left: 16,
                         right: 16,
                         top: 16,
                         bottom: AdService.instance.isBannerAdLoaded ? 100 : 16, // Add more space for banner ad
                       ),
                       child: Column(
                         children: [
                           // Save limit indicator
                           FutureBuilder<Map<String, dynamic>>(
                             future: SaveLimitService.getSaveLimitInfo(),
                             builder: (context, snapshot) {
                               if (snapshot.hasData) {
                                 final info = snapshot.data!;
                                 final remainingSaves = info['remainingSaves'] as int;
                                 final canSaveFree = info['canSaveFree'] as bool;
                                 
                                 return Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                   decoration: BoxDecoration(
                                     color: canSaveFree 
                                         ? Colors.green.withValues(alpha: 0.1)
                                         : Colors.orange.withValues(alpha: 0.1),
                                     borderRadius: BorderRadius.circular(20),
                                     border: Border.all(
                                       color: canSaveFree ? Colors.green : Colors.orange,
                                       width: 1,
                                     ),
                                   ),
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(
                                         canSaveFree ? Icons.check_circle : Icons.warning,
                                         color: canSaveFree ? Colors.green : Colors.orange,
                                         size: 16,
                                       ),
                                       const SizedBox(width: 8),
                                       Text(
                                         canSaveFree 
                                             ? '$remainingSaves free saves left today'
                                             : 'Watch ad to save more',
                                         style: TextStyle(
                                           color: canSaveFree ? Colors.green : Colors.orange,
                                           fontWeight: FontWeight.w600,
                                           fontSize: 12,
                                         ),
                                       ),
                                     ],
                                   ),
                                 );
                               }
                               return const SizedBox.shrink();
                             },
                           ),
                           const SizedBox(height: 12),
                           
                           // Action buttons
                           Row(
                             children: [
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: _controller.overlays.isEmpty ? null : _saveImage,
                                   icon: const Icon(Icons.save),
                                   label: const Text('Save Image'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: AppTheme.primaryBlue,
                                     foregroundColor: Colors.white,
                                     padding: const EdgeInsets.symmetric(vertical: 16),
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: OutlinedButton.icon(
                                   onPressed: _controller.overlays.isEmpty ? null : () {
                                     _controller.reset();
                                   },
                                   icon: const Icon(Icons.refresh),
                                   label: const Text('Reset'),
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: AppTheme.primaryBlue,
                                     padding: const EdgeInsets.symmetric(vertical: 16),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
            ],
          ),
        ),
        ),
        ),
        
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 1.57, // Down
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              Colors.blue,
              Colors.lightBlue,
              Colors.cyan,
              Colors.teal,
              Colors.indigo,
              Colors.blueAccent,
            ],
          ),
        ),
        
        // Banner Ad
        if (AdService.instance.isBannerAdLoaded && AdService.instance.bannerAd != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                top: false, // Don't add top safe area for banner
                child: SizedBox(
                  width: AdService.instance.bannerAd!.size.width.toDouble(),
                  height: AdService.instance.bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: AdService.instance.bannerAd!),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
