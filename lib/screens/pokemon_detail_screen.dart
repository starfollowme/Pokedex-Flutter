// lib/screens/pokemon_detail_screen.dart

import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Dihapus
import '../models/pokemon.dart';
import '../services/gemini_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;
  final String heroTag;

  const PokemonDetailScreen(
      {Key? key, required this.pokemon, required this.heroTag})
      : super(key: key);

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final GeminiService _geminiService = GeminiService(
    apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  );
  String? _aiDescription;
  bool _isLoadingAiDescription = false;

  @override
  void initState() {
    super.initState();
    _fetchAiDescription();
  }

  Future<void> _fetchAiDescription() async {
    // ... (Logika fetch deskripsi AI tidak berubah, hanya akan dipanggil)
    if (widget.pokemon.aiDescription != null &&
        widget.pokemon.aiDescription!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _aiDescription = widget.pokemon.aiDescription;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoadingAiDescription = true);

    final description = await _geminiService.generatePokemonDescription(
      widget.pokemon.name,
      widget.pokemon.types.join(', '),
    );

    if (mounted) {
      setState(() {
        _aiDescription = description;
        if (description != null &&
            !description.toLowerCase().startsWith('error:')) {
          widget.pokemon.aiDescription = description;
        }
        _isLoadingAiDescription = false;
      });
    }
  }

  // Helper untuk warna berdasarkan tipe Pokemon
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'grass':
        return Colors.green.shade400;
      case 'fire':
        return Colors.red.shade400;
      case 'water':
        return Colors.blue.shade400;
      case 'poison':
        return Colors.purple.shade400;
      case 'electric':
        return Colors.amber.shade300;
      case 'rock':
        return Colors.brown.shade400;
      case 'ground':
        return Colors.brown.shade300;
      case 'bug':
        return Colors.lightGreen.shade500;
      case 'psychic':
        return Colors.pink.shade300;
      case 'fighting':
        return Colors.deepOrange.shade600;
      case 'ghost':
        return Colors.indigo.shade400;
      case 'ice':
        return Colors.cyan.shade200;
      case 'dragon':
        return Colors.indigo.shade600;
      case 'dark':
        return Colors.grey.shade800;
      case 'steel':
        return Colors.blueGrey.shade400;
      case 'fairy':
        return Colors.pink.shade200;
      default:
        return Colors.grey.shade400;
    }
  }

  // Widget untuk judul setiap seksi
  Widget _buildSectionTitle(String title, {double topPadding = 24.0}) {
    return Padding(
      padding:
          EdgeInsets.only(top: topPadding, bottom: 8.0, left: 16.0, right: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  // Widget untuk menampilkan statistik dengan progress bar
  Widget _buildStatRow(Stat stat) {
    // Normalisasi nilai stat (misal, maks 255)
    double normalizedValue = stat.baseStat / 255.0;
    String statName = stat.name
        .replaceAll('-', ' ')
        .split(' ')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              statName,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              stat.baseStat.toString(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: normalizedValue,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForType(widget.pokemon.types.first),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pokemonNameCapitalized =
        widget.pokemon.name[0].toUpperCase() + widget.pokemon.name.substring(1);
    final primaryTypeColor = _getColorForType(widget.pokemon.types.first);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: <Widget>[
          // App Bar yang bisa mengecil (collapsible)
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryTypeColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                pokemonNameCapitalized,
                // Menggunakan TextStyle standar
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  // Jika ingin menyesuaikan font family, pastikan font tersebut
                  // sudah terdaftar di pubspec.yaml
                  // fontFamily: 'NamaFontKustom',
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryTypeColor.withOpacity(0.8),
                          primaryTypeColor
                        ],
                      ),
                    ),
                  ),
                  Hero(
                    tag: widget.heroTag,
                    child: Image.network(
                      widget.pokemon.imageUrl,
                      fit: BoxFit.contain,
                      height: 180,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Konten Detail Pokemon
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama dan ID
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          pokemonNameCapitalized,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tipe Pokemon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: widget.pokemon.types.map((type) {
                        return Chip(
                          backgroundColor: _getColorForType(type),
                          label: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Informasi Dasar
                  _buildSectionTitle('Informasi Dasar'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoTile(
                            'Berat', '${widget.pokemon.weight / 10} kg'),
                        _infoTile(
                            'Tinggi', '${widget.pokemon.height / 10} m'),
                      ],
                    ),
                  ),

                  // Kemampuan
                  _buildSectionTitle('Kemampuan'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: widget.pokemon.abilities.map((ability) {
                        return Chip(
                          label: Text(
                              ability[0].toUpperCase() + ability.substring(1)),
                          backgroundColor: Colors.grey.shade200,
                        );
                      }).toList(),
                    ),
                  ),

                  // Statistik Dasar
                  _buildSectionTitle('Statistik Dasar'),
                  ...widget.pokemon.stats
                      .map((stat) => _buildStatRow(stat))
                      .toList(),

                  // Deskripsi AI
                  _buildSectionTitle('Deskripsi Pokedex (AI)'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _isLoadingAiDescription
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border:
                                    Border.all(color: Colors.grey.shade200)),
                            child: Text(
                              _aiDescription ??
                                  'Tidak ada deskripsi AI saat ini.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _aiDescription != null &&
                                            _aiDescription!
                                                .toLowerCase()
                                                .startsWith('error:')
                                        ? Colors.red.shade700
                                        : Colors.black87,
                                    fontStyle: FontStyle.italic,
                                  ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget kecil untuk info berat dan tinggi
  Widget _infoTile(String title, String value) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }
}