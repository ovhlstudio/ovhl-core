# 🗺️ AI ROADMAP - OVHL CORE v1 (Lengkap Menuju Deploy)

Dokumen ini berisi daftar **tugas pengembangan** yang terstruktur per fase untuk membangun OVHL Core v1 dari nol hingga siap deploy. Gunakan ini sebagai panduan utama sesi kerja AI Co-Developer.

**Update Terakhir:** 29 Oktober 2025

---

## 📖 Cara Menggunakan Roadmap Ini

- **Fokus per Fase:** Selesaikan task di Fase 1 sebelum lanjut ke Fase 2, dst. kecuali task bisa diparalelkan.
- **Update Status:** Saat memulai/menyelesaikan task, update kolom `Status`.
- **Cek Success Criteria:** Pastikan semua kriteria terpenuhi sebelum menandai task `Done`.
- **Gunakan Referensi:** Buka file blueprint yang dirujuk jika butuh detail implementasi.
- **Wajib Logging:** **SETIAP AKHIR SESI KERJA DENGAN AI**, Developer **WAJIB** mengisi `AI_DEV_LOG.md` dengan detail:
  - Task ID yang dikerjakan.
  - Progres spesifik (file apa dibuat/diubah, fungsi apa selesai).
  - Hasil (Sukses? Error? Stuck?).
  - **Jika Error/Stuck:** Jelaskan errornya, apa yang sudah dicoba AI/Developer, dan **perintahkan AI berikutnya** untuk mencoba solusi spesifik atau memperbaiki.
  - **Jika Sukses:** Perintahkan AI berikutnya untuk lanjut ke sub-task berikutnya atau task baru.

---

## 🏗️ FASE 1: Fondasi Inti (Core Systems Minimal)

**Tujuan:** Membangun kerangka dasar agar modul bisa di-load, berkomunikasi internal, dan melakukan logging.

| Task ID  | Nama Task                         | Deskripsi Singkat                                                                  | Status  | Prioritas | Success Criteria                                                                                 | Referensi Blueprint     | Catatan/Blocker                         |
| :------- | :-------------------------------- | :--------------------------------------------------------------------------------- | :------ | :-------- | :----------------------------------------------------------------------------------------------- | :---------------------- | :-------------------------------------- |
| OVHL-001 | Implementasi `LoggerService`      | Membuat `LoggerService.lua` (Info, Warn, Error), baca flag debug global.           | `To Do` | Kritis    | Output log sesuai format; Menghormati flag `Core.DebugEnabled`.                                  | `03`, `07`              | -                                       |
| OVHL-004 | Implementasi `ConfigService`      | Membuat `ConfigService.lua` (baca `__config`, dasar `GetConfig`, flag debug).      | `To Do` | Kritis    | `OVHL:GetConfig` mengembalikan `__config`; `Core.DebugEnabled` bisa dibaca.                      | `01`, `03`, `07`        | Perlu `LoggerService` (OVHL-001).       |
| OVHL-005 | Implementasi `DependencyResolver` | Membuat utilitas untuk membaca `dependencies` & `priority`, hasilkan load order.   | `To Do` | Kritis    | Bisa menghasilkan urutan load yang benar untuk 5+ modul tes; Deteksi circular dep.               | `01`, `03`              | Perlu `LoggerService` (OVHL-001).       |
| OVHL-006 | Implementasi `ServiceManager`     | Membuat `ServiceManager.lua` (Auto-discover `services/`, panggil lifecycle DI v1). | `To Do` | Kritis    | Services di `services/` ter-load sesuai urutan; Lifecycle `:Inject`,`:Init`,`:Start` terpanggil. | `01`, `03`, `07`        | Perlu Logger, Config, DepResolver.      |
| OVHL-007 | Implementasi `ModuleLoader`       | Membuat `ModuleLoader.lua` (Auto-discover `modules/`, panggil lifecycle DI v1).    | `To Do` | Kritis    | Modules di `modules/` ter-load sesuai urutan; Lifecycle terpanggil.                              | `01`, `03`, `07`        | Perlu Logger, Config, DepResolver.      |
| OVHL-003 | Implementasi `EventBusService`    | Membuat `EventBusService.lua` (`Emit`, `Subscribe` internal server).               | `To Do` | Tinggi    | Event bisa dikirim & diterima antar service/module; `pcall` wrap di callback.                    | `01`, `07`              | Perlu `LoggerService` (OVHL-001).       |
| OVHL-008 | Implementasi `OVHL_Global`        | Membuat `OVHL_Global.lua` dengan shortcut API dasar (`GetConfig`, `Emit`, `Sub`).  | `To Do` | Tinggi    | API dasar berfungsi di server.                                                                   | `01`, `07`              | Perlu ServiceManager, EventBus, Config. |
| OVHL-009 | Setup Basic Test Runner (TestEZ)  | Konfigurasi TestEZ dan buat 1 tes unit dasar untuk `LoggerService`.                | `To Do` | Sedang    | Tes `LoggerService` bisa dijalankan dan pass.                                                    | `02` (SDK), TestEZ Docs | -                                       |

