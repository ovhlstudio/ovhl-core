# 🚀 02 - PANDUAN AWAL & DEV WORKFLOW (V1)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                                       |
| ------------------ | ----------------------------------------------------------- |
| **ID Dokumen**     | `ARC-V1-002`                                                |
| **Status**         | `Aktif (Rilis Baru)`                                        |
| **Lokasi Path**    | `./docs/blueprint/02_DEV_WORKFLOW.md`                       |
| **Tipe Dokumen**   | `Panduan Setup & Alur Kerja Developer`                      |
| **Target Audiens** | `All Developers, AI Assistant, Core Team`                   |
| **Relasi**         | `Index: 00_MASTER_INDEX.md`, `Ref: 01_ARCHITECTURE_CORE.md` |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)`                     |
| **Dibuat**         | `29 Oktober 2025`                                           |

---

## 🛠️ 2.1. SETUP LINGKUNGAN (PERSIAPAN WAJIB)

Bagian ini mencakup semua langkah untuk menyiapkan komputer Anda agar siap mengembangkan dengan OVHL V1.

### 2.1.1. Prasyarat Software

Pastikan semua _software_ berikut sudah terinstal di sistem Anda.

| Software                         | Tujuan                                     | Wajib?           | Referensi |
| :------------------------------- | :----------------------------------------- | :--------------- | :-------- |
| **Roblox Studio**                | Engine utama game.                         | **Ya**           |           |
| **Visual Studio Code (VS Code)** | Editor kode utama kita.                    | **Ya**           |           |
| **Rojo 7.x**                     | Sinkronisasi file dari VS Code ke Studio.  | **Ya**           |           |
| **Git**                          | Version control (wajib untuk tim).         | **Ya**           |           |
| **Wally**                        | Package Manager untuk library Luau.        | **Ya**           | -         |
| **StyLua**                       | Formatter untuk merapikan kode Luau.       | Direkomendasikan | -         |
| **Selene**                       | _Linter_ untuk menjaga kualitas kode Luau. | Direkomendasikan |           |
| **Node.js**                      | Dibutuhkan untuk SDK/CLI Tools (Opsional). | Direkomendasikan | -         |

### 2.1.2. Ekstensi VS Code

Untuk pengalaman _development_ terbaik, instal ekstensi VS Code berikut:

- **`roblox-ts.vscode-rojo`**: Manajemen project Rojo.
- **`Kampfkarren.selene-vscode`**: Menampilkan error _linting_ Selene.
- **`sumneko.lua`** (atau `ms-vscode.lua`): _Syntax highlighting_ dan _autocomplete_ Luau.
- **`JohnnyMorganz.stylua`**: Menjalankan formatter StyLua otomatis saat menyimpan.

### 2.1.3. Quick Start (Instalasi 5 Menit)

1.  **Clone Repository:**
    Gunakan **Git** untuk men-clone _repository_ proyek ke komputer Anda.
    ```bash
    # Ganti URL dengan URL repo Anda
    git clone [https://github.com/ovhlstudio/ovhl-roblox.git](https://github.com/ovhlstudio/ovhl-roblox.git)
    cd ovhl-roblox
    ```
2.  **Instal Dependensi Luau (Wally):**
    Gunakan **Wally** untuk menginstal semua library Luau yang dibutuhkan (seperti Fusion, 't', dll), yang terdaftar di `wally.toml`.
    ```bash
    wally install
    # Ini akan membuat folder 'Packages/' berisi library
    ```
3.  **Jalankan Rojo Serve:**
    Dari _root_ folder proyek, jalankan `rojo serve`. Ini akan membuat "jembatan" antara folder lokal Anda dan Roblox Studio.
    ```bash
    # Perintah ini akan terus berjalan di terminal, jangan ditutup!
    rojo serve default.project.json
    ```
4.  **Buka Roblox Studio & Sinkronisasi:**
    - Buka Roblox Studio dan buka _place_ game Anda (atau buat Baseplate baru).
    - Pastikan _plugin_ **Rojo** sudah terinstal di Studio.
    - Klik tab "Plugins", lalu klik ikon **Rojo** dan **"Connect"**.
    - Otomatis, semua file dari folder `src/` dan `Packages/` akan tersinkronisasi ke Studio.
5.  **Play Test! (F5):**
    - Tekan **Play (F5)** di Roblox Studio.
    - Buka _console_ **Output**.
    - Anda akan melihat log dari sistem **Auto-Discovery** V1, menunjukkan proses loading, validasi, inject, init, dan start.
    - **Selamat!** Setup Anda berhasil. Framework OVHL V1 sudah berjalan.

---

## 🗺️ 2.2. STRUKTUR PROYEK & ROJO

Memahami _mapping_ antara VS Code dan Roblox Studio sangat penting. **Anda HANYA boleh mengedit file di VS Code**.

### 2.2.1. Tampilan di VS Code (Folder `src/`)

Ini adalah **"Source of Truth"** Anda.

```text
src/
├── server/                 # Kode khusus Server
│   ├── services/           # Core Services (Logger, EventBus, dll)
│   ├── modules/            # Fitur Game Server (Shop, Quest, AdminPanel)
│   └── init.server.lua     # Bootstrap Server
│
├── client/                 # Kode khusus Client
│   ├── controllers/        # Core Controllers (StateManager, RemoteClient)
│   ├── modules/            # Fitur UI Client (HUD, InventoryUI, Login)
│   └── init.client.lua     # Bootstrap Client
│
└── shared/                 # Kode Server & Client
    ├── components/         # [V1] Logic untuk Coder/Builder (LavaPart.lua, dll)
    ├── constants/          # Settingan game (Senjata, XP, dll)
    ├── lib/                # [V1] Libraries dari Wally (Fusion, 't', dll) - JANGAN EDIT
    ├── utils/              # Fungsi helper (Validation, Math, dll)
    ├── NetworkSchema.lua   # [V1] Kontrak validasi RemoteManager
    └── OVHL_Global.lua     # API 'OVHL' utama
```

### 2.2.2. Tampilan di Roblox Studio (Hasil Sinkronisasi Rojo)

Ini adalah **hasil akhir** di Studio. **JANGAN PERNAH** mengedit _script_ di sini, karena akan tertimpa oleh Rojo.

```text
DataModel
├── ServerScriptService
│   └── OVHL_Server/      <-- (Folder 'src/server')
│       ├── services/
│       ├── modules/
│       └── init.server.lua
│   └── OVHL_Tests/       <-- (Folder 'tests')
│
├── ReplicatedStorage
│   └── OVHL_Shared/      <-- (Folder 'src/shared')
│       ├── components/
│       ├── constants/
│       ├── lib/
│       ├── utils/
│       ├── NetworkSchema.lua
│       └── OVHL_Global.lua
│   └── Packages/         <-- (Folder 'Packages/' dari Wally)
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── OVHL_Client/  <-- (Folder 'src/client')
            ├── controllers/
            ├── modules/
            └── init.client.lua
```

### 2.2.3. Konfigurasi Rojo (`default.project.json`)

File ini adalah "cetakan" yang mengatur _mapping_ di atas.

```json
{
  "name": "ovhl-V1-game",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "OVHL_Shared": {
        "$path": "src/shared"
      },
      "Packages": {
        "$path": "Packages" // Map folder Wally
      }
    },
    "ServerScriptService": {
      "OVHL_Server": {
        "$path": "src/server"
      },
      "OVHL_Tests": {
        // Map folder tests
        "$path": "tests"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "OVHL_Client": {
          "$path": "src/client"
        }
      }
    }
  }
}
```

---

## 🔥 2.3. ALUR KERJA DEVELOPMENT (V1)

Ini adalah siklus kerja harian Anda menggunakan OVHL V1.

### 2.3.1. Alur Kerja Harian (Daily Workflow)

1.  **Jalankan `rojo serve`**: Buka terminal, `cd` ke folder proyek, ketik `rojo serve default.project.json`. Biarkan berjalan.
2.  **Koneksi Studio**: Buka Studio, buka _plugin_ Rojo, klik "Connect".
3.  **Buat/Edit File Modul**: Di **VS Code** (di dalam folder `src/`). Ikuti standar di `03_CODING_STANDARDS_DI.md`.
4.  **Simpan File (Ctrl+S)**: Rojo otomatis menyinkronkan ke Studio.
5.  **Cek Live Update (Hot Reloading V1)**:
    - **Untuk KODE UI & KOMPONEN (Client & Shared):** Jika _Hot Reloading Service_ (akan dibuat) aktif, perubahan akan langsung terlihat di game yang sedang berjalan tanpa perlu _restart_. State UI biasanya akan di-reset, kecuali diimplementasikan _state preservation_.
    - **Untuk KODE SERVER (`services`, `modules`):** Fitur baru atau perubahan logika akan aktif saat **Play Test berikutnya** (F5). _Hot reloading_ di sisi server lebih kompleks dan berisiko, jadi kita fokus pada _hot reloading_ client dulu.
6.  **Gunakan Linter/Formatter**: Jalankan `selene .` dan `stylua .` secara berkala (atau otomatis via ekstensi VS Code) untuk menjaga kualitas kode.
7.  **Play Test (F5)**: Tekan "Play" di Studio untuk mengetes logika baru di sisi server dan client secara keseluruhan.
8.  **Cek Output & Debug**: Lihat _console_ Output untuk log atau error. Gunakan _debugger_ Studio jika perlu.
9.  **Commit & Push**: Setelah fitur selesai dan dites, gunakan Git untuk menyimpan perubahan dengan _commit message_ yang jelas.

### 2.3.2. Git Workflow (Standar Tim)

Ikuti standar _Conventional Commits_ untuk histori yang jelas dan otomatisasi (misal: generate changelog).

- **Branching Pattern:**
  - `main`: Kode produksi yang stabil. **Hanya di-merge dari `develop` saat rilis.**
  - `develop`: Cabang pengembangan utama. **Semua `feature` dan `fix` di-merge ke sini.**
  - `feature/<deskripsi-singkat>`: Fitur baru (misal: `feature/inventory-system`). Dibuat dari `develop`.
  - `fix/<deskripsi-singkat>`: Perbaikan bug (misal: `fix/shop-purchase-error`). Dibuat dari `develop`.
  - `docs/<deskripsi-singkat>`: Perubahan dokumentasi (misal: `docs/update-networking-V1`). Dibuat dari `develop`.
- **Commit Message Format:** `type(scope): description`
  - **`type`**: `feat` (fitur baru), `fix` (bug fix), `docs` (dokumentasi), `style` (formatting, no logic change), `refactor` (perubahan kode tanpa mengubah behavior), `perf` (peningkatan performa), `test` (menambah/memperbaiki tes), `build` (perubahan sistem build/Rojo/Wally), `ci` (perubahan CI/CD), `chore` (tugas maintenance lain).
  - **`scope`** (opsional): Area kode yang terdampak (misal: `ui`, `network`, `shop`, `component(LavaPart)`).
  - **Contoh:**
    - `feat(network): implementasikan rate limiting di RemoteManager V1`
    - `fix(ui): perbaiki alignment text di CoinDisplay component`
    - `docs(workflow): tambahkan detail hot reloading V1`
    - `refactor(ShopModule): pindahkan logika validasi ke function terpisah`
    - `test(LevelSystem): tambahkan unit test untuk SavePlayerData`
    - `chore: update library Fusion ke versi terbaru`

---

## 🤖 2.4. CLI TOOLS & SDK (V1)

Untuk mempercepat _development_, kita menggunakan _tools_ CLI berbasis Node.js yang ada di folder `sdk/`. _Tools_ ini membantu men-generate _boilerplate_ (kode template) secara otomatis sesuai standar V1.

- **Filosofi:** "Tools that think with you" - Otomatisasi untuk mempercepat development, mengurangi _human error_, dan menjaga konsistensi.
- **Lokasi:** Folder `sdk/` (dijalankan via `npm run <script>` atau `pnpm`/`yarn`).

### Contoh Perintah Generator (Scaffolding)

- **Membuat Service Server Baru:**

  ```bash
  npm run create:service ShopService --deps=Logger,DataService,EconomyService
  # atau mode interaktif:
  # npm run create:service
  ```

  - **Hasil:** Membuat `src/server/modules/ShopService.lua` lengkap dengan `__manifest`, `dependencies`, dan fungsi `:Inject()`, `:Init()`, `:Start()` sesuai template standar V1.

- **Membuat Komponen Coder/Builder Baru:**

  ```bash
  npm run create:component SpinningCoin
  # atau mode interaktif:
  # npm run create:component
  ```

  - **Hasil:** Membuat `src/shared/components/SpinningCoin.lua` lengkap dengan `__manifest (type="component")`, `:Knit()`, dan `:Destroy()`.

- **Membuat Modul UI Baru (Hooks):**
  ```bash
  npm run create:ui MainMenuScreen
  # atau mode interaktif:
  # npm run create:ui
  ```
  - **Hasil:** Membuat `src/client/modules/MainMenuScreen.lua` lengkap dengan `__manifest (type="module")` dan template standar UI Hooks V1 menggunakan Fusion.

### Fitur Visi V1 (dari Konsep TS)

- **Mode Interaktif (TUI):** Jika argumen tidak lengkap, _tool_ akan bertanya (pakai `inquirer`).
- **Kategorisasi & Penempatan Otomatis:** _Tool_ otomatis menempatkan file di folder yang benar (`services/`, `components/`, `client/modules/`) berdasarkan tipe yang dibuat.
- **Update Dependensi (Advanced):** Di masa depan, `create:service` bisa otomatis menambahkan _service_ baru ini ke `dependencies` modul lain yang mungkin membutuhkannya (berdasarkan analisa kode atau input user).
- **Progress Bar:** Menampilkan visual yang jelas saat men-generate banyak file.

---

## ✨ 2.5. TUTORIAL MODUL PERTAMA (Hello World V1)

Tutorial ini menggunakan **Pola Dependency Injection V1** yang baru.

1.  **Buat File Modul (via CLI atau Manual):**

    - **Via CLI:**
      ```bash
      npm run create:service WelcomeMessage --deps=Logger
      ```
    - **Manual:** Buat file `src/server/modules/WelcomeMessage.lua`.

2.  **Tulis/Edit Kode Modul:**
    _Jika pakai CLI, sebagian besar kode ini sudah ada._

    ```lua
    -- File: src/server/modules/WelcomeMessage.lua

    -- 1. Ambil OVHL Global Accessor (jika perlu Emit/Subscribe)
    local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

    -- 2. Definisikan tabel modul
    local WelcomeMessage = {}
    WelcomeMessage.__index = WelcomeMessage

    -- 3. WAJIB: Buat __manifest
    WelcomeMessage.__manifest = {
        name = "WelcomeMessage", -- Harus sama dengan nama file
        version = "1.0.0",
        type = "module",        -- Tipe 'module' untuk fitur game
        dependencies = {"Logger"} -- Butuh Logger
    }

    -- Properti internal
    WelcomeMessage.logger = nil

    -- 4. [V1 BARU] :Inject (Dipanggil oleh framework)
    function WelcomeMessage:Inject(services)
        self.logger = services.Logger -- Simpan Logger yang di-inject
    end

    -- 5. :Init (Opsional, bisa kosong jika tidak perlu)
    function WelcomeMessage:Init()
        return true -- Wajib return true/false
    end

    -- 6. Implementasikan fungsi Start
    function WelcomeMessage:Start()
        -- Gunakan Logger via self (sudah di-inject)
        local logger = self.logger

        -- Dengar event 'PlayerJoined' via OVHL
        OVHL:Subscribe("PlayerJoined", function(player)
            -- Bungkus pcall untuk standar No Crash
            local success, err = pcall(function()
                 logger:Info("Selamat datang, " .. player.Name .. "!")
            end)
            if not success then logger:Error("Error di WelcomeMessage PlayerJoined handler", {error=err}) end
        end)

        logger:Info("WelcomeMessage module loaded!")
    end

    -- 7. Kembalikan tabel modul
    return WelcomeMessage
    ```

3.  **Simpan & Test:**
    - **Simpan** file `WelcomeMessage.lua` (Ctrl+S). Rojo akan menyinkronkannya.
    - Tekan **Play (F5)** di Studio.
    - Cek _console_ **Output**. Anda akan melihat log `WelcomeMessage module loaded!` dan `Selamat datang, [NamaPemain]!`.

---

## 🐛 2.6. TROUBLESHOOTING (MASALAH UMUM)

- **Q: Modul / Service saya tidak ter-load! Tidak ada di log Auto-Discovery!**
  **A:** 99% masalah ada di `__manifest`. Pastikan:

  1.  _Property_ `__manifest` ada.
  2.  `name` (string) **sama persis** dengan nama file (Case-Sensitive).
  3.  `type` (string) diisi dengan benar: `service`, `controller`, `module`, atau `component`.
  4.  Cek `dependencies = {...}`. Jika Anda _typo_ (salah ketik) nama dependensi, `DependencyResolver` akan **FAIL FAST** saat startup. Cek log Output Studio paling atas untuk pesan error `Missing dependency`.
  5.  Pastikan file ada di folder yang benar (`src/server/services`, `src/server/modules`, dll).

- **Q: Saya dapat error "HttpError: Unauthenticated" atau "Connect failed" dari Rojo.**
  **A:** Pastikan `rojo serve default.project.json` **sedang berjalan** di terminal VS Code Anda. Jika sudah, coba _restart_ `rojo serve` dan Roblox Studio. Pastikan juga tidak ada _firewall_ yang memblok koneksi port Rojo (biasanya 34872).

- **Q: Saya mengedit _script_ di Studio, tapi hilang saat Play Test!**
  **A:** **JANGAN PERNAH** mengedit _script_ di dalam folder yang dikelola Rojo (`OVHL_Server`, `OVHL_Client`, `OVHL_Shared`, `Packages`). VS Code adalah _Source of Truth_. Perubahan Anda di Studio akan selalu ditimpa oleh Rojo.

- **Q: Hot Reloading UI tidak bekerja!**
  **A:** Pastikan:
  1.  `HotReloadService` (akan dibuat) sudah ada dan aktif.
  2.  Modul UI Anda mengikuti pola Hooks V1 dengan benar.
  3.  Tidak ada error syntax di kode UI Anda (cek Output).
  4.  Rojo `serve` masih berjalan dan terkoneksi.

---

### 🔄 Riwayat Perubahan (Changelog)

| Versi | Tanggal     | Penulis                 | Perubahan                                                                                                                                                                                      |
| :---- | :---------- | :---------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0 | 29 Okt 2025 | OVHL Core Team & Gemini | Rilis awal file detail Dev Workflow V1. Menggabungkan `1.2_PANDUAN_AWAL.md` dan `2.1_MODULE_STANDART.md` (Git), serta menambahkan konsep V1 (Hot Reload, CLI Tools V1, Wally, Tutorial DI V1). |
