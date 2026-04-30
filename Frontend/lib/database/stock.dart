import 'dart:io';

class Stock {
  final int id;
  final String nama;
  final String kuantitas;
  final String unit;
  final String? keterangan;
  final File? gambar;

  Stock({
    required this.id,
    required this.nama,
    required this.kuantitas,
    required this.unit,
    this.keterangan,
    this.gambar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kuantitas': kuantitas,
      'unit': unit,
      'keterangan': keterangan,
      'gambar': gambar,
    };
  }

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      id: map['id'],
      nama: map['nama'],
      kuantitas: map['kuantitas'],
      unit: map['unit'],
      keterangan: map['keterangan'],
      gambar: map['gambar'],
    );
  }
}
