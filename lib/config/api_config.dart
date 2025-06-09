import 'package:flutter/foundation.dart';

class ApiConfig {
  // Ambil nilai dari dart-define hanya sekali di sini, compile-time constant
  static const String _envApiKey = String.fromEnvironment('AIzaSyBChqvjDx4i_yTTMJzFKmAr_-8p8qJpY0s', defaultValue: '');

  static const String developmentApiKey = 'AIzaSyBChqvjDx4i_yTTMJzFKmAr_-8p8qJpY0s'; // isi jika perlu

  static String getGeminiApiKey() {
    if (_envApiKey.isNotEmpty) {
      return _envApiKey;
    }

    if (kDebugMode && developmentApiKey != 'YOUR_DEVELOPMENT_API_KEY_HERE') {
      return developmentApiKey;
    }

    return '';
  }

  static Map<String, dynamic> validateSetup() {
    final apiKey = getGeminiApiKey();
    final isValid = apiKey.isNotEmpty &&
                    apiKey.length > 30 &&
                    apiKey.startsWith('AIza');

    return {
      'isValid': isValid,
      'apiKey': apiKey,
      'instructions': _getSetupInstructions(),
      'debugInfo': kDebugMode
          ? {
              'apiKeyLength': apiKey.length,
              'apiKeyPrefix': apiKey.length > 4 ? apiKey.substring(0, 4) : 'N/A',
              'fromEnvironment': apiKey == _envApiKey,
              'fromDevelopmentKey': apiKey == developmentApiKey,
            }
          : null,
    };
  }

  static String _getSetupInstructions() {
    return '''
🔧 CARA SETUP GEMINI API KEY:

1. DAPATKAN API KEY:
   - Kunjungi: https://aistudio.google.com/app/apikey
   - Login dengan akun Google
   - Buat API key baru
   - Copy API key yang dihasilkan

2. SETUP UNTUK DEVELOPMENT:
   - Di file api_config.dart
   - Ganti 'YOUR_DEVELOPMENT_API_KEY_HERE' dengan API key asli (opsional untuk dev)

3. SETUP UNTUK PRODUCTION:
   - Gunakan dart-define saat build/run:
   - flutter run --dart-define=GEMINI_API_KEY=your_actual_key
   - flutter build --dart-define=GEMINI_API_KEY=your_actual_key

4. TESTING:
   - Pastikan API key dimulai dengan 'AIza'
   - Panjang sekitar 39 karakter
   - Tidak mengandung spasi atau karakter khusus

⚠️ PENTING:
- JANGAN commit API key ke version control
- Gunakan dart-define untuk production
- Simpan API key dengan aman
''';
  }

  static String getSetupStatus() {
    final validation = validateSetup();

    if (validation['isValid']) {
      return '✅ API key berhasil dikonfigurasi dan valid';
    } else {
      return '❌ API key belum dikonfigurasi atau tidak valid';
    }
  }
}
