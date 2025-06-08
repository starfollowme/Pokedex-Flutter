// lib/screens/pokemon_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/gemini_service.dart'; // Pastikan path ini benar

class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({Key? key, required this.pokemon}) : super(key: key);

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  // Mengambil API Key dari variabel lingkungan dan meneruskannya ke GeminiService
  // PENTING: Anda harus menjalankan aplikasi dengan:
  // flutter run --dart-define=GEMINI_API_KEY=KUNCI_API_BARU_ANDA_YANG_AMAN
  final GeminiService _geminiService = GeminiService(
    apiKey: const String.fromEnvironment(
      'AIzaSyAFGzMBcfVC2XOxLU6BF2svr9ic-OtwXDg',
      // defaultValue opsional jika Anda ingin menangani kasus kunci tidak ada secara berbeda
      // Namun, lebih baik memastikan selalu ada via --dart-define saat menjalankan.
      // defaultValue: 'YOUR_FALLBACK_OR_PLACEHOLDER_API_KEY_FOR_DEBUG_ONLY'
    ),
  );
  String? _aiDescription;
  bool _isLoadingAiDescription = false;

  @override
  void initState() {
    super.initState();
    _fetchAiDescription();
  }

  Future<void> _fetchAiDescription() async {
    if (widget.pokemon.aiDescription != null && widget.pokemon.aiDescription!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _aiDescription = widget.pokemon.aiDescription;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingAiDescription = true;
      });
    }
    
    // Tidak perlu blok try-catch di sini jika GeminiService sudah menangani error
    // dan mengembalikan string pesan error.
    final description = await _geminiService.generatePokemonDescription(
      widget.pokemon.name,
      widget.pokemon.types.isNotEmpty ? widget.pokemon.types.join(', ') : 'unknown',
    );

    if (mounted) {
      setState(() {
        _aiDescription = description; // Akan berisi deskripsi sukses atau pesan error dari service
        // Hanya cache jika deskripsi bukan pesan error dari service kita
        if (description != null && !description.toLowerCase().startsWith('error:')) {
            widget.pokemon.aiDescription = description;
        }
        _isLoadingAiDescription = false;
      });
    }
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.end),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemon.name[0].toUpperCase() + widget.pokemon.name.substring(1)),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Image.network(
                widget.pokemon.imageUrl,
                height: 200,
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 200, color: Colors.grey),
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200,
                    width: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '#${widget.pokemon.id.toString().padLeft(3, '0')} ${widget.pokemon.name[0].toUpperCase()}${widget.pokemon.name.substring(1)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionTitle('Informasi Dasar'),
            _buildStatRow('Tipe', widget.pokemon.types.map((t) => t[0].toUpperCase() + t.substring(1)).join(', ')),
            _buildStatRow('Tinggi', '${widget.pokemon.height / 10} m'),
            _buildStatRow('Berat', '${widget.pokemon.weight / 10} kg'),
            
            _buildSectionTitle('Kemampuan'),
            Padding(
              padding: const EdgeInsets.only(left: 8.0), // Sedikit indentasi untuk daftar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.pokemon.abilities
                    .map((ability) => Text('• ${ability[0].toUpperCase()}${ability.substring(1)}', style: const TextStyle(fontSize: 16)))
                    .toList(),
              ),
            ),

            _buildSectionTitle('Deskripsi Pokedex (AI)'),
            _isLoadingAiDescription
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))
                : Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red.withOpacity(0.2))
                    ),
                    child: Text(
                      _aiDescription ?? 'Tidak ada deskripsi AI saat ini.',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: _aiDescription != null && _aiDescription!.toLowerCase().startsWith('error:')
                            ? Colors.red[700] // Warna merah untuk pesan error
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}