---

## ✨ FASE 2: Fitur Inti & Workflow Developer

**Tujuan:** Mengimplementasikan fitur utama (UI Hooks, Coder/Builder, Networking v1 Dasar) dan meningkatkan alur kerja developer.

| Task ID  | Nama Task                               | Deskripsi Singkat                                                                                 | Status  | Prioritas | Success Criteria                                                                                           | Referensi Blueprint | Catatan/Blocker                     |
| :------- | :-------------------------------------- | :------------------------------------------------------------------------------------------------ | :------ | :-------- | :--------------------------------------------------------------------------------------------------------- | :------------------ | :---------------------------------- |
| OVHL-010 | Integrasi Fusion & Setup Hooks          | Instal Fusion via Wally. Buat `ThemeController` dasar & `useTheme` hook.                          | `To Do` | Tinggi    | Wally instal Fusion; `useTheme()` mengembalikan state tema; Komponen UI dasar bisa render pakai `New`.     | `04`                | Wally harus terinstal.              |
| OVHL-011 | Implementasi `StateManager`             | Membuat `StateManager.lua` (Client Controller) untuk global UI state (`Get/Set/Sub`).             | `To Do` | Tinggi    | `OVHL:SetState`, `GetState`, `Subscribe` (client) berfungsi; UI Hooks bisa pakai global state.             | `01`, `04`, `07`    | Perlu `ClientController` bootstrap. |
| OVHL-012 | Implementasi `UIEngine`                 | Membuat `UIEngine.lua` (Client Controller) untuk me-mount/unmount komponen UI Hooks.              | `To Do` | Tinggi    | Bisa mount komponen dari `modules/` client; Lifecycle `Cleanup` Fusion terpanggil.                         | `04`, `07`          | Perlu Fusion (OVHL-010).            |
| OVHL-013 | Implementasi `ComponentService`         | Membuat `ComponentService.lua` (Server & Client) untuk Coder/Builder workflow (`Knit`/`Destroy`). | `To Do` | Tinggi    | Komponen di `shared/components/` ter-load; `:Knit` terpanggil saat instance di-tag; `:Destroy` terpanggil. | `05`, `07`          | Perlu Auto-Discovery stabil.        |
| OVHL-014 | Implementasi `RemoteManager` v1 (Dasar) | Membuat `RemoteManagerService.lua` & `RemoteClient.lua`, API `RegisterHandler`, `Invoke`, `Fire`. | `To Do` | Kritis    | Client bisa `Invoke`/`Fire` ke server; Server bisa panggil handler terdaftar.                              | `01`, `06`, `07`    | Perlu DI & Auto-Discovery.          |
| OVHL-015 | Implementasi Schema Validation (`t`)    | Integrasikan library `t`. Buat `NetworkSchema.lua`. `RemoteManager` otomatis validasi.            | `To Do` | Kritis    | Remote call gagal jika argumen tidak cocok `NetworkSchema.lua`.                                            | `06`                | Perlu `RemoteManager` (OVHL-014).   |
| OVHL-016 | Implementasi Rate Limiting              | Tambahkan middleware Rate Limiting otomatis ke `RemoteManager` v1.                                | `To Do` | Tinggi    | Spam `Invoke`/`Fire` dari client ditolak server.                                                           | `06`                | Perlu `RemoteManager` (OVHL-014).   |
| OVHL-017 | Setup Basic CLI Generator (SDK)         | Buat script `npm run create:service` dasar di folder `sdk/`.                                      | `To Do` | Sedang    | CLI bisa generate file `Service.lua` baru dengan `__manifest` kosong.                                      | `02`, `09`          | Perlu Node.js setup.                |
| OVHL-018 | Implementasi Basic Hot Reloading (UI)   | Buat service/mekanisme dasar untuk reload UI Hooks saat file `.lua` client berubah.               | `To Do` | Sedang    | Perubahan pada file UI di VS Code terlihat di Studio tanpa restart Play.                                   | `02`, `04`          | Perlu `UIEngine` (OVHL-012).        |

---

## 💎 FASE 3: Polish, Ekosistem & Kesiapan Deploy

**Tujuan:** Memoles fitur, menambah robustness, menyiapkan fondasi ekosistem, dan memastikan framework siap produksi.

