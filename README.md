# 💧 Aplikasi Kasir Laundry – Tugas Akhir
Proyek ini merupakan **Aplikasi Kasir Laundry** yang dikembangkan sebagai **Tugas Akhir** di Politeknik Negeri Pontianak.  
Aplikasi ini dirancang untuk membantu proses operasional laundry, mulai dari pencatatan transaksi, manajemen pelanggan, pembayaran (Cash & QRIS), hingga pencetakan struk dengan printer thermal Bluetooth.

## ✨ Fitur Utama
- 📌 Manajemen Pelanggan (CRUD)
- 🧺 Manajemen Barang & Layanan Laundry
- 💳 Pembayaran (Cash & QRIS via Midtrans)
- 🧾 Pencetakan Struk dengan Printer Thermal Bluetooth
- 📊 Laporan & Riwayat Transaksi
- 🔐 Manajemen User & Role dengan Filament Shield (backend)
- 🌐 Realtime Update antara Flutter & Laravel API

## 🛠️ Teknologi yang Digunakan
- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: [Laravel 11](https://laravel.com/) + [Filament](https://filamentphp.com/) (Admin Panel)
- **Database**: MySQL/MariaDB
- **Payment Gateway**: Midtrans (QRIS Integration)
- **Printing**: print_bluetooth_thermal (Flutter package)

## 🖥️ Spesifikasi Sistem
Untuk menjalankan proyek ini, disarankan:
- **OS**: Windows 10/11, Linux, atau macOS
- **RAM**: Minimal 4GB (disarankan 8GB+)
- **Software yang Dibutuhkan**:
  - [Flutter SDK](https://docs.flutter.dev/get-started/install)
  - [Android Studio](https://developer.android.com/studio) / [VSCode](https://code.visualstudio.com/)
  - [Laragon](https://laragon.org/) / XAMPP / LAMP (untuk MySQL & PHP)
  - PHP ^8.2
  - Composer
  - Node.js & NPM (opsional untuk frontend tambahan di Laravel)
  - Git

## 📂 Struktur Folder
```
|- README.md (ini file root)
|- frontend/   -> Proyek Flutter
|- backend/    -> Proyek Laravel + Filament
```

## ⚡ Catatan Integrasi
Agar **Frontend (Flutter)** dapat terhubung dengan **Backend (Laravel API)**:
1. Pastikan backend Laravel sudah dijalankan dan dapat diakses via browser/postman.  
   Contoh: `http://127.0.0.1:8000/api/`
2. Sesuaikan **BASE_URL** di konfigurasi `ApiService` pada proyek Flutter (`frontend/`) agar mengarah ke URL backend.
3. Pastikan database sudah dimigrasikan & di-seed sesuai panduan di `backend/README.md`.

👉 Lihat panduan detail pada folder masing-masing:
- [Frontend README](./Frontend-Mobile/aplikasi_demo_test/README.md)
- [Backend README](./Backend-Laravel/backend-TA/README.md)
