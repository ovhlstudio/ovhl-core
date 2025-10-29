# 🍳 08 - RESEP KODING (COOKBOOK v1)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                            |
| ------------------ | ------------------------------------------------ |
| **ID Dokumen**     | `ARC-v1-008`                                     |
| **Status**         | `Aktif (Rilis Baru)`                             |
| **Lokasi Path**    | `./docs/blueprint/08_COOKBOOK_RECIPES.md`        |
| **Tipe Dokumen**   | `Contoh Kode Praktis`                            |
| **Target Audiens** | `All Developers, AI Assistant`                   |
| **Relasi**         | `Index: 00_MASTER_BLUEPRINT_v1.md`, `Ref: 01-07` |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)`          |
| **Dibuat**         | `29 Oktober 2025`                                |

---

## 📖 Pengantar

Selamat datang di "Cookbook" OVHL Core v1! Dokumen ini berisi kumpulan "resep" atau contoh kode praktis untuk menyelesaikan tugas-tugas umum saat membuat modul game menggunakan arsitektur v1. Fokusnya adalah **bagaimana melakukan sesuatu** dengan cepat dan benar menggunakan API `OVHL` dan pola v1 (DI, Hooks, Coder/Builder, Networking Aman).

**Asumsi:**

- Anda sudah melakukan setup sesuai `02_DEV_WORKFLOW.md`.
- Anda sudah memahami konsep dasar `OVHL` Global Accessor, DI v1, UI Hooks v1, Coder/Builder, dan Networking v1.

**Cara Membaca Resep:**
Setiap resep akan mencakup:

1.  **Kasus Penggunaan:** Masalah yang ingin diselesaikan.
2.  **Lokasi File:** Di mana menaruh kode ini.
3.  **Kode Snippet:** Potongan kode relevan yang mengilustrasikan pola v1.
4.  **Penjelasan v1:** Menjelaskan bagaimana pola v1 (DI, Hooks, Schema, pcall) diterapkan.

---

## 🎨 RESEP 1: MEMBUAT UI SEDERHANA (v1 HOOKS)

**Kasus Penggunaan:** Menampilkan jumlah koin pemain di layar, update otomatis saat koin berubah.
**Lokasi File:** `src/client/modules/CoinDisplay.lua`

```lua
-- File: src/client/modules/CoinDisplay.lua

-- [v1] 1. Ambil OVHL & Fusion
local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)
local Fusion = require(game.ReplicatedStorage.Packages.Fusion)
local New, Children, Value, Computed, Cleanup = Fusion.New, Fusion.Children, Fusion.Value, Fusion.Computed, Fusion.Cleanup

-- [v1] 2. Komponen adalah fungsi
local function CoinDisplay(props)

    -- [v1] 3. Buat state 'coins' (Value), ambil nilai awal dari OVHL StateManager
    local coins = Value(OVHL:GetState("coins", 0))

    -- [v1] 4. Gunakan Cleanup untuk langganan & auto-unsubscribe
    Cleanup(function()
        local unsub = OVHL:Subscribe("coins", function(newCoins)
            coins:set(newCoins) -- Update state lokal jika global state berubah
        end)

        -- Fungsi cleanup (auto dipanggil saat komponen hancur)
        return unsub
    end)

    -- [v1] 5. Render UI menggunakan 'New' dan 'Computed'
    return New "TextLabel" {
        Name = "CoinDisplay",
        Size = UDim2.fromOffset(150, 40),
        Position = UDim2.fromOffset(10, 10), -- Pojok kiri atas
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        TextColor3 = Color3.fromRGB(255, 200, 0), -- Emas
        TextSize = 16,
        Font = Enum.Font.GothamSemibold,

        -- Ikat Text ke state 'coins' via Computed agar otomatis update
        Text = Computed(function()
            return "💰 " .. coins:get()
        end),

        [Children] = { -- Contoh menambahkan UICorner
            New "UICorner" { CornerRadius = UDim.new(0, 6) }
        }
    }
end

