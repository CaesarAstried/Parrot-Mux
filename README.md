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

1. **Clone Repositori Parrot-Mux**  
   Jalankan perintah berikut di Termux untuk meng-clone repositori:

   ```bash
   git clone https://github.com/CaesarAstried/Parrot-Mux/

2. Masuk ke Direktori Parrot-Mux
Setelah repositori berhasil di-clone, masuk ke direktori Parrot-Mux dengan perintah:

   ```bash
   cd Parrot-Mux


3. Beri Izin Eksekusi pada Script
Berikan izin eksekusi pada script start.sh dengan perintah:

   ```bash
   chmod +x start.sh
   

4. Jalankan Script Instalasi
Setelah memberikan izin eksekusi, jalankan script untuk memulai instalasi dengan perintah:

   ```bash
   ./start.sh

Proses instalasi akan dimulai, dan beberapa dependensi akan diunduh. Ikuti petunjuk di layar untuk menyelesaikan proses instalasi.



Akses Parrot OS dengan VNC Viewer

Setelah instalasi selesai, kamu bisa mengakses Parrot OS menggunakan VNC Viewer.

1. Instal VNC Viewer
Instal aplikasi VNC Viewer di perangkat Android kamu dari Google Play Store.


2. Jalankan VNC Viewer
Buka aplikasi VNC Viewer, lalu masukkan alamat IP dan port yang telah disediakan oleh script Parrot-Mux.


3. Masukkan Kata Sandi
Saat diminta, masukkan kata sandi yang telah diatur selama proses instalasi untuk masuk ke desktop Parrot OS.


