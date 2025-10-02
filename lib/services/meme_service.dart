import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/meme.dart';

class MemeService {
  static const String _baseUrl = 'https://raw.githubusercontent.com/mike14082025/getMemePicture/refs/heads/main/getAll';

  /// Fetches meme templates from the GitHub API
  Future<List<Meme>> fetchMemes() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle different possible response structures
        List<dynamic> memesJson;
        
        if (responseData is Map<String, dynamic>) {
          final data = responseData;
          if (data['success'] == true && data['data'] != null) {
            // Original imgflip structure
            memesJson = data['data']['memes'] as List<dynamic>;
          } else if (data['memes'] != null) {
            // Direct memes array
            memesJson = data['memes'] as List<dynamic>;
          } else {
            throw Exception('Unexpected API response structure: ${data.keys}');
          }
        } else if (responseData is List) {
          // Direct array response
          memesJson = responseData;
        } else {
          throw Exception('Unexpected API response type: ${responseData.runtimeType}');
        }
        
        return memesJson.map((json) => Meme.fromJson(json)).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  /// Picks a random meme from the provided list
  Meme randomMeme(List<Meme> memes) {
    if (memes.isEmpty) {
      throw Exception('Cannot pick random meme from empty list');
    }
    
    final random = Random();
    return memes[random.nextInt(memes.length)];
  }

  /// Fetches memes and returns a random one
  Future<Meme> fetchRandomMeme() async {
    final memes = await fetchMemes();
    return randomMeme(memes);
  }
}
