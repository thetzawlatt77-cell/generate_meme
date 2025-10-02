import 'package:shared_preferences/shared_preferences.dart';

class SaveLimitService {
  static const String _saveCountKey = 'daily_save_count';
  static const String _lastResetDateKey = 'last_reset_date';
  static const int _maxFreeSaves = 3;

  /// Get the current daily save count
  static Future<int> getCurrentSaveCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetDailyLimit(prefs);
    return prefs.getInt(_saveCountKey) ?? 0;
  }

  /// Get remaining free saves for today
  static Future<int> getRemainingFreeSaves() async {
    final currentCount = await getCurrentSaveCount();
    return _maxFreeSaves - currentCount;
  }

  /// Check if user can save without watching ads
  static Future<bool> canSaveWithoutAd() async {
    final remainingSaves = await getRemainingFreeSaves();
    return remainingSaves > 0;
  }

  /// Increment the save count after a successful save
  static Future<void> incrementSaveCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetDailyLimit(prefs);
    
    final currentCount = prefs.getInt(_saveCountKey) ?? 0;
    await prefs.setInt(_saveCountKey, currentCount + 1);
  }

  /// Check if it's a new day and reset the counter if needed
  static Future<void> _checkAndResetDailyLimit(SharedPreferences prefs) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastResetDateString = prefs.getString(_lastResetDateKey);
    
    if (lastResetDateString == null) {
      // First time using the app
      await prefs.setString(_lastResetDateKey, today.toIso8601String());
      await prefs.setInt(_saveCountKey, 0);
    } else {
      final lastResetDate = DateTime.parse(lastResetDateString);
      final lastResetDay = DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);
      
      if (today.isAfter(lastResetDay)) {
        // New day - reset the counter
        await prefs.setString(_lastResetDateKey, today.toIso8601String());
        await prefs.setInt(_saveCountKey, 0);
      }
    }
  }

  /// Get the next reset time (12 AM tomorrow)
  static DateTime getNextResetTime() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
  }

  /// Get time remaining until next reset
  static Duration getTimeUntilReset() {
    final nextReset = getNextResetTime();
    return nextReset.difference(DateTime.now());
  }

  /// Format time remaining as a readable string
  static String getTimeUntilResetString() {
    final duration = getTimeUntilReset();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Reset the save count (for testing purposes)
  static Future<void> resetSaveCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_saveCountKey, 0);
    await prefs.setString(_lastResetDateKey, DateTime.now().toIso8601String());
  }

  /// Get save limit info for display
  static Future<Map<String, dynamic>> getSaveLimitInfo() async {
    final currentCount = await getCurrentSaveCount();
    final remainingSaves = await getRemainingFreeSaves();
    final canSaveFree = await canSaveWithoutAd();
    final timeUntilReset = getTimeUntilResetString();
    
    return {
      'currentCount': currentCount,
      'remainingSaves': remainingSaves,
      'maxFreeSaves': _maxFreeSaves,
      'canSaveFree': canSaveFree,
      'timeUntilReset': timeUntilReset,
    };
  }
}
