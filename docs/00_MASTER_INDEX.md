# 💎 OVHL CORE v1 - MASTER BLUEPRINT (INDEX)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                                                                                                                                             |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ID Dokumen**     | `OVHL-v1-MASTER-IDX`                                                                                                                                              |
| **Status**         | `Aktif (Versi Index)`                                                                                                                                             |
| **Lokasi Path**    | `./docs/00_MASTER_INDEX.md`                                                                                                                                       |
| **Tipe Dokumen**   | `Index Utama / Overview`                                                                                                                                          |
| **Target Audiens** | `Semua Pihak (Titik Awal Navigasi)`                                                                                                                               |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)`                                                                                                                           |
| **Dibuat**         | `29 Oktober 2025`                                                                                                                                                 |
| **Catatan**        | Dokumen ini adalah **index utama** yang memberikan gambaran umum dan link ke dokumen detail (`01` s/d `10`). **Detail teknis lengkap ada di file masing-masing.** |

---

## 🌟 PENGANTAR & VISI OVHL v1

Selamat datang di OVHL Core v1, sebuah ekosistem pengembangan game Roblox berbasis Luau yang dirancang untuk **modularitas**, **skalabilitas**, **kemudahan penggunaan**, **pemisahan workflow Coder/Builder**, dan **kesiapan untuk SDK & AI Co-Development**.

Framework ini berdiri di atas 5 pilar utama:

1.  🔥 **Auto-Discovery:** "Tinggal Taruh, Langsung Jalan" via `__manifest`.
2.  🔑 **API Sederhana (`OVHL`):** Satu titik akses global.
3.  ⚖️ **Pemisahan Coder vs. Builder:** Workflow berbasis Atribut/Tag.
4.  ⚠️ **"No Crash":** Stabilitas via `pcall` dan _graceful degradation_.
5.  🤖 **SDK/AI Ready:** Arsitektur eksplisit via DI, Manifest, Schema.

- ➡️ **Detail Filosofi & Visi:** Lihat [**`01_ARCHITECTURE_CORE.md`**](./docs/blueprint/01_ARCHITECTURE_CORE.md)

---

## 📚 DAFTAR ISI DOKUMEN DETAIL

Berikut adalah "bab-bab" dari dokumentasi OVHL v1. Klik link untuk membaca detail setiap topik.

1.  **[🏛️ `01_ARCHITECTURE_CORE.md`](./docs/blueprint/01_ARCHITECTURE_CORE.md)**

    - Membahas Filosofi Inti, Diagram Arsitektur (Server, Client, Shared), Sistem Auto-Discovery (`__manifest`, `__config`), Pola Komunikasi (`EventBus` vs `RemoteManager`), dan Filosofi Error Handling ("No Crash").
    - _Ini adalah fondasi utama._

2.  **[🚀 `02_DEV_WORKFLOW.md`](./docs/blueprint/02_DEV_WORKFLOW.md)**

    - Panduan lengkap mulai dari Setup Lingkungan (Rojo, Wally, VS Code), Struktur Proyek, Alur Kerja Harian (termasuk Hot Reloading), Standar Git Workflow, hingga pengenalan CLI Tools (SDK).
    - _Wajib dibaca developer baru._

3.  **[📋 `03_CODING_STANDARDS_DI.md`](./docs/blueprint/03_CODING_STANDARDS_DI.md)**

    - Aturan main koding: Konvensi Penamaan (Naming Convention), Pola Dependency Injection (DI) v1 via `:Inject()`, Template Standar Modul Server, dan Standar Error Handling (`pcall` + Logging).
    - _Panduan gaya koding tim._

4.  **[🎨 `04_UI_FRAMEWORK_HOOKS.md`](./docs/blueprint/04_UI_FRAMEWORK_HOOKS.md)**

    - Detail implementasi UI Framework v1 berbasis Hooks (menggunakan library Fusion): Filosofi, API Hooks (`Value`, `Computed`, `Cleanup`, `OnEvent`), Template Standar Modul UI, dan Sistem Theming.
    - _Panduan membuat UI._

5.  **[🧩 `05_CODER_BUILDER_WORKFLOW.md`](./docs/blueprint/05_CODER_BUILDER_WORKFLOW.md)**

    - Penjelasan mendalam tentang alur kerja pemisahan Coder vs. Builder: Konsep, Alur Kerja (Builder pakai Atribut/Tag, Coder pakai `:Knit`/`:Destroy`), Standar Atribut `ovhl:component`, dan cara kerja `ComponentService` otomatis.
    - _Kunci kolaborasi tim Coder & Builder._

6.  **[🔐 `06_NETWORKING_SECURITY.md`](./docs/blueprint/06_NETWORKING_SECURITY.md)**

    - Spesifikasi `RemoteManager` v1 yang aman dan cepat: Arsitektur Middleware, Fitur Keamanan (Validasi Schema `t`, Rate Limiting), Fitur Performa (Batching, Caching), dan Fitur Monitoring (Network Analytics).
    - _Penting untuk keamanan & performa game multiplayer._

7.  **[📚 `07_API_REFERENCE.md`](./docs/blueprint/07_API_REFERENCE.md)**

    - "Cheat Sheet" lengkap semua API publik OVHL v1: API `OVHL` Global Accessor (Server & Client), Metadata Auto-Discovery (`__manifest`, `__config`), API UI Hooks, API Komponen Coder/Builder, dan (Advanced) API Core Services.
    - _Referensi cepat saat coding._

8.  **[🍳 `08_COOKBOOK_RECIPES.md`](./docs/blueprint/08_COOKBOOK_RECIPES.md)**

    - Kumpulan contoh kode praktis ("resep") untuk menyelesaikan tugas umum menggunakan OVHL v1: Membuat UI Hooks, Menyimpan Data (DI), Komponen Coder/Builder (Lava Part), Networking Aman (Beli Item), dll.
    - _Contoh implementasi nyata._

9.  **[🌐 `09_SDK_ECOSYSTEM.md`](./docs/blueprint/09_SDK_ECOSYSTEM.md)**

    - Visi jangka panjang framework: Bagaimana arsitektur v1 mendukung pembuatan SDK (CLI Tools), pengembangan Plugin & Marketplace pihak ketiga, serta implementasi Admin Panel untuk konfigurasi live.
    - _Arah pengembangan framework._

10. **[❓ `10_TROUBLESHOOTING_FAQ.md`](./docs/blueprint/10_TROUBLESHOOTING_FAQ.md)**
    - Daftar masalah umum yang sering dihadapi developer saat menggunakan OVHL v1 beserta solusinya (misal: Modul tidak ter-load, Rojo error, Race Condition, dll).
    - _Pertolongan pertama saat mentok._

---

## 🤖 UNTUK AI CO-DEVELOPER

Gunakan 3 file berikut saat memulai sesi kerja:

- **[`AI/AI_CHEAT_SHEET.md`](./docs/ai_context/AI_CHEAT_SHEET.md):** Ringkasan konsep inti & API utama.
- **[`AI/AI_ROADMAP.md`](./docs/ai_context/AI_ROADMAP.md):** Daftar tugas saat ini & berikutnya.
- **[`AI/AI_DEV_LOG.md`](./docs/ai_context/AI_DEV_LOG.md):** Catatan sesi sebelumnya & instruksi.

Jika Anda membutuhkan **detail implementasi** yang tidak ada di `AI_CHEAT_SHEET.md`, **minta user** untuk me-refer atau meng-copy-paste bagian relevan dari file detail (`01` s/d `10`) di atas.

---

<p align="center">
  <small>Hak Cipta © 2025 OVHL Studio. Semua Hak Dilindungi.</small>
</p>
