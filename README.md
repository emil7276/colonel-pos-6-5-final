# CP Colonel POS 6.5

Flutter Android POS untuk operasional Colonel Fried Chicken / CP.

## Struktur
- `app/lib/data` — SQLite dan operasi transaksi
- `app/lib/models` — model data
- `app/lib/services` — cetak nota
- `app/lib/features` — UI per fitur
- `app/lib/core` — tema, utilitas, dan komponen bersama

## Build
Push ke `main` atau jalankan workflow **CP Colonel POS 6.5** secara manual. GitHub Actions membuat file platform Android, mengambil dependency, membuat launcher icon CP, menjalankan analyzer, dan menghasilkan APK release.

## Login bawaan
- Administrator: `admin` / `1234`
- Kasir: `kasir` / `1234`

Ganti kredensial default setelah instalasi pada menu Manajemen Pengguna.
