# 🧩 05 - WORKFLOW CODER vs. BUILDER (v1 TAG-BASED)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                                              |
| ------------------ | ------------------------------------------------------------------ |
| **ID Dokumen**     | `ARC-v1-005`                                                       |
| **Status**         | `Aktif (Rilis Baru)`                                               |
| **Lokasi Path**    | `./docs/blueprint/05_CODER_BUILDER_WORKFLOW.md`                    |
| **Tipe Dokumen**   | `Detail Alur Kerja Coder/Builder & API Komponen`                   |
| **Target Audiens** | `Coder (Programmer), Builder (Artist/Designer), AI Assistant`      |
| **Relasi**         | `Index: 00_MASTER_BLUEPRINT_v1.md`, `Ref: 01_ARCHITECTURE_CORE.md` |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)`                            |
| **Dibuat**         | `29 Oktober 2025`                                                  |

---

## ⚖️ 5.1. KONSEP PEMISAHAN & FILOSOFI

Salah satu pilar utama OVHL v1 adalah memfasilitasi kolaborasi yang mulus antara peran yang berbeda dalam tim pengembangan game: **Builder/Artist/Designer** dan **Coder/Programmer**.

**Filosofi:** "Pisahkan Tampilan/Penempatan dari Logika."

- **Builder (di Studio):**

  - Bertanggung jawab penuh atas **tampilan visual** dan **penempatan objek** di dalam game (Workspace atau UI).
  - Menggunakan _tools_ bawaan Roblox Studio untuk menata Part, Model, Mesh, GUI, dll.
  - **TIDAK MENULIS KODE.**
  - Tugas utamanya adalah **memberi "Tag" (via Atribut atau CollectionService)** pada _Instance_ yang perlu _logic_ dari Coder. Tag ini berfungsi sebagai "kontrak" atau "nama panggilan".
  - Bisa menambahkan **data konfigurasi** (via Atribut) untuk _logic_ tersebut (misal: kecepatan putaran, jumlah damage).

- **Coder (di VS Code):**

  - Bertanggung jawab penuh atas **logika** dan **perilaku** objek.
  - Menulis kode Luau di folder `src/shared/components/`.
  - **TIDAK PEDULI** di mana atau bagaimana _Instance_ itu ditempatkan oleh Builder.
  - Membuat "Modul Komponen" yang merespon "Tag" yang diberikan oleh Builder.
  - Mengambil data konfigurasi dari Atribut yang diberikan Builder.

- **OVHL (Otomatis via `ComponentService`):**
  - Bertindak sebagai **"Mak Comblang"** otomatis.
  - Saat game berjalan, `ComponentService` akan mencari semua _Instance_ yang punya "Tag" OVHL.
  - Mencari "Modul Komponen" yang cocok dengan "Tag" tersebut.
  - Menghubungkan keduanya: membuat _instance_ dari _logic_ Coder dan mengaitkannya dengan _Instance_ fisik dari Builder.
  - Mengelola _lifecycle_ hubungan ini (memanggil `:Knit` saat terhubung, `:Destroy` saat terputus/hancur).

**Keuntungan:**

- **Kolaborasi Efisien:** Builder dan Coder bisa bekerja **paralel** tanpa saling tunggu atau mengganggu.
- **Reusable Logic:** Satu _logic_ Coder (misal: `SpinningPart.lua`) bisa dipakai oleh Builder untuk ratusan _Part_ yang berbeda di Studio.
- **Clean Workspace:** Tidak ada `Script` atau `LocalScript` acak yang menempel di Part/UI. Semua _logic_ terpusat di `src/shared/components/`.
- **Mudah Dikelola:** Perubahan visual oleh Builder tidak merusak _logic_. Perubahan _logic_ oleh Coder tidak merusak tampilan.

---

## 🏷️ 5.2. METODE PENANDAAN (TAGGING)

Builder punya dua cara untuk memberi "Tag" pada _Instance_ di Studio agar dikenali oleh `ComponentService`:

### Metode 1: Atribut (Attributes) - Direkomendasikan

Ini adalah cara **utama dan paling fleksibel**.

1.  **Pilih Instance** di Studio (Part, Model, Frame, TextButton, dll).
2.  Buka panel **Properties**.
3.  Scroll ke bawah ke bagian **Attributes**. Klik tombol **"+"**.
4.  **Buat Atribut Kunci:**
    - **Nama:** `ovhl:component` (WAJIB nama ini!)
    - **Tipe:** `String`
    - **Value:** Nama _logic_ komponen yang Coder buat (harus cocok dengan `__manifest.name` di file `.lua`, misal: `"LavaPart"`, `"SpinningCoin"`, `"HealthBarUI"`).
5.  **(Opsional) Buat Atribut Data:** Tambahkan atribut lain untuk konfigurasi. **Nama atribut HARUS diawali `ovhl:`** agar mudah dikenali dan tidak bentrok.
    - Contoh 1:
      - Nama: `ovhl:damage`
      - Tipe: `Number`
      - Value: `100`
    - Contoh 2:
      - Nama: `ovhl:spinSpeed`
      - Tipe: `Number`
      - Value: `5`
    - Contoh 3:
      - Nama: `ovhl:targetPlayerState`
      - Tipe: `String`
      - Value: `"coins"` (Untuk UI yang menampilkan state 'coins')

**Keuntungan Atribut:**

- Sangat fleksibel untuk menambahkan data konfigurasi.
- Mudah dilihat dan diedit di panel Properties.
- Didukung penuh oleh `ComponentService` v1.

### Metode 2: CollectionService Tags

Cara alternatif, cocok jika tidak butuh data konfigurasi tambahan.

1.  **Pilih Instance** di Studio.
2.  Buka panel **Tag Editor** (biasanya di tab VIEW > Tag Editor).
3.  Ketik nama Tag di kolom input. **Nama Tag HARUS diawali `OVHL:`** dan diikuti nama _logic_ komponen.
    - Contoh: `OVHL:LavaPart`, `OVHL:SpinningCoin`.
4.  Tekan Enter atau klik tombol centang untuk menambahkan Tag ke Instance.

**Keuntungan CollectionService:**

- Cepat untuk menandai banyak objek dengan _logic_ yang sama tanpa data tambahan.
- Terintegrasi baik dengan API Roblox `CollectionService`.

**Bagaimana `ComponentService` Memilih?**

- `ComponentService` akan **pertama kali** mencari Atribut `ovhl:component`.
- Jika **tidak ditemukan**, dia akan mencari Tag CollectionService yang diawali `OVHL:`.
- Jika **keduanya ada**, Atribut `ovhl:component` akan **diprioritaskan**.

---

## 🗺️ 5.3. ALUR KERJA (LANGKAH DEMI LANGKAH)

Mari kita ambil contoh membuat "Pintu Otomatis".

### Step 1: Kesepakatan Nama

- Coder dan Builder sepakat: Logic untuk pintu otomatis akan dinamai `AutoDoor`.

### Step 2: Builder (di Studio)

1.  Builder membuat sebuah `Model` pintu yang terdiri dari beberapa `Part` (misal: `Frame`, `LeftDoor`, `RightDoor`).
2.  Builder memilih **Model pintu utama**.
3.  Builder menambahkan **Atribut**:
    - `ovhl:component` (String) = `"AutoDoor"`
4.  Builder menambahkan **Atribut data** (opsional):
    - `ovhl:openDistance` (Number) = `10` (Jarak pemain agar pintu terbuka)
    - `ovhl:openSpeed` (Number) = `2` (Kecepatan pintu membuka/menutup)
    - `ovhl:autoCloseDelay` (Number) = `3` (Detik sebelum pintu menutup otomatis)

### Step 3: Coder (di VS Code)

Coder membuat _logic_ di folder `components`.

_File: `src/shared/components/AutoDoor.lua`_

```lua
local TweenService = game:GetService("TweenService")

