# Parrot-Mux
Panduan untuk menginstal **Parrot OS** di perangkat Android menggunakan **Termux** dan **VNC Viewer**.

Parrot OS adalah sistem operasi berbasis Debian yang digunakan untuk pengujian penetrasi, keamanan, dan forensik digital. Dengan proyek ini, kamu dapat menginstal dan menjalankan Parrot OS di perangkat Android melalui Termux dan mengaksesnya menggunakan VNC Viewer.

## Persyaratan

Sebelum memulai, pastikan kamu memiliki hal-hal berikut:
- Perangkat Android yang sudah ter-root (optional, tapi lebih disarankan)
- **Termux** yang terinstal di perangkatmu
- **VNC Viewer** untuk mengakses desktop Parrot OS
- Koneksi internet yang stabil

## Langkah Instalasi

1. **Instal Termux**  
   Jika belum terinstal, kamu bisa mengunduh Termux dari [Google Play Store](https://play.google.com/store/apps/details?id=com.termux) atau [F-Droid](https://f-droid.org/packages/com.termux/).

2. **Clone Repositori Parrot-Mux**  
   Buka Termux, lalu jalankan perintah berikut untuk meng-clone repositori:

   ```bash
   git clone https://github.com/CaesarAstried/Parrot-Mux/
