import 'dart:async'; // Add this import for TimeoutException
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel? _model;
  final bool _isApiKeyValid;
  final String _apiKey;
  
  // Singleton pattern
  static GeminiService? _instance;
  static const Duration _timeout = Duration(seconds: 30);
  
  GeminiService._internal({required String apiKey})
      : _apiKey = apiKey,
        _isApiKeyValid = _validateApiKey(apiKey),
        _model = _validateApiKey(apiKey) 
            ? GenerativeModel(
                model: 'gemini-1.5-flash-latest',
                apiKey: apiKey,
                generationConfig: GenerationConfig(
                  temperature: 0.7,
                  topK: 40,
                  topP: 0.95,
                  maxOutputTokens: 1024,
                ),
                safetySettings: [
                  SafetySetting(
                    HarmCategory.harassment,
                    HarmBlockThreshold.medium,
                  ),
                  SafetySetting(
                    HarmCategory.hateSpeech,
                    HarmBlockThreshold.medium,
                  ),
                ],
              )
            : null {
    if (!_isApiKeyValid && kDebugMode) {
      debugPrint(
        '⚠️ GeminiService: API key tidak valid!\n'
        'Pastikan Anda telah mengatur API key yang benar.\n'
        'Cara setup:\n'
        '1. Dapatkan API key dari Google AI Studio\n'
        '2. Tambahkan ke environment variables atau dart-define\n'
        '3. Format: --dart-define=GEMINI_API_KEY=your_actual_key_here'
      );
    }
  }
  
  // Factory constructor untuk singleton
  factory GeminiService({required String apiKey}) {
    _instance ??= GeminiService._internal(apiKey: apiKey);
    return _instance!;
  }
  
  // Validasi API key yang lebih robust
  static bool _validateApiKey(String apiKey) {
    if (apiKey.isEmpty) return false;
    
    // Check minimum length
    if (apiKey.length < 35) return false;
    
    // Check for common placeholder patterns
    final upperKey = apiKey.toUpperCase();
    final invalidPatterns = [
      'GEMINI_API_KEY',
      'YOUR_API_KEY',
      'PLACEHOLDER',
      'REPLACE_ME',
      'INSERT_KEY',
      'ADD_YOUR_KEY',
      'EXAMPLE_KEY',
      'TEST_KEY',
      'DEMO_KEY',
    ];
    
    for (final pattern in invalidPatterns) {
      if (upperKey.contains(pattern)) return false;
    }
    
    // Check if it starts with expected prefix for Google AI keys
    if (!apiKey.startsWith('AIza')) return false;
    
    return true;
  }
  
  // Getter untuk status API key
  bool get isApiKeyValid => _isApiKeyValid;
  String get apiKeyStatus => _isApiKeyValid 
      ? 'Valid' 
      : 'Invalid atau tidak ditemukan';
  
  // Method untuk test koneksi API
  Future<bool> testConnection() async {
    if (!_isApiKeyValid || _model == null) return false;
    
    try {
      final response = await _model!
          .generateContent([Content.text('Hello')])
          .timeout(_timeout);
      return response.text?.isNotEmpty == true;
    } catch (e) {
      if (kDebugMode) debugPrint('Connection test failed: $e');
      return false;
    }
  }
  
  Future<String> generatePokemonDescription(
      String name, String type) async {
    // Validasi input
    if (name.trim().isEmpty) {
      return 'Error: Nama Pokémon tidak boleh kosong.';
    }
    
    if (!_isApiKeyValid || _model == null) {
      return 'Error: API key tidak valid atau tidak dikonfigurasi dengan benar.\n'
             'Silakan periksa konfigurasi API key Anda.';
    }
    
    final prompt = '''
Anda adalah ahli Pokédex profesional. Buatlah deskripsi singkat dan menarik untuk Pokémon berikut:

Nama: $name
Tipe: $type

Buatlah deskripsi dalam 2-3 kalimat yang mencakup:
- Karakteristik fisik unik
- Kemampuan atau perilaku khas
- Habitat atau lingkungan hidup

Jawab dalam Bahasa Indonesia dengan gaya yang informatif namun menarik.
''';
    
    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(_timeout);
      
      final text = response.text?.trim();
      
      if (text?.isNotEmpty == true) {
        return text!;
      } else {
        return 'Maaf, tidak dapat menghasilkan deskripsi untuk $name saat ini. Silakan coba lagi.';
      }
    } on GenerativeAIException catch (e) {
      return _handleGeminiError(e);
    } on TimeoutException catch (_) {
      return 'Timeout: Permintaan memakan waktu terlalu lama. Silakan coba lagi.';
    } catch (e) {
      if (kDebugMode) debugPrint('Unexpected error in generatePokemonDescription: $e');
      return 'Terjadi kesalahan teknis. Silakan coba lagi dalam beberapa saat.';
    }
  }
  
  Future<String> askAboutPokemon(String name, String question) async {
    // Validasi input
    if (name.trim().isEmpty || question.trim().isEmpty) {
      return 'Error: Nama Pokémon dan pertanyaan tidak boleh kosong.';
    }
    
    if (!_isApiKeyValid || _model == null) {
      return 'Error: API key tidak valid atau tidak dikonfigurasi dengan benar.\n'
             'Silakan periksa konfigurasi API key Anda.';
    }
    
    final prompt = '''
Anda adalah asisten Pokédex yang berpengetahuan luas. Tentang Pokémon "$name", jawablah pertanyaan berikut dengan akurat dan informatif:

Pertanyaan: "$question"

Berikan jawaban yang:
- Akurat berdasarkan pengetahuan Pokémon
- Mudah dipahami
- Dalam Bahasa Indonesia
- Tidak lebih dari 4-5 kalimat

Jika pertanyaan tidak terkait dengan Pokémon, beritahu dengan sopan bahwa Anda hanya dapat menjawab tentang Pokémon.
''';
    
    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(_timeout);
      
      final text = response.text?.trim();
      
      if (text?.isNotEmpty == true) {
        return text!;
      } else {
        return 'Maaf, tidak dapat menjawab pertanyaan tentang $name saat ini. Silakan coba lagi.';
      }
    } on GenerativeAIException catch (e) {
      return _handleGeminiError(e);
    } on TimeoutException catch (_) {
      return 'Timeout: Permintaan memakan waktu terlalu lama. Silakan coba lagi.';
    } catch (e) {
      if (kDebugMode) debugPrint('Unexpected error in askAboutPokemon: $e');
      return 'Terjadi kesalahan teknis. Silakan coba lagi dalam beberapa saat.';
    }
  }
  
  Future<String> generatePokemonFacts(String name) async {
    if (name.trim().isEmpty) {
      return 'Error: Nama Pokémon tidak boleh kosong.';
    }
    
    if (!_isApiKeyValid || _model == null) {
      return 'Error: API key tidak valid atau tidak dikonfigurasi dengan benar.';
    }
    
    final prompt = '''
Buatlah 3 fakta menarik tentang Pokémon "$name" dalam format list:

1. [Fakta pertama tentang asal usul atau evolusi]
2. [Fakta kedua tentang kemampuan unik]
3. [Fakta ketiga tentang trivia menarik]

Jawab dalam Bahasa Indonesia dengan gaya yang informatif dan menarik.
''';
    
    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(_timeout);
      
      final text = response.text?.trim();
      return text?.isNotEmpty == true 
          ? text! 
          : 'Tidak dapat menghasilkan fakta untuk $name saat ini.';
    } on GenerativeAIException catch (e) {
      return _handleGeminiError(e);
    } on TimeoutException catch (_) {
      return 'Timeout: Permintaan memakan waktu terlalu lama.';
    } catch (e) {
      if (kDebugMode) debugPrint('Error in generatePokemonFacts: $e');
      return 'Terjadi kesalahan teknis.';
    }
  }
  
  // Method untuk menangani error Gemini API
  String _handleGeminiError(GenerativeAIException e) {
    if (kDebugMode) debugPrint('Gemini API error: ${e.message}');
    
    final message = e.message.toLowerCase();
    
    if (message.contains('api key') || message.contains('authentication')) {
      return 'Error: API key tidak valid atau bermasalah.\n'
             'Silakan periksa konfigurasi API key Anda.';
    } else if (message.contains('quota') || message.contains('limit')) {
      return 'Error: Kuota API telah habis.\n'
             'Silakan coba lagi nanti atau periksa usage API Anda.';
    } else if (message.contains('safety') || message.contains('blocked')) {
      return 'Maaf, permintaan Anda tidak dapat diproses karena alasan keamanan.\n'
             'Silakan coba dengan pertanyaan yang berbeda.';
    } else if (message.contains('network') || message.contains('connection')) {
      return 'Error: Masalah koneksi internet.\n'
             'Silakan periksa koneksi Anda dan coba lagi.';
    } else {
      return 'Terjadi masalah dengan layanan AI: ${e.message}\n'
             'Silakan coba lagi dalam beberapa saat.';
    }
  }
  
  // Method untuk membersihkan instance (untuk testing)
  static void resetInstance() {
    _instance = null;
  }
  
  // Method untuk mendapatkan info debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'isApiKeyValid': _isApiKeyValid,
      'apiKeyLength': _apiKey.length,
      'apiKeyPrefix': _apiKey.length > 4 ? _apiKey.substring(0, 4) : 'N/A',
      'modelInitialized': _model != null,
      'instanceCreated': _instance != null,
    };
  }
}