-- [v1] 6. Definisikan Manifest & Export
local manifest = {
    name = "CoinDisplay",
    version = "1.0.0",
    type = "module", -- Tipe 'module' untuk UI Client
    domain = "ui",
    description = "Menampilkan jumlah koin pemain (Hooks v1)"
}
-- Wrapper Create untuk UIEngine
local function Create(props) return CoinDisplay(props or {}) end
-- Format return standar untuk modul UI
return { Create = Create, __manifest = manifest }
```

**Penjelasan v1:**

1.  **Hooks:** Menggunakan `Value` untuk state lokal, `Computed` untuk teks yang reaktif, dan `Cleanup` untuk _subscribe/unsubscribe_ ke `OVHL:Subscribe("coins")`. Tidak ada lagi `:Init`, `:DidMount`, `:WillUnmount` manual.
2.  **StateManager:** Mengambil dan mendengarkan _state_ global `coins` melalui API `OVHL`.
3.  **Fusion:** Menggunakan `New`, `Children`, `Value`, `Computed`, `Cleanup` dari library Fusion.

---

## 💾 RESEP 2: MENYIMPAN DATA (v1 DI)

**Kasus Penggunaan:** Menyimpan progres level pemain saat dia keluar dari game, menggunakan Dependency Injection.
**Lokasi File:** `src/server/modules/LevelSystem.lua`

```lua
-- File: src/server/modules/LevelSystem.lua

-- [v1] 1. Ambil OVHL (hanya jika perlu Emit/Subscribe)
local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

local LevelSystem = {}
LevelSystem.__index = LevelSystem

-- [v1] 2. Manifest dengan deklarasi dependensi
LevelSystem.__manifest = {
    name = "LevelSystem",
    version = "1.0.0",
    type = "module",
    domain = "gameplay",
    dependencies = {"Logger", "DataService"} -- Butuh Logger dan DataService
}

-- [v1] 3. Deklarasi properti internal (opsional)
LevelSystem.logger = nil
LevelSystem.dataService = nil
LevelSystem.playerLevels = {} -- Cache level di memori

-- [v1] 4. Inject dependensi
function LevelSystem:Inject(services)
    self.logger = services.Logger
    self.dataService = services.DataService
end

-- [v1] 5. Init (opsional)
function LevelSystem:Init()
    assert(self.logger and self.dataService, "Dependencies not injected!")
    self.playerLevels = {}
    self.logger:Info("LevelSystem Initialized")
    return true
end

-- [v1] 6. Start (Langganan event)
function LevelSystem:Start()
    OVHL:Subscribe("PlayerJoined", function(player)
        -- Bungkus pcall untuk No Crash
        local success, err = pcall(function() self:LoadPlayerLevel(player) end)
        if not success then self.logger:Error("Error loading level", {player=player.Name, error=err}) end
    end)

    OVHL:Subscribe("PlayerRemoving", function(player)
        -- Bungkus pcall untuk No Crash
        local success, err = pcall(function() self:SavePlayerLevel(player) end)
        if not success then self.logger:Error("Error saving level", {player=player.Name, error=err}) end
    end)

    self.logger:Info("LevelSystem Started")
end

-- [v1] 7. Logika (menggunakan service yang di-inject)
function LevelSystem:LoadPlayerLevel(player)
    local userId = player.UserId
    -- Gunakan self.dataService
    local success, data = self.dataService:GetPlayerData(player, "PlayerProgress")

    if success and data and data.level then
        self.playerLevels[userId] = data.level
        self.logger:Info("Level dimuat untuk " .. player.Name .. ": " .. data.level)
    else
        self.playerLevels[userId] = 1 -- Default level 1
        -- Gunakan self.logger
        self.logger:Warn("Gagal load level " .. player.Name .. ", default 1", {error = data})
    end
end

function LevelSystem:SavePlayerLevel(player)
    local userId = player.UserId
    local currentLevel = self.playerLevels[userId]
    if not currentLevel then return end -- Tidak ada data untuk disimpan

    self.logger:Info("Menyimpan level " .. player.Name .. ": " .. currentLevel)
    -- Gunakan self.dataService, bungkus pcall
    local success, err = pcall(function()
        local dataToSave = { level = currentLevel }
        return self.dataService:SetPlayerData(player, "PlayerProgress", dataToSave)
    end)

    if not success then
        -- Gunakan self.logger
        self.logger:Error("Gagal menyimpan level " .. player.Name, {error = err})
    else
        self.playerLevels[userId] = nil -- Hapus dari memori setelah disimpan
    end
end

-- Fungsi lain (contoh: naik level)
function LevelSystem:IncreaseLevel(player, amount)
    local userId = player.UserId
    if self.playerLevels[userId] then
        self.playerLevels[userId] = self.playerLevels[userId] + (amount or 1)
        local newLevel = self.playerLevels[userId]
        -- Emit event (pakai OVHL karena ini komunikasi antar modul)
        OVHL:Emit("PlayerLevelUp", player, newLevel)
        self.logger:Info(player.Name .. " naik ke level " .. newLevel)
    end
