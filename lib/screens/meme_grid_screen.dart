import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/meme.dart';
import '../services/meme_service.dart';
import '../services/ad_service.dart';
import '../theme.dart';

class MemeGridScreen extends StatefulWidget {
  final List<Meme> memes;
  final Function(Meme) onMemeSelected;

  const MemeGridScreen({
    super.key,
    required this.memes,
    required this.onMemeSelected,
  });

  @override
  State<MemeGridScreen> createState() => _MemeGridScreenState();
}

class _MemeGridScreenState extends State<MemeGridScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Meme> _filteredMemes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredMemes = widget.memes;
    _searchController.addListener(_filterMemes);
    
    // Load native ad
    AdService.instance.loadNativeAd();
  }

  @override
  void dispose() {
    _searchController.dispose();
    AdService.instance.disposeNativeAd();
    super.dispose();
  }

  void _filterMemes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMemes = widget.memes;
      } else {
        _filteredMemes = widget.memes
            .where((meme) => meme.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _refreshMemes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final memeService = MemeService();
      final newMemes = await memeService.fetchMemes();
      setState(() {
        _filteredMemes = newMemes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh memes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text(
          'Choose Meme Template',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshMemes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredMemes.length} memes found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Grid view
          Expanded(
            child: _filteredMemes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No memes found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _filteredMemes.length + (AdService.instance.isNativeAdLoaded ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show native ad as first item if loaded
                      if (AdService.instance.isNativeAdLoaded && index == 0) {
                        return _NativeAdCard();
                      }
                      
                      // Adjust index for memes (subtract 1 if native ad is shown)
                      final memeIndex = AdService.instance.isNativeAdLoaded ? index - 1 : index;
                      final meme = _filteredMemes[memeIndex];
                      return _MemeCard(
                        meme: meme,
                        onTap: () {
                          widget.onMemeSelected(meme);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemeCard extends StatelessWidget {
  final Meme meme;
  final VoidCallback onTap;

  const _MemeCard({
    required this.meme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
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
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Meme name
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                meme.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Dimensions info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                '${meme.width} × ${meme.height}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeAdCard extends StatelessWidget {
  const _NativeAdCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: AdService.instance.isNativeAdLoaded && AdService.instance.nativeAd != null
            ? AdWidget(ad: AdService.instance.nativeAd!)
            : Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Text(
                    'Ad Loading...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
