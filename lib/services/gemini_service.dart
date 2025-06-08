
import 'package:flutter/foundation.dart'; // Untuk kDebugMode
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model;
  final bool _isApiKeyValid;

  GeminiService({required String apiKey})
      : _isApiKeyValid = apiKey.isNotEmpty &&
          apiKey.length > 30 &&
          // Hindari placeholder API key umum
          !apiKey.toUpperCase().contains('AIzaSyCuBlsP4-bEnx495yu0ANgm-kgeI1c6fVA') &&
          !apiKey.toUpperCase().contains('PLACEHOLDER') &&
          !apiKey.toUpperCase().contains('REPLACE_ME'),
        _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: apiKey,
          // Jika ingin atur suhu atau parameter lain, aktifkan berikut:
          // generationConfig: GenerationConfig(temperature: 0.7),
        ) {
    if (!_isApiKeyValid && kDebugMode) {
      debugPrint(
        '⚠️ GeminiService: API key tidak valid atau placeholder. ' 
        'Pastikan mengirimkan kunci asli melalui --dart-define apiKey.'
        "\nDiterima: '$apiKey'"
      );
    }
  }

  Future<String> generatePokemonDescription(
      String name, String type) async {
    if (!_isApiKeyValid) {
      return 'Error: API key tidak valid atau kosong.';
    }

    final prompt = '''
Anda adalah ahli Pokedex.
Buat deskripsi singkat (2–3 kalimat) untuk Pokémon "$name" tipe $type.
Fokus pada karakteristik unik dan perilaku khas.
Jawab dalam Bahasa Indonesia.''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      return (text?.isNotEmpty == true)
          ? text!
          : 'AI tidak dapat menghasilkan deskripsi saat ini.';
    } on GenerativeAIException catch (e) {
      if (kDebugMode) debugPrint('Gemini API error: ${e.message}');
      return 'Masalah layanan AI: ${e.message}';
    } catch (e) {
      if (kDebugMode) debugPrint('Unexpected error: $e');
      return 'Kesalahan teknis: ${e.toString()}';
    }
  }

  Future<String> askAboutPokemon(
      String name, String question) async {
    if (!_isApiKeyValid) {
      return 'Error: API key tidak valid atau kosong.';
    }

    final prompt = '''
Anda adalah asisten Pokedex.
Tentang Pokémon "$name", jawab pertanyaan berikut dalam Bahasa Indonesia:
"$question"''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      return (text?.isNotEmpty == true)
          ? text!
          : 'AI tidak dapat menjawab saat ini.';
    } on GenerativeAIException catch (e) {
      if (kDebugMode) debugPrint('Gemini API error: ${e.message}');
      return 'Masalah layanan AI: ${e.message}';
    } catch (e) {
      if (kDebugMode) debugPrint('Unexpected error: $e');
      return 'Kesalahan teknis: ${e.toString()}';
    }
  }
} 