end

return LevelSystem
```

**Penjelasan v1:**

1.  **Dependency Injection:** `Logger` dan `DataService` dideklarasikan di `__manifest.dependencies` dan secara otomatis di-_inject_ ke `self` melalui `:Inject()`. Tidak ada lagi `OVHL:GetService()` di tengah kode.
2.  **Lifecycle v1:** Mengikuti urutan `:Inject`, `:Init`, `:Start`.
3.  **No Crash:** Logika di _handler_ `Subscribe` dan saat memanggil `DataService:SetPlayerData` dibungkus `pcall`, dan _error_ dicatat menggunakan `self.logger`.

---

## 🧩 RESEP 3: CODER/BUILDER (LAVA PART)

**Kasus Penggunaan:** Builder membuat Part di Studio, Coder menambahkan _logic_ agar Part tersebut mematikan pemain saat disentuh.

**Step 1: Builder (di Studio)**

- Buat `Part`, taruh di `workspace`, warnai merah.
- Beri **Atribut**:
  - `ovhl:component` (String) = `"LavaPart"`
  - `ovhl:damage` (Number) = `100`

**Step 2: Coder (di VS Code)**

- Buat file: `src/shared/components/LavaPart.lua`

```lua
-- File: src/shared/components/LavaPart.lua
local LavaPart = {}
LavaPart.__index = LavaPart

-- [v1] 1. Manifest Komponen
LavaPart.__manifest = {
    name = "LavaPart", -- Harus cocok dg Atribut 'ovhl:component'
    type = "component" -- Tipe khusus untuk workflow ini
}

-- Properti internal
LavaPart.part = nil
LavaPart.damage = 100 -- Nilai default jika atribut tidak ada
LavaPart.touchConn = nil

-- [v1] 2. :Knit (Constructor) - Dipanggil ComponentService
function LavaPart:Knit(instance, attributes)
    -- Pastikan instance adalah BasePart
    if not instance:IsA("BasePart") then
        warn("[LavaPart] Knit failed: Instance bukan BasePart:", instance:GetFullName())
        return -- Jangan lanjutkan jika tipe salah
    end

    self.part = instance
    -- Ambil damage dari atribut, fallback ke default
    self.damage = attributes.damage or self.damage

    -- Bungkus koneksi event dengan pcall (best practice)
    local success, conn = pcall(function()
        return self.part.Touched:Connect(function(hit)
             -- Bungkus handler juga
            local ok, err = pcall(function() self:OnTouch(hit) end)
            if not ok then warn("[LavaPart] Error in OnTouch:", err) end
        end)
    end)

    if success then
        self.touchConn = conn
        print("[LavaPart] Knit success:", instance:GetFullName(), "Damage:", self.damage)
    else
        warn("[LavaPart] Knit failed to connect Touched event:", conn) -- conn berisi error
    end
end

-- [v1] 3. Logika Internal
function LavaPart:OnTouch(hit)
    -- Cari Humanoid di parent object yang menyentuh
    local character = hit.Parent
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

    -- Beri damage jika ada Humanoid dan belum mati
    if humanoid and humanoid.Health > 0 then
        humanoid:TakeDamage(self.damage)
    end
end

-- [v1] 4. :Destroy (Destructor) - Dipanggil ComponentService
function LavaPart:Destroy()
    if self.touchConn then
        self.touchConn:Disconnect()
        self.touchConn = nil -- Cleanup referensi
    end
    print("[LavaPart] Destroyed:", self.part and self.part:GetFullName() or "Unknown")
end