local AutoDoor = {}
AutoDoor.__index = AutoDoor

-- 1. Manifest Komponen
AutoDoor.__manifest = {
    name = "AutoDoor", -- Cocokkan dengan Atribut 'ovhl:component'
    type = "component"
    -- Dependencies: Opsional, jika komponen butuh service inti
    -- dependencies = {"Logger"}
}

-- Properti Internal
AutoDoor.model = nil
AutoDoor.leftDoor = nil
AutoDoor.rightDoor = nil
AutoDoor.detector = nil -- Part tak terlihat untuk deteksi jarak
AutoDoor.config = {}
AutoDoor.isOpen = false
AutoDoor.debounce = false
AutoDoor.connections = {}

-- 2. :Knit (Constructor)
-- Dipanggil oleh ComponentService saat Model pintu ditemukan
function AutoDoor:Knit(instanceModel, attributes)
    self.model = instanceModel

    -- Cari part pintu berdasarkan nama (Builder harus konsisten menamai)
    self.leftDoor = self.model:FindFirstChild("LeftDoor")
    self.rightDoor = self.model:FindFirstChild("RightDoor")

    -- Validasi apakah part penting ada
    if not (self.leftDoor and self.rightDoor) then
        warn("[AutoDoor] Knit failed: Missing LeftDoor or RightDoor part in model:", instanceModel:GetFullName())
        return -- Gagal Knit, komponen tidak aktif
    end

    -- Simpan posisi awal pintu (tertutup)
    self.closedPosLeft = self.leftDoor.CFrame
    self.closedPosRight = self.rightDoor.CFrame

    -- Ambil konfigurasi dari Atribut (dengan nilai default)
    self.config = {
        openDistance = attributes.openDistance or 12,
        openSpeed = attributes.openSpeed or 1.5,
        autoCloseDelay = attributes.autoCloseDelay or 3
    }

    -- Buat Part Detector (jika belum ada)
    self.detector = self.model:FindFirstChild("Detector")
    if not self.detector then
        self.detector = Instance.new("Part")
        self.detector.Name = "Detector"
        self.detector.Size = Vector3.new(self.config.openDistance * 2, 6, self.config.openDistance * 2)
        self.detector.CFrame = self.model.PrimaryPart and self.model.PrimaryPart.CFrame or self.model:GetPivot()
        self.detector.Anchored = true
        self.detector.CanCollide = false
        self.detector.CanQuery = false -- Agar tidak terdeteksi raycast lain
        self.detector.CanTouch = true -- Harus bisa disentuh
        self.detector.Transparency = 1
        self.detector.Parent = self.model
    end

    -- Hubungkan event Touched dan TouchEnded
    self.connections.touched = self.detector.Touched:Connect(function(hit) self:OnDetectorTouch(hit) end)
    self.connections.touchEnded = self.detector.TouchEnded:Connect(function(hit) self:OnDetectorTouchEnded(hit) end)

    print("[AutoDoor] Knit success:", instanceModel:GetFullName())
