// lib/models/pokemon.dart

class Stat {
  final String name;
  final int baseStat;

  Stat({required this.name, required this.baseStat});
}

class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int height; // dalam desimeter
  final int weight; // dalam hektogram
  final List<String> abilities;
  final List<Stat> stats; // <-- DATA BARU
  String? aiDescription; // Untuk deskripsi dari Gemini

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.stats, // <-- DATA BARU
    this.aiDescription,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // Ekstraksi tipe
    List<String> types = (json['types'] as List)
        .map((typeInfo) => typeInfo['type']['name'] as String)
        .toList();

    // Ekstraksi kemampuan
    List<String> abilities = (json['abilities'] as List)
        .map((abilityInfo) => abilityInfo['ability']['name'] as String)
        .toList();

    // Ekstraksi statistik
    List<Stat> stats = (json['stats'] as List).map((statInfo) {
      return Stat(
        name: statInfo['stat']['name'] as String,
        baseStat: statInfo['base_stat'] as int,
      );
    }).toList();

    // Mendapatkan gambar resmi, jika tidak ada, gunakan sprite default
    String imageUrl =
        json['sprites']['other']['official-artwork']['front_default'] ??
            json['sprites']['front_default'] ??
            'https_error_image.png'; // Fallback

    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: imageUrl,
      types: types,
      height: json['height'],
      weight: json['weight'],
      abilities: abilities,
      stats: stats, // <-- DATA BARU
    );
  }

  // Helper untuk mendapatkan URL detail dari URL daftar
  static String getDetailUrl(Map<String, dynamic> pokemonListItemJson) {
    return pokemonListItemJson['url'];
  }
}