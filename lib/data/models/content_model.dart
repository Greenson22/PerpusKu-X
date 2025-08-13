// lib/data/models/content_model.dart

class Content {
  final String
  name; // Ini akan tetap menyimpan nama file, misal: "artikel-1.html"
  final String path;
  final String
  title; // Properti baru untuk menyimpan judul, misal: "Pengenalan Flutter"

  Content({required this.name, required this.path, required this.title});
}
