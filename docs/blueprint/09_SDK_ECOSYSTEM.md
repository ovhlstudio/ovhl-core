# 🌐 09 - STRATEGI EKOSISTEM & SDK (v1)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                      |
| ------------------ | ------------------------------------------ |
| **ID Dokumen**     | `ARC-v1-009`                               |
| **Status**         | `Aktif (Rilis Baru)`                       |
| **Lokasi Path**    | `./docs/blueprint/09_SDK_ECOSYSTEM.md`     |
| **Tipe Dokumen**   | `Visi Jangka Panjang & Strategi Ekosistem` |
| **Target Audiens** | `Core Team, Product Team, AI Assistant`    |
| **Relasi**         | `Index: 00_MASTER_INDEX.md`, `Ref: 01-08`  |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)`    |
| **Dibuat**         | `29 Oktober 2025`                          |

---

## 🚀 9.1. VISI JANGKA PANJANG

OVHL v1 dirancang bukan hanya sebagai _framework_ internal, tetapi sebagai **fondasi ekosistem pengembangan Roblox** yang terbuka, kolaboratif, dan berkelanjutan. Visi jangka panjangnya mencakup tiga pilar utama:

1.  **SDK (Software Development Kit) Canggih:** Menyediakan _developer tools_ (CLI, plugin VS Code, dll.) yang cerdas untuk mempercepat _workflow_ secara drastis, termasuk integrasi dengan AI Co-Development.
2.  **Ekosistem Plugin & Marketplace Terbuka:** Memungkinkan developer pihak ketiga untuk membuat, membagikan, dan bahkan memonetisasi _plugin_, komponen UI, _asset pack_ "pintar", dan _template_ proyek yang kompatibel dengan OVHL.
3.  **Pengalaman Game Dinamis:** Memfasilitasi pembuatan fitur _live-ops_ seperti _Admin Panel_ untuk konfigurasi _real-time_, _event_ dalam game, dan manajemen komunitas.

Arsitektur v1 yang telah kita definisikan (Auto-Discovery, DI, Coder/Builder, Networking v1, UI Hooks) secara fundamental **sudah mendukung** realisasi visi ini. Bagian ini menjelaskan bagaimana caranya.

---

## 🔌 9.2. DUKUNGAN UNTUK SDK (SOFTWARE DEVELOPMENT KIT)

SDK OVHL v1 (berbasis Node.js di folder `sdk/`) bertujuan untuk menjadi "Asisten Cerdas" bagi developer. Arsitektur v1 memungkinkan ini melalui:

- **Analisa Proyek Otomatis:**

  - **DI & `__manifest`:** _Tool_ SDK dapat dengan mudah mem-parsing semua `__manifest` di `src/` untuk membangun peta dependensi proyek secara akurat. Ini memungkinkan fitur seperti:
    - Validasi dependensi sebelum _runtime_.
    - Visualisasi grafik dependensi.
    - Saran _refactoring_ otomatis.
  - **`NetworkSchema.lua`:** SDK bisa membaca "kontrak" jaringan ini untuk:
    - Men-generate dokumentasi API _network_ otomatis.
    - Memberikan _autocomplete_ dan validasi _real-time_ saat developer menulis kode `OVHL:Invoke/Fire` di VS Code.
    - Men-generate _mock server_ untuk _testing_ UI _client_ secara terisolasi.
  - **Pola Standar:** Karena semua modul mengikuti _template_ standar v1 (DI, Lifecycle), SDK bisa dengan mudah "memahami" struktur kode dan melakukan operasi _refactoring_ atau _codemod_ (transformasi kode otomatis).

- **Generator Kode Cerdas (Scaffolding v1):**

  - Perintah `npm run create:service` tidak hanya membuat file kosong, tapi bisa:
    - Otomatis menambahkan _service_ baru ke `dependencies` modul lain yang mungkin membutuhkannya (berdasarkan analisa atau input interaktif).
    - Men-generate _template_ metode dasar berdasarkan _domain_ (`gameplay` vs `data`).
    - Men-generate _unit test_ dasar untuk _service_ baru.
  - Generator `create:component` bisa otomatis membuat `__manifest` dan kerangka `:Knit`/`:Destroy` sesuai standar Coder/Builder.

- **Integrasi AI Co-Development:**
  - Struktur yang eksplisit (`__manifest`, `NetworkSchema`, DI) menyediakan **konteks berkualitas tinggi** untuk AI.
  - SDK bisa bertindak sebagai "penerjemah" antara developer dan AI:
    1.  Developer: "AI, buatkan _service_ baru untuk _leaderboard_."
    2.  SDK: Menganalisa proyek, mengumpulkan konteks relevan (Schema, Service yang ada), membuat _prompt_ detail untuk AI.
    3.  AI: Men-generate kode `LeaderboardService.lua` sesuai standar v1.
    4.  SDK: Menerima kode, memvalidasinya, menempatkannya di folder yang benar, dan mungkin otomatis menambahkannya ke `dependencies` modul lain.

---

## 🏪 9.3. DUKUNGAN UNTUK PLUGIN & MARKETPLACE

Visi ekosistem terbuka memungkinkan developer lain berkontribusi. Arsitektur v1 memfasilitasi ini:

- **Distribusi via Wally:**

  - _Plugin_ pihak ketiga adalah _library_ Luau biasa yang bisa dipublikasikan ke _registry_ Wally (seperti Uplift Games Index atau _registry_ custom).
  - Developer game pengguna OVHL cukup menambahkan `NamaVendor/NamaPlugin = "1.0.0"` di `wally.toml` mereka dan menjalankan `wally install`. _Plugin_ akan ter-download ke folder `Packages/`.

- **Integrasi Mulus via Auto-Discovery:**

  - `ModuleLoader` / `ServiceManager` v1 **otomatis mendeteksi** modul _plugin_ di dalam folder `Packages/` **jika** modul tersebut memiliki `__manifest` yang valid.
  - Artinya, _plugin_ bisa "Tinggal Instal, Langsung Jalan" tanpa perlu kode registrasi manual di game utama.

- **Interaksi Aman via Dependency Injection:**

  - _Plugin_ bisa dengan aman meminta _core service_ OVHL (seperti `Logger`, `DataService`, `RemoteManager`) dengan mendeklarasikannya di `__manifest.dependencies`.
  - Framework akan meng-_inject_ _instance service_ yang sama, memastikan _plugin_ berinteraksi dengan sistem inti secara terkontrol. _Plugin_ tidak bisa "merusak" _core service_ secara langsung.

- **Komponen Coder/Builder sebagai Produk:**

  - Alur kerja Coder/Builder (`:Knit`/`:Destroy`) sangat cocok untuk _marketplace_.
  - Developer pihak ketiga bisa menjual:
    - **Asset Pack "Pintar":** Kumpulan Model 3D atau Prefab UI yang sudah diberi Atribut `ovhl:component` dan disertai _logic_-nya di `src/shared/components/`. Pengguna tinggal _drag-and-drop_ ke game mereka.
    - **Komponen UI Lanjutan:** Komponen UI siap pakai (dibuat dengan Hooks v1) yang bisa diimpor dan digunakan di game pengguna.

- **Monetisasi & Kualitas:**
  - Strategi _revenue sharing_ bisa diterapkan di _marketplace_ resmi.
  - Tim OVHL bisa melakukan kurasi atau _review_ kualitas untuk _plugin_ yang ingin masuk ke _marketplace_ resmi, memastikan standar dan keamanan.

---

## 📊 9.4. DUKUNGAN UNTUK ADMIN PANEL & LIVE OPS

Membuat _Admin Panel_ atau fitur _live ops_ (mengubah _setting_ game secara _real-time_) menjadi mudah dengan arsitektur v1:

- **Konfigurasi Dinamis (`ConfigService` & `__config`):**

  - Setiap modul bisa mendefinisikan _setting_ defaultnya di `__config`.
  - `ConfigService` (Core Service) akan menjadi pusat pengelolaan konfigurasi. Dia membaca `__config`, mengecek _override_ dari `DataService` (yang diubah oleh Admin Panel), dan menyediakan API `OVHL:GetConfig()` yang selalu memberikan nilai konfigurasi **terbaru**.

- **Gerbang Aman (`RemoteManager v1`):**

  - Admin Panel (yang merupakan UI Client khusus admin) akan menggunakan `OVHL:Invoke` untuk mengirim perubahan _setting_ ke server.
  - Akan ada _remote_ khusus (misal: `Admin:UpdateConfig`) yang **wajib** memiliki validasi **autentikasi & otorisasi** yang ketat di _handler_-nya (memastikan hanya admin yang bisa memanggil). `RemoteManager v1` juga akan menerapkan _schema validation_ dan _rate limiting_ sebagai lapisan keamanan tambahan.

- **Update Real-time (`EventBus`):**
  - Saat `ConfigService` berhasil menyimpan _setting_ baru (dari Admin Panel), dia akan **`OVHL:Emit`** sebuah _event_ internal spesifik, misalnya `ConfigUpdated:ShopModule`.
  - Modul yang relevan (`ShopModule`) akan `OVHL:Subscribe` ke _event_ ini.
  - Ketika _event_ diterima, _handler_ di `ShopModule` akan memanggil `OVHL:GetConfig("ShopModule")` lagi untuk mendapatkan _setting_ terbaru dan mengaplikasikannya secara _live_ tanpa perlu _restart_ server.

**Contoh Alur Live Update Harga Item:**

1.  Admin buka Panel UI, ubah harga "Sword" jadi 150.
2.  Panel UI `OVHL:Invoke("Admin:UpdateShopConfig", { prices = { Sword = 150 } })`.
3.  Server terima, validasi admin, panggil `ConfigService:Set("ShopModule", newConfig)`.
4.  `ConfigService` simpan ke `DataService` **DAN** `OVHL:Emit("ConfigUpdated:ShopModule", newConfig)`.
5.  `ShopModule` (yang sudah `Subscribe`) terima _event_, panggil `self.config = OVHL:GetConfig("ShopModule")`.
6.  Detik berikutnya, pemain yang beli "Sword" akan dikenakan harga 150.

Pola yang sama bisa digunakan untuk mengaktifkan/menonaktifkan fitur, memulai _event_ X2 XP, mengirim pengumuman global, dll.

---

### 🔄 Riwayat Perubahan (Changelog)

| Versi | Tanggal     | Penulis                 | Perubahan                                                                                                                                                            |
| :---- | :---------- | :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0 | 29 Okt 2025 | OVHL Core Team & Gemini | Rilis awal file detail Strategi Ekosistem & SDK v1. Dibuat dari hasil split `00_MASTER_INDEX.md`. Menjelaskan bagaimana arsitektur v1 mendukung visi jangka panjang. |
