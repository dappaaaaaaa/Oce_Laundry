# Backend Kasir Laundry – Laravel + Filament 

## Persiapan
Pastikan sudah menginstal:
- PHP ^8.2
- Composer
- MySQL/MariaDB
- Node.js & NPM (opsional untuk asset build)
- Git

## Setup & Menjalankan
1. Masuk ke direktori backend:
   ```bash
   cd Backend-Laravel/backend-TA
   ```
2. Install dependency Laravel:
   ```bash
   composer install
   ```
3. Duplikasi file `.env.example` menjadi `.env`:
   ```bash
   cp .env.example .env
   ```
4. Sesuaikan konfigurasi database di `.env`:
   ```env
   DB_DATABASE=kasir_laundry
   DB_USERNAME=root
   DB_PASSWORD=
   ```
5. Generate key:
   ```bash
   php artisan key:generate
   ```
6. Jalankan migrasi & seeder:
   ```bash
   php artisan migrate --seed
   ```
   > Seeder sudah termasuk user admin dengan role **Super Admin**.
7. Jalankan server:
   ```bash
   php artisan serve
   ```

Backend dapat diakses pada:
- API: `http://127.0.0.1:8000/api/`
- Filament Admin Panel: `http://127.0.0.1:8000/admin`

## Login Admin (default)
- **Email**: admin@example.com  
- **Password**: password  

## Catatan Integrasi
- Midtrans harus dikonfigurasi di `.env`:
  ```env
  MIDTRANS_SERVER_KEY=your_server_key
  MIDTRANS_IS_PRODUCTION=false
  ```
- Pastikan CORS diaktifkan agar API bisa diakses Flutter.
