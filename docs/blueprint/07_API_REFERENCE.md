# 📚 07 - REFERENSI API LENGKAP (v1)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                   |
| ------------------ | --------------------------------------- |
| **ID Dokumen**     | `ARC-v1-007`                            |
| **Status**         | `Aktif (Rilis Baru)`                    |
| **Lokasi Path**    | `./docs/blueprint/07_API_REFERENCE.md`  |
| **Tipe Dokumen**   | `Referensi API Publik`                  |
| **Target Audiens** | `All Developers, AI Assistant`          |
| **Relasi**         | `Index: 00_MASTER_BLUEPRINT_v1.md`      |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)` |
| **Dibuat**         | `29 Oktober 2025`                       |

---

## 🔑 7.1. API UTAMA: `OVHL` Global Accessor

Ini adalah API utama yang diakses melalui modul `OVHL_Global.lua`. Modul ini harus di-_require_ di awal setiap file yang membutuhkannya.

```lua
local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)
```

### 7.1.1. Server & Client (Shared)

API ini tersedia di Server dan Client, namun merujuk ke _service_/_controller_ yang berbeda di _background_.

- **`OVHL:GetService(name: string) -> table | nil`**

  - **Server:** Mengambil _instance_ _service_ yang sudah terdaftar (Shortcut ke `ServiceManager:GetService`).
  - **Client:** Mengambil _instance_ _controller_ yang sudah terdaftar (Shortcut ke `ClientController:GetController`).
  - **⚠️ v1 NOTE:** **HINDARI PENGGUNAAN INI.** Utamakan **Dependency Injection** (via `:Inject()`) untuk mendapatkan dependensi antar modul/service. Gunakan `GetService` hanya jika akses dinamis benar-benar diperlukan (misal: di _tools_ debug atau kasus langka lainnya).
  - **Return:** _Instance_ modul/service jika ditemukan, `nil` jika tidak.

- **`OVHL:GetConfig(moduleName: string) -> table | nil`**
  - **Server:** Mengambil tabel konfigurasi untuk `moduleName`. Mengembalikan _live config_ dari `DataService` jika ada, atau _default config_ dari `__config` jika tidak ada (Shortcut ke `ConfigService:Get`).
  - **Client:** **TIDAK TERSEDIA.** Client harus meminta konfigurasi dari server melalui `OVHL:Invoke` jika diperlukan.
  - **Return:** Tabel konfigurasi jika ditemukan, `nil` jika modul tidak punya config.

### 7.1.2. Server-Side (Internal Communication)

API ini **hanya** berjalan di Server dan digunakan untuk komunikasi _internal_ yang aman antar _service_ dan _module_.

- **`OVHL:Emit(eventName: string, ...) -> number`**

  - Menerbitkan (publish) _event_ internal ke `EventBus`. Semua _listener_ yang terdaftar untuk `eventName` akan dipanggil secara sinkron.
  - **Argumen:** `eventName` (string, PascalCase direkomendasikan), diikuti oleh argumen data (opsional, tipe apa saja).
  - **Return:** Jumlah _listener_ yang berhasil dipanggil.
  - **Contoh:** `OVHL:Emit("PlayerKilled", killerPlayer, victimPlayer, weaponUsed)`

- **`OVHL:Subscribe(eventName: string, callback: function) -> function`**
  - Mendaftar (subscribe) untuk mendengarkan _event_ internal dari `EventBus`.
  - **Argumen:** `eventName` (string), `callback` (fungsi yang akan dipanggil saat _event_ terjadi. Argumen _callback_ akan sesuai dengan yang dikirim oleh `Emit`).
  - **Return:** Fungsi `unsubscribe`. Panggil fungsi ini (tanpa argumen) untuk berhenti mendengarkan _event_ (penting untuk _cleanup_!).
  - **⚠️ PENTING:** Logika di dalam `callback` **WAJIB** dibungkus `pcall` untuk menjaga stabilitas ("No Crash").
  - **Contoh:**
    ```lua
    local function onPlayerKilled(killer, victim, weapon)
        local success, err = pcall(function()
            -- Logika Anda di sini...
            self.logger:Info(killer.Name .. " mengalahkan " .. victim.Name)
        end)
        if not success then self.logger:Error("Error di handler PlayerKilled", {error=err}) end
    end
    self.unsubscribeKilled = OVHL:Subscribe("PlayerKilled", onPlayerKilled)
    -- ... saat cleanup: self.unsubscribeKilled()
    ```

### 7.1.3. Client-Side (UI State & Networking)

API ini **hanya** berjalan di Client.

- **`OVHL:SetState(key: string, value: any) -> boolean`**

  - Mengatur nilai _state_ global di `StateManager`.
  - Akan memicu _update_ pada semua komponen UI Hooks yang berlangganan `key` ini.
  - **Argumen:** `key` (string, unik), `value` (nilai baru, tipe apa saja).
  - **Return:** `true` jika berhasil diatur.
  - **Contoh:** `OVHL:SetState("PlayerCoins", 500)`

- **`OVHL:GetState(key: string, defaultValue: any) -> any`**

  - Mengambil nilai _state_ global saat ini dari `StateManager`.
  - **Argumen:** `key` (string), `defaultValue` (nilai yang dikembalikan jika `key` belum pernah di-`SetState`).
  - **Return:** Nilai _state_ saat ini atau `defaultValue`.
  - **Contoh:** `local currentCoins = OVHL:GetState("PlayerCoins", 0)`

- **`OVHL:Subscribe(key: string, callback: function) -> function`**

  - Berlangganan perubahan pada _state_ global tertentu di `StateManager`.
  - Dipakai secara internal oleh UI Hooks v1 (`Value`, `Computed`, `useTheme`). Jarang dipanggil manual kecuali untuk _logic_ non-UI.
  - **Argumen:** `key` (string), `callback` (fungsi yang dipanggil dengan nilai baru saat _state_ berubah).
  - **Return:** Fungsi `unsubscribe`.
  - **Contoh:** `local unsub = OVHL:Subscribe("PlayerCoins", function(newCoins) print("Koin berubah:", newCoins) end)`

- **`OVHL:Fire(remoteName: string, ...) -> boolean`**

  - Mengirim _event_ ke server melalui `RemoteManager` v1. **Tidak menunggu balasan.**
  - **Fitur v1:** Panggilan ini otomatis di-_batch_ jika terjadi berdekatan untuk efisiensi jaringan. Argumen **otomatis divalidasi** oleh server menggunakan `NetworkSchema.lua`. Panggilan dibatasi oleh _rate limit_.
  - **Argumen:** `remoteName` (string, harus terdaftar di `NetworkSchema.lua`), diikuti argumen data (harus cocok dengan _schema_).
  - **Return:** `true` jika _event_ berhasil masuk antrian kirim (bukan berarti sudah sampai server).
  - **Contoh:** `OVHL:Fire("Player:Shoot", targetPosition)`

- **`OVHL:Invoke(remoteName: string, ...) -> any`**

  - Memanggil fungsi di server melalui `RemoteManager` v1 dan **menunggu balasan**.
  - **Fitur v1:** Argumen **otomatis divalidasi** oleh server menggunakan `NetworkSchema.lua`. Panggilan dibatasi oleh _rate limit_. Hasil bisa diambil dari _cache_ server jika diaktifkan.
  - **Argumen:** `remoteName` (string, harus terdaftar di `NetworkSchema.lua`), diikuti argumen data (harus cocok dengan _schema_).
  - **Return:** Nilai yang dikembalikan oleh _handler_ di server. Bisa berupa tabel `{success=true, data=...}` atau `{success=false, error=...}` sesuai desain Anda, atau bisa juga `nil` jika terjadi _error network_ atau _timeout_.
  - **⚠️ PENTING:** Selalu bungkus `OVHL:Invoke` dalam `pcall` di sisi client untuk menangani kemungkinan _error network_ atau _error_ dari server.
  - **Contoh:**
    ```lua
    local success, result = pcall(OVHL.Invoke, OVHL, "Shop:BuyItem", "Sword", 1)
    if success then
        if result and result.success then
            print("Beli berhasil! Koin sisa:", result.data.newCoins)
        else
            warn("Beli gagal:", result and result.error or "Unknown error")
        end
    else
        warn("Network error saat beli:", result) -- result berisi pesan error pcall
    end
    ```

- **`OVHL:Listen(remoteName: string, callback: function) -> RBXScriptConnection`**
  - Mendengarkan _event_ yang dikirim dari server (via `RemoteManager:FireClient` atau `FireAllClients`).
  - **Argumen:** `remoteName` (string), `callback` (fungsi yang akan dipanggil saat _event_ diterima. Argumen _callback_ akan sesuai dengan yang dikirim server).
  - **Return:** Koneksi `RBXScriptConnection`. Panggil `:Disconnect()` pada koneksi ini saat _cleanup_ untuk berhenti mendengarkan.
  - **Validasi v1:** Sebaiknya validasi tipe data yang diterima di dalam _callback_ menggunakan `t.check()` dan _schema_ dari `NetworkSchema.lua` (jika ada) untuk keamanan ekstra di sisi client.
  - **Contoh:**
    ```lua
    local connection = OVHL:Listen("Client:ReceiveNotification", function(message, type)
        -- Validasi opsional di client
        local schema = require(game.ReplicatedStorage.OVHL_Shared.NetworkSchema)["Client:ReceiveNotification"]
        if schema and t.check({message, type}, schema) then
            ShowNotification(message, type or "Info")
        else
            warn("ReceiveNotification: Data tidak valid dari server.")
        end
    end)
    -- Saat cleanup: connection:Disconnect()
    ```

---

## 🧩 7.2. API AUTO-DISCOVERY (Metadata)

Ini adalah properti tabel yang **WAJIB** atau **OPSIONAL** ada di file modul (`.lua`) agar dikenali oleh sistem _Auto-Discovery_.

### `__manifest` (Wajib untuk Semua Modul)

| Key            | Tipe      | Wajib? | Deskripsi                                                                                                                     |
| :------------- | :-------- | :----- | :---------------------------------------------------------------------------------------------------------------------------- |
| `name`         | `string`  | **Ya** | Nama unik (Sama dengan nama file). ID utama modul.                                                                            |
| `version`      | `string`  | **Ya** | Versi SemVer (misal: "1.0.0").                                                                                                |
| `type`         | `string`  | **Ya** | `service` (Server Core), `controller` (Client Core), `module` (Fitur Game Svr/Cli), `component` (Shared Logic Coder/Builder). |
| `dependencies` | `table`   | Tidak  | Daftar `name` (string) dari _service_/_module_/_controller_ lain yang dibutuhkan. **Kunci untuk DI v1**.                      |
| `priority`     | `number`  | Tidak  | Urutan load relatif (0-100, 100 first). Default: 50.                                                                          |
| `domain`       | `string`  | Tidak  | Kategori (misal: `ui`, `gameplay`, `data`).                                                                                   |
| `description`  | `string`  | Tidak  | Penjelasan singkat (untuk developer & AI).                                                                                    |
| `autoload`     | `boolean` | Tidak  | Load otomatis saat startup? (Default: `true`).                                                                                |

### `__config` (Opsional untuk `service`, `controller`, `module`)

Tabel Luau berisi _setting_ default untuk modul tersebut. Strukturnya bebas sesuai kebutuhan modul.

---

## 🪝 7.3. API UI FRAMEWORK (v1 - HOOKS via Fusion)

Ini adalah API utama untuk membuat UI (menggunakan library **Fusion**).

**Import Utama:**

```lua
local Fusion = require(game.ReplicatedStorage.Packages.Fusion)
local New, Children, Value, Computed, Cleanup, OnEvent, Hydrate, ForPairs, ForKeys, Observer = ... -- (Import sesuai kebutuhan)
```

**API Paling Sering Dipakai:**

- **`Value(initialValue)`**: Membuat state lokal.
  - `:get() -> any`: Baca nilai.
  - `:set(newValue) -> void`: Ubah nilai & trigger update.
- **`Computed(function)`**: Membuat state turunan (otomatis update).
- **`New "InstanceType" { Property = value, [Children] = {}, [OnEvent] = {} }`**: Membuat Instance Roblox baru secara deklaratif.
- **`Hydrate(instance) { ... }`**: Mengambil Instance dari Studio & menambahkan/mengubah properti/event/children.
- **`Cleanup(function)`**: Mendaftarkan fungsi cleanup (disconnect, unsubscribe) yang akan otomatis dipanggil saat komponen hancur. **Wajib untuk mencegah memory leak**.
- **`OnEvent "EventName"`**: Menghubungkan ke event Roblox Instance di dalam `New` atau `Hydrate`. Otomatis disconnect.
- **`Children`**: Key khusus (`[Fusion.Children] = {}`) untuk menampung anak Instance.
- **`ForPairs(table, function(key, value, index))` / `ForKeys(table, function(key, index))`**: Untuk merender daftar UI secara dinamis dari tabel.

_(Untuk API Fusion yang lebih lengkap, lihat dokumentasi resmi Fusion)._

---

## 🛠️ 7.4. API KOMPONEN CODER/BUILDER (v1)

Ini adalah API untuk modul di `src/shared/components/`.

### Atribut (di Studio)

- **`ovhl:component` (string)**: **WAJIB**. Nama _logic_ komponen (harus cocok `__manifest.name`).
- **`ovhl:<namaData>` (any)**: Opsional. Data konfigurasi untuk _logic_. Nama harus diawali `ovhl:`. Tipe data harus didukung oleh Atribut Roblox (string, number, bool, Color3, Vector3, dll.).

### Lifecycle Metode (di Kode Luau)

- **`Component:Knit(instance: Instance, attributes: table)`**: (Wajib Ada)

  - Dipanggil **satu kali** oleh `ComponentService` saat _Instance_ Studio pertama kali "dijodohkan" dengan _logic_ ini.
  - `instance`: _Instance_ dari Studio (Part, Model, UI) yang memiliki Tag/Atribut.
  - `attributes`: Tabel Lua berisi semua Atribut `ovhl:xxx`. _Key_ adalah nama atribut tanpa prefix `ovhl:` (misal: `attributes.damage`, `attributes.spinSpeed`).
  - **Tugas:** Simpan `instance`, baca `attributes`, hubungkan event (`:Connect`), mulai _logic_. Bungkus dengan `pcall` jika ada operasi berisiko.

- **`Component:Destroy()`**: (Wajib Ada)
  - Dipanggil **satu kali** oleh `ComponentService` saat `instance` dihancurkan (`Destroying` event) atau saat game berhenti.
  - **Tugas:** **WAJIB** membersihkan semua koneksi (`:Disconnect()`), _thread_ (`task.cancel()`), _unsubscribe_, dan referensi untuk **mencegah memory leak**.

---

### 🔄 Riwayat Perubahan (Changelog)

| Versi | Tanggal     | Penulis                 | Perubahan                                                                                                                                                                                              |
| :---- | :---------- | :---------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0 | 29 Okt 2025 | OVHL Core Team & Gemini | Rilis awal file detail Referensi API v1. Dibuat dari hasil split `00_MASTER_BLUEPRINT_v1.md`. Menggabungkan API dari V1 dan menambahkan API baru untuk DI, UI Hooks, Coder/Builder, dan Networking v1. |
