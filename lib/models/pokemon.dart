// lib/models/pokemon.dart

class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int height; // dalam desimeter
  final int weight; // dalam hektogram
  final List<String> abilities;
  String? aiDescription; // Untuk deskripsi dari Gemini

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
    required this.abilities,
    this.aiDescription,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // Ekstraksi data dari PokeAPI
    List<String> types = (json['types'] as List)
        .map((typeInfo) => typeInfo['type']['name'] as String)
        .toList();
    
    List<String> abilities = (json['abilities'] as List)
        .map((abilityInfo) => abilityInfo['ability']['name'] as String)
        .toList();

    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['front_default'] ?? 'https_error_image.png', // Fallback image
      types: types,
      height: json['height'],
      weight: json['weight'],
      abilities: abilities,
    );
  }

  // Helper untuk mendapatkan URL detail dari URL daftar
  static String getDetailUrl(Map<String, dynamic> pokemonListItemJson) {
    return pokemonListItemJson['url'];
  }
}