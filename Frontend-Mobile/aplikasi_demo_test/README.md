# Frontend – Flutter Kasir Laundry

## Persiapan
Pastikan sudah menginstal:
- Flutter SDK (versi terbaru disarankan)
- Android Studio / VSCode
- Emulator Android atau perangkat fisik
- Git

Cek instalasi Flutter:
```bash
flutter doctor
```

## Cara Menjalankan
1. Masuk ke direktori frontend:
   ```bash
   cd frontend
   ```
2. Install dependency:
   ```bash
   flutter pub get
   ```
3. Sesuaikan **BASE_URL API** di file konfigurasi `lib/services/api_service.dart` agar sesuai dengan URL backend Laravel.
   ```dart
   static const String baseUrl = "http://127.0.0.1:8000/api"; 
   ```
   > Jika dijalankan di emulator Android, gunakan `10.0.2.2` sebagai localhost.
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## Catatan
- Untuk mencetak struk via Bluetooth, pastikan perangkat printer sudah dipasangkan (pairing) dengan Android.
- Untuk pembayaran QRIS, pastikan backend Laravel dengan Midtrans sudah dikonfigurasi.