return LavaPart
```

**Penjelasan v1:**

1.  **Pemisahan:** Builder hanya menata Part dan memberi Atribut. Coder hanya menulis _logic_ di file `.lua` ini.
2.  **`__manifest.type = "component"`:** Memberi tahu `ComponentService` bahwa ini adalah _logic_ untuk Coder/Builder.
3.  **`:Knit(instance, attributes)`:** Fungsi "penghubung". Menerima Part (`instance`) dan data (`attributes`) dari Builder.
4.  **`:Destroy()`:** Fungsi "pembersih". Wajib disconnect semua koneksi event untuk mencegah _memory leak_.
5.  **No Crash:** Koneksi event dan _handler_ `OnTouch` dibungkus `pcall` sebagai _best practice_, meskipun logikanya sederhana.

---

## 🔐 RESEP 4: BELI ITEM (NETWORKING v1 AMAN)

**Kasus Penggunaan:** Client memanggil server untuk membeli item. Panggilan ini harus aman dari spam (_rate limit_) dan _exploit_ (validasi tipe data).

**Step 1: Definisikan Schema (Kontrak Network)**
_File: `src/shared/NetworkSchema.lua`_

```lua
-- src/shared/NetworkSchema.lua
local t = require(game.ReplicatedStorage.Packages.t) -- Instal 't' via Wally

local NetworkSchema = {
    -- Kontrak untuk remote Shop:BuyItem
    ["Shop:BuyItem"] = t.tuple( -- Argumen harus dalam urutan ini
        t.string,               -- Arg 1: itemId (harus string)
        t.integer               -- Arg 2: quantity (harus integer)
    )
    -- Tambahkan schema untuk remote lain di sini...
}

assert(t.map(t.string, t.tuple)(NetworkSchema), "NetworkSchema tidak valid!")
return NetworkSchema
```

**Step 2: Client (UI Panggil Invoke)**
_File: `src/client/modules/ShopUI.lua` (dibuat pakai Hooks v1)_

```lua
-- File: src/client/modules/ShopUI.lua
local OVHL = require(...)
local Fusion = require(...)
local New, Value, OnEvent, Cleanup = Fusion.New, Fusion.Value, Fusion.OnEvent, Fusion.Cleanup

local function ShopItemButton(props)
    local itemId = props.itemId
    local canClick = Value(true) -- State untuk debounce

    local function handleBuyClick()
        if not canClick:get() then return end -- Debounce aktif
        canClick:set(false) -- Kunci tombol

        local quantity = 1 -- Contoh quantity
        print("Mencoba membeli:", itemId, "Qty:", quantity)

        -- Panggil Invoke dalam task.spawn agar tidak blok UI
        task.spawn(function()
            -- Bungkus pcall untuk error network/server
            local success, result = pcall(OVHL.Invoke, OVHL, "Shop:BuyItem", itemId, quantity)

            if success then
                if result and result.success then
                    print("Pembelian berhasil!", result.data)
                    -- Mungkin update state koin dari result.data.newCoins
                    -- OVHL:SetState("PlayerCoins", result.data.newCoins)
                else
                    warn("Pembelian ditolak server:", result and result.error or "Unknown server error")
                    -- Tampilkan pesan error ke user
                end
            else
                warn("Gagal menghubungi server:", result) -- result = error pcall
                -- Tampilkan pesan error network ke user
            end

            -- Buka kunci tombol setelah 1 detik (contoh cooldown)
            task.delay(1, function() canClick:set(true) end)
        end)
    end

    return New "TextButton" {
        Text = "Beli " .. itemId,
        [OnEvent "MouseButton1Click"] = handleBuyClick
    }
end

-- Export Komponen UI (ingat manifest & Create)
-- ...
```

**Step 3: Server (Module Handler dengan DI v1)**
_File: `src/server/modules/ShopModule.lua`_

```lua
-- File: src/server/modules/ShopModule.lua
local OVHL = require(...)

local ShopModule = {}
ShopModule.__index = ShopModule

-- Manifest dengan dependensi
ShopModule.__manifest = {
    name = "ShopModule",
    type = "module",
    dependencies = {"Logger", "EconomyService", "InventoryService", "RemoteManager"}
}

-- Properti internal
ShopModule.logger = nil
ShopModule.economyService = nil
ShopModule.inventoryService = nil
ShopModule.itemPrices = { Sword = 100, Shield = 150 } -- Contoh harga

-- Inject dependensi
function ShopModule:Inject(services)
    self.logger = services.Logger
    self.economyService = services.EconomyService
    self.inventoryService = services.InventoryService

    -- Daftarkan handler ke RemoteManager v1
    services.RemoteManager:RegisterHandler("Shop:BuyItem", function(player, ...)
        -- Langsung panggil metode internal, bungkus pcall di sana
        return self:ProcessPurchase(player, ...)
    end)
end

function ShopModule:Init()
    -- Ambil config harga jika ada
    local config = OVHL:GetConfig("ShopModule")
    if config and config.DefaultPrices then self.itemPrices = config.DefaultPrices end
    return true