end

-- 3. Logika Internal
function AutoDoor:OnDetectorTouch(hit)
    if self.debounce then return end
    local player = game.Players:GetPlayerFromCharacter(hit.Parent)
    if player and not self.isOpen then
        self:OpenDoors()
    end
end

function AutoDoor:OnDetectorTouchEnded(hit)
    -- Perlu logika lebih canggih untuk cek apakah masih ada pemain di area
    -- Untuk simpelnya, kita pakai delay auto-close
end

function AutoDoor:OpenDoors()
    if self.isOpen or self.debounce then return end
    self.isOpen = true
    self.debounce = true

    -- Hitung posisi terbuka (geser ke samping)
    local openOffset = Vector3.new(self.leftDoor.Size.X, 0, 0)
    local openPosLeft = self.closedPosLeft * CFrame.new(-openOffset)
    local openPosRight = self.closedPosRight * CFrame.new(openOffset)

    local tweenInfo = TweenInfo.new(self.config.openSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local tweenLeft = TweenService:Create(self.leftDoor, tweenInfo, {CFrame = openPosLeft})
    local tweenRight = TweenService:Create(self.rightDoor, tweenInfo, {CFrame = openPosRight})

    tweenLeft:Play()
    tweenRight:Play()

    -- Tunggu animasi selesai
    tweenRight.Completed:Wait()

    self.debounce = false

    -- Jadwalkan auto-close
    task.delay(self.config.autoCloseDelay, function()
        -- Cek lagi apakah masih ada pemain sebelum menutup (logika tambahan)
        self:CloseDoors()
    end)
end

function AutoDoor:CloseDoors()
     if not self.isOpen or self.debounce then return end
     self.isOpen = false
     self.debounce = true

     local tweenInfo = TweenInfo.new(self.config.openSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
     local tweenLeft = TweenService:Create(self.leftDoor, tweenInfo, {CFrame = self.closedPosLeft})
     local tweenRight = TweenService:Create(self.rightDoor, tweenInfo, {CFrame = self.closedPosRight})

     tweenLeft:Play()
     tweenRight:Play()

     tweenRight.Completed:Wait()
     self.debounce = false
end

-- 4. :Destroy (Destructor)
-- Dipanggil oleh ComponentService saat Model pintu dihapus
function AutoDoor:Destroy()
    -- Disconnect semua koneksi
    for _, conn in pairs(self.connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(self.connections)

    print("[AutoDoor] Destroyed:", self.model and self.model:GetFullName() or "Unknown")
end

return AutoDoor
```

### Step 4: OVHL (Otomatis via `ComponentService`)

- Saat game dimulai, `ComponentService` berjalan.
- Dia menemukan Model pintu dengan Atribut `ovhl:component` = `"AutoDoor"`.
- Dia membaca Atribut lain: `{ openDistance = 10, openSpeed = 2, autoCloseDelay = 3 }`.
- Dia mencari _logic_ `AutoDoor` yang sudah terdaftar dari `src/shared/components/AutoDoor.lua`.
- Dia membuat _instance_ baru dari `AutoDoor` dan memanggil `:Knit(modelPintu, {openDistance=10, ...})`.
- Pintu sekarang otomatis berfungsi.
- Jika Model pintu dihapus dari game, `ComponentService` akan otomatis memanggil `:Destroy()` pada _instance_ `AutoDoor` tersebut untuk membersihkan koneksi.

---

## 🛠️ 5. API KOMPONEN & `ComponentService`

### 5.1. API Komponen (Metode di File Komponen)

- **`Component:Knit(instance: Instance, attributes: table)`**: (Wajib Ada)

  - Fungsi _constructor_ yang dipanggil `ComponentService`.
  - `instance`: _Instance_ dari Studio (Part, Model, UI) yang memiliki Tag/Atribut.
  - `attributes`: Tabel Lua berisi semua Atribut `ovhl:xxx` yang ada di _Instance_ tersebut. _Key_ adalah nama atribut tanpa prefix `ovhl:`. Contoh: Jika ada Atribut `ovhl:damage`, maka `attributes.damage` akan berisi nilainya.
  - Tugas utama: Menyimpan referensi `instance`, membaca `attributes`, dan menghubungkan _event_ atau memulai _logic_.
  - Jika terjadi error kritis saat Knit, `warn()` dan `return` agar komponen tidak aktif.

- **`Component:Destroy()`**: (Wajib Ada)
  - Fungsi _destructor_ yang dipanggil `ComponentService` saat `instance` dihancurkan atau game berhenti.
  - Tugas utama: **Membersihkan semua koneksi** (`:Disconnect()`), _thread_ (`task.cancel()`), _unsubscribe_ event, atau referensi eksternal untuk **mencegah memory leak**.

### 5.2. `ComponentService` (Core Service Otomatis)

- **Tugas:** Menjembatani dunia Builder dan Coder secara otomatis.
- **Cara Kerja:**
  1.  **Registrasi Logic:** Saat startup, dia _Auto-Discover_ semua file di `src/shared/components/` yang punya `__manifest.type = "component"`. Dia menyimpan _logic_ ini dalam sebuah _registry_.
  2.  **Pemindaian Instance:** Dia memindai `game.Workspace` dan `game.Players.LocalPlayer.PlayerGui` (di client) untuk _Instance_ yang memiliki Atribut `ovhl:component` atau Tag CollectionService `OVHL:NamaKomponen`.
  3.  **Knitting (Menjahit):** Saat menemukan _Instance_ yang cocok, dia:
      a. Membaca nama _logic_ dari Atribut/Tag.
      b. Membaca semua Atribut `ovhl:xxx` lainnya dan mengubahnya menjadi tabel `attributes`.
      c. Mencari _logic_ yang sesuai di _registry_.
      d. Membuat _instance_ baru dari _logic_ tersebut.
      e. Memanggil `:Knit(instanceStudio, attributes)` pada _instance logic_ baru.
      f. Menyimpan referensi antara _instance Studio_ dan _instance logic_.
  4.  **Lifecycle Management:**
      a. Dia mendengarkan event `instanceStudio.Destroying`.
      b. Saat _Instance Studio_ hancur, dia mencari _instance logic_ yang terkait dan memanggil `:Destroy()` padanya.
      c. Dia membersihkan referensi.
- **Akses:** Developer **tidak perlu** memanggil `ComponentService` secara langsung. Semuanya berjalan otomatis di _background_.

---

### 🔄 Riwayat Perubahan (Changelog)

| Versi | Tanggal     | Penulis                 | Perubahan                                                                                                                                                                                                                  |
| :---- | :---------- | :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0 | 29 Okt 2025 | OVHL Core Team & Gemini | Rilis awal file detail Workflow Coder vs. Builder v1. Dibuat dari hasil split `00_MASTER_BLUEPRINT_v1.md`. Menjelaskan konsep, alur kerja Atribut/Tag, API Komponen (`Knit`/`Destroy`), dan cara kerja `ComponentService`. |