| Task ID  | Nama Task                                    | Deskripsi Singkat                                                                           | Status    | Prioritas | Success Criteria                                                                                   | Referensi Blueprint | Catatan/Blocker                     |
| :------- | :------------------------------------------- | :------------------------------------------------------------------------------------------ | :-------- | :-------- | :------------------------------------------------------------------------------------------------- | :------------------ | :---------------------------------- |
| OVHL-020 | Implementasi Network Batching                | Tambahkan middleware batching otomatis untuk `OVHL:Fire` di `RemoteClient`.                 | `Backlog` | Sedang    | Banyak `Fire` dalam 1 frame dikirim sebagai 1 paket network (cek via NetworkMonitor).              | `06`                | Perlu `RemoteManager` v1 stabil.    |
| OVHL-021 | Implementasi Network Caching                 | Tambahkan support `__cache` di `RemoteManager` v1 untuk `Invoke`.                           | `Backlog` | Sedang    | `Invoke` dengan `__cache` mengembalikan hasil dari cache jika valid.                               | `06`                | Perlu `RemoteManager` v1 stabil.    |
| OVHL-022 | Implementasi `NetworkMonitorService`         | Buat `NetworkMonitorService.lua` yang dicatat oleh `RemoteManager` v1.                      | `Backlog` | Sedang    | Service mencatat data latency, status, caller untuk setiap remote call.                            | `06`                | Perlu `RemoteManager` v1 stabil.    |
| OVHL-023 | Implementasi `DataService` (Real)            | Ganti mock `DataService` dengan implementasi DataStore Roblox (atau DataStore2/ProfileSvc). | `Backlog` | Tinggi    | Data player bisa disimpan & dimuat persisten. Handle `pcall`, retry, session locking.              | `03`, `08`          | Perlu DI & `LoggerService`.         |
| OVHL-024 | Implementasi `ConfigService` (Live)          | Integrasikan `ConfigService` dengan `DataService` untuk live config update. Emit event.     | `Backlog` | Sedang    | `OVHL:GetConfig` mengembalikan live config; `ConfigUpdated:Modul` ter-emit saat `Set`.             | `01`, `09`          | Perlu `DataService` (OVHL-023).     |
| OVHL-025 | Buat Admin Panel Dasar                       | Buat UI Admin Panel dasar (Hooks v1) untuk melihat log & mengubah config live.              | `Backlog` | Sedang    | Admin bisa lihat log `NetworkMonitor` & `Logger`; Bisa ubah `Core.DebugEnabled` secara live.       | `09`                | Perlu UI, Config Live, Net Monitor. |
| OVHL-026 | Tingkatkan CLI Generators (SDK)              | Tambahkan fitur interaktif (TUI), template lebih canggih, update dependensi otomatis.       | `Backlog` | Rendah    | `create:service` bisa tanya deps & update manifest lain; `create:ui` & `create:component` lengkap. | `02`, `09`          | Perlu CLI dasar (OVHL-017).         |
| OVHL-027 | Implementasi State Preservation (Hot Reload) | Tambahkan mekanisme simpan/restore state dasar saat Hot Reloading UI.                       | `Backlog` | Rendah    | State UI Hooks tidak selalu reset total saat file berubah.                                         | `02`, `04`          | Perlu Hot Reload dasar (OVHL-018).  |
| OVHL-028 | Tulis Unit Tests Komprehensif                | Tambahkan unit test (TestEZ) untuk semua Core Services & Controllers.                       | `Backlog` | Sedang    | Coverage > 80% untuk core systems.                                                                 | `02`, TestEZ Docs   | Perlu Test Runner (OVHL-009).       |
| OVHL-029 | Buat Dokumentasi Detail Lengkap              | Finalisasi semua file blueprint `00` - `10` dengan detail implementasi & contoh.            | `Backlog` | Tinggi    | Semua blueprint lengkap, akurat, dan siap dibaca developer.                                        | Semua               | Selesaikan implementasi dulu.       |
| OVHL-030 | Performance Benchmarking & Optimasi          | Lakukan profiling & optimasi pada critical path (startup, remotes, UI render).              | `Backlog` | Sedang    | Startup time < target; Remote latency < target; FPS UI stabil.                                     | `01` (Perf Targets) | Perlu fitur inti selesai.           |

---

## ✅ Selesai (Completed Tasks)

| Task ID  | Nama Task       | Tanggal Selesai | Catatan Hasil                                   |
| :------- | :-------------- | :-------------- | :---------------------------------------------- |
| OVHL-000 | Setup Proyek v1 | 29 Okt 2025     | Struktur folder, file config, Rojo, Wally siap. |
| ...      | ...             | ...             | ...                                             |

---

**Legenda Status:**

- `To Do`: Siap dikerjakan.
- `In Progress`: Sedang dikerjakan.
- `Review`: Menunggu review/testing.
- `Done`: Selesai.
- `Blocked`: Terhalang task lain / masalah eksternal.
- `Backlog`: Ide / task untuk masa depan.

**Legenda Prioritas:**

- `Kritis`: Harus segera.
- `Tinggi`: Penting.
- `Sedang`: Normal.
- `Rendah`: Bisa ditunda.