end

function ShopModule:Start()
    self.logger:Info("ShopModule Started")
end

-- Handler utama untuk pembelian
function ShopModule:ProcessPurchase(player, itemId, quantity)
    -- TIDAK PERLU VALIDASI TIPE ARGUMEN di sini!
    -- RemoteManager v1 sudah melakukannya berdasarkan NetworkSchema.lua.
    -- Kita bisa langsung percaya itemId adalah string, quantity adalah integer.

    -- Lakukan validasi bisnis & bungkus pcall
    local success, result = pcall(function()
        local price = self.itemPrices[itemId]
        if not price then
            error("Item tidak ditemukan: " .. tostring(itemId)) -- error() akan ditangkap pcall
        end

        local totalPrice = price * quantity

        -- Gunakan service yang sudah di-inject
        if not self.economyService:HasEnoughCoins(player, totalPrice) then
            -- Kembalikan error bisnis yang aman untuk client
            return { success = false, error = "Koin tidak cukup." }
        end
        if not self.inventoryService:HasEnoughSlots(player, quantity) then
             return { success = false, error = "Inventory penuh." }
        end

        -- Lakukan transaksi (anggap fungsi ini atomic atau punya rollback internal)
        local decreaseOk = self.economyService:DecreaseCoins(player, totalPrice)
        local addOk = self.inventoryService:AddItem(player, itemId, quantity)

        if not (decreaseOk and addOk) then
             -- Lakukan rollback jika perlu (tergantung desain service lain)
             self.economyService:IncreaseCoins(player, totalPrice) -- Contoh rollback
             error("Gagal menyelesaikan transaksi.") -- Error internal
        end

        local newCoins = self.economyService:GetCoins(player)

        -- Kembalikan hasil sukses
        return {
            success = true,
            data = { -- Data yang mau dikirim balik ke client
                purchasedItem = itemId,
                quantity = quantity,
                newCoins = newCoins
            }
        }
    end)

    if not success then
        -- Log error internal server
        self.logger:Error("ProcessPurchase gagal", {
            player = player.Name, itemId = itemId, quantity = quantity, error = result -- result = pesan error
        })
        -- Kembalikan pesan error umum ke client (jangan bocorkan detail error internal)
        -- Periksa apakah result adalah tabel error bisnis kita atau error pcall
        if type(result) == "table" and result.error then
             return result -- Kembalikan error bisnis (misal: Koin tidak cukup)
        else
             return { success = false, error = "Terjadi kesalahan pada server." }
        end
    else
        -- Jika pcall sukses, result adalah tabel {success=true/false, ...} dari dalam pcall
        if result.success then
             self.logger:Info("Pembelian sukses", {player=player.Name, itemId=itemId, quantity=quantity})
             -- Emit event internal (opsional)
             OVHL:Emit("ItemPurchased", player, itemId, quantity)
        end
        return result -- Kembalikan hasil ke client
    end
end

return ShopModule
```

**Penjelasan v1:**

1.  **Schema `t`:** Kontrak `Shop:BuyItem` didefinisikan di `NetworkSchema.lua`. `RemoteManager v1` otomatis memvalidasi tipe argumen `itemId` (string) dan `quantity` (integer) sebelum `ProcessPurchase` dipanggil.
2.  **Rate Limiting:** `RemoteManager v1` otomatis membatasi seberapa sering `Shop:BuyItem` bisa dipanggil per pemain.
3.  **Dependency Injection:** `ShopModule` mendapatkan `Logger`, `EconomyService`, `InventoryService`, dan `RemoteManager` melalui `:Inject()`.
4.  **No Crash & Logging:** Logika inti `ProcessPurchase` dibungkus `pcall`. _Error_ bisnis (seperti "Koin tidak cukup") dikembalikan sebagai `{ success = false, error = "..." }`. _Error_ tak terduga ditangkap `pcall`, dicatat oleh `Logger`, dan pesan _error_ umum dikembalikan ke _client_.
5.  **Debounce Client:** UI Client menggunakan _state_ `canClick` untuk mencegah _spam klik_ tombol Beli.

---

---

## 📢 RESEP 5: KOMUNIKASI ANTAR MODUL SERVER (EVENTBUS)

**Kasus Penggunaan:** Saat `LevelSystem` menaikkan level pemain (`Emit`), `AchievementSystem` perlu tahu (`Subscribe`) untuk mengecek _achievement_.

**Emitter (`src/server/modules/LevelSystem.lua`):**

```lua
-- (Sambungan dari Resep 2)
-- Asumsi self.logger sudah di-inject
function LevelSystem:IncreaseLevel(player, amount)
    local userId = player.UserId
    if self.playerLevels[userId] then
        self.playerLevels[userId] = self.playerLevels[userId] + (amount or 1)
        local newLevel = self.playerLevels[userId]

        -- Emit event menggunakan OVHL:Emit
        OVHL:Emit("PlayerLevelUp", player, newLevel) -- Kirim event internal

        self.logger:Info(player.Name .. " naik ke level " .. newLevel)
    end
end
```

**Listener (`src/server/modules/AchievementSystem.lua`):**

```lua
-- File: src/server/modules/AchievementSystem.lua
local OVHL = require(...)

local AchievementSystem = {}
AchievementSystem.__index = AchievementSystem

AchievementSystem.__manifest = {
    name = "AchievementSystem",
    type = "module",
    dependencies = {"Logger"} -- Butuh Logger
}

AchievementSystem.logger = nil
AchievementSystem.unsubscribeFuncs = {} -- Simpan fungsi unsubscribe

function AchievementSystem:Inject(services) self.logger = services.Logger end
function AchievementSystem:Init() self.unsubscribeFuncs = {}; return true end

function AchievementSystem:Start()
    -- Subscribe ke event menggunakan OVHL:Subscribe
    local unsub = OVHL:Subscribe("PlayerLevelUp", function(player, newLevel)
        -- Bungkus logika handler dengan pcall (WAJIB!)
        local success, err = pcall(function()
            self:CheckLevelUpAchievement(player, newLevel)
        end)
        if not success then
            self.logger:Error("Error di handler PlayerLevelUp", {player=player.Name, error = err})
        end
    end)
    -- Simpan fungsi unsubscribe untuk cleanup
    table.insert(self.unsubscribeFuncs, unsub)

    self.logger:Info("AchievementSystem Started, listening for events...")
end

-- Metode internal
function AchievementSystem:CheckLevelUpAchievement(player, newLevel)
    self.logger:Info("Mengecek achievement level up: " .. player.Name .. " Lv." .. newLevel)
    -- ... (Logika cek achievement berdasarkan newLevel) ...
    if newLevel == 10 then
        -- Berikan achievement "Level 10 Reached"
        print("Achievement Unlocked: Level 10!")
        -- Mungkin Emit event lain: OVHL:Emit("AchievementUnlocked", player, "Level10")
    end
end

-- Cleanup (akan dipanggil framework saat shutdown, TAPI best practice tetap cleanup manual jika memungkinkan)
-- Kita bisa tambahkan metode :Stop() di lifecycle jika perlu cleanup sebelum shutdown
function AchievementSystem:Stop()
     self.logger:Info("AchievementSystem stopping, unsubscribing events...")
     for _, unsub in ipairs(self.unsubscribeFuncs) do
         pcall(unsub) -- Bungkus pcall untuk keamanan
     end
     table.clear(self.unsubscribeFuncs)
end


return AchievementSystem
```

**Penjelasan v1:**

1.  **Decoupled:** `LevelSystem` tidak tahu `AchievementSystem` ada. Dia hanya `Emit` _event_.
2.  **DI:** `AchievementSystem` mendapatkan `Logger` via `:Inject()`.
3.  **No Crash:** _Handler_ `Subscribe` **wajib** dibungkus `pcall` agar _error_ di _listener_ tidak mengganggu _emitter_ atau _listener_ lain.
4.  **Cleanup:** Fungsi `unsubscribe` yang dikembalikan `OVHL:Subscribe` disimpan dan dipanggil saat modul berhenti (atau di lifecycle `:Stop()` jika diimplementasikan) untuk mencegah _memory leak_.

---

---

### 🔄 Riwayat Perubahan (Changelog)

| Versi | Tanggal     | Penulis                 | Perubahan                                                                                                                                                                                        |
| :---- | :---------- | :---------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0 | 29 Okt 2025 | OVHL Core Team & Gemini | Rilis awal file detail Resep Koding v1. Dibuat dari hasil split `00_MASTER_BLUEPRINT_v1.md`. Mengupdate semua resep untuk menggunakan pola v1 (DI, UI Hooks, Coder/Builder, Networking v1 Aman). |
