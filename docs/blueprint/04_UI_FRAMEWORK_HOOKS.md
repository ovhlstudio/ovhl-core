# 🎨 04 - UI FRAMEWORK (v1 - HOOKS)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                             |
| ------------------ | ------------------------------------------------- |
| **ID Dokumen**     | `ARC-v1-004`                                      |
| **Status**         | `Aktif (Rilis Baru)`                              |
| **Lokasi Path**    | `./docs/blueprint/04_UI_FRAMEWORK_HOOKS.md`       |
| **Tipe Dokumen**   | `Detail Arsitektur UI & API Hooks`                |
| **Target Audiens** | `UI Developers, Core Dev, AI Assistant`           |
| **Relasi**         | `Index: 00_MASTER_BLUEPRINT_v1.md`, `Lib: Fusion` |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)`           |
| **Dibuat**         | `29 Oktober 2025`                                 |

---

## 🎨 4.1. FILOSOFI UI v1

UI Framework v1 adalah _upgrade_ fundamental dari pendekatan `BaseComponent` V1. Kita mengadopsi pola **Hooks** yang modern, reaktif, dan fungsional, terinspirasi dari React dan diimplementasikan secara _native_ menggunakan library **Fusion**.

- **Fungsional & Reaktif:** UI adalah _fungsi_ murni dari _state_. Saat _state_ (baik lokal maupun global dari `StateManager`) berubah, UI akan secara otomatis (dan efisien) menghitung ulang dan memperbarui hanya bagian yang perlu diubah.
- **Hooks-Based:** Kita tidak lagi menggunakan metode _lifecycle_ `:Init`, `:DidMount`, `:WillUnmount` secara manual. Sebagai gantinya, kita menggunakan fungsi-fungsi khusus yang disebut _Hooks_ (seperti `Value` untuk state, `Computed` untuk state turunan, `Cleanup` untuk _cleanup_) di dalam _fungsi komponen_ kita. Ini membuat kode lebih deklaratif dan mudah dibaca.
- **100% Luau Native (via Fusion):** Ini bukan _wrapper_ React. Kita menggunakan **Fusion**, sebuah library Luau yang kuat dan populer untuk UI reaktif di Roblox. Fusion menyediakan implementasi _Hooks_ dan _rendering engine_ yang efisien. Library ini diinstal via Wally.
- **Komposabilitas:** UI dibangun dari komponen-komponen kecil yang bisa digabungkan (dikomposisi) menjadi UI yang lebih kompleks.

---

## 🪝 4.2. API HOOKS UTAMA (Implementasi via Fusion)

Untuk menggunakan framework ini, Anda perlu menginstal **Fusion** via Wally (`wally install elttob/fusion@0.2` atau versi terbaru). Kemudian, di awal setiap file modul UI, impor fungsi-fungsi utama Fusion:

```lua
-- Ambil library Fusion dari Packages (jalur mungkin berbeda sedikit)
local Fusion = require(game.ReplicatedStorage.Packages.Fusion)

-- Fungsi-fungsi utama yang sering dipakai
local New = Fusion.New             -- Membuat Instance Roblox baru
local Children = Fusion.Children   -- Menampung anak-anak Instance
local Value = Fusion.Value         -- State lokal yang bisa berubah
local Computed = Fusion.Computed   -- State turunan yang bergantung state lain
local Observer = Fusion.Observer   -- Mengamati perubahan state (mirip useEffect)
local OnEvent = Fusion.OnEvent     -- Menghubungkan ke event Instance (auto disconnect)
local Cleanup = Fusion.Cleanup     -- Menjalankan fungsi saat komponen hancur (auto disconnect)
local Hydrate = Fusion.Hydrate     -- Mengambil Instance yang sudah ada (untuk Coder/Builder UI)
local ForPairs = Fusion.ForPairs   -- Merender daftar item secara dinamis
local ForKeys = Fusion.ForKeys     -- Merender daftar item secara dinamis (tanpa urutan)

-- Ambil OVHL untuk Global State & Networking
local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)
```

### 4.2.1. `Value(initialValue)` (State Lokal)

- **Tujuan:** Membuat _state_ lokal di dalam komponen yang bisa berubah nilainya. Mirip `useState` di React.
- **Penggunaan:**

  ```lua
  local count = Value(0) -- Buat state 'count' dengan nilai awal 0

  local function increment()
      count:set(count:get() + 1) -- Ubah nilai state
  end

  -- Di dalam Render:
  New "TextLabel" { Text = count } -- Otomatis update jika count berubah
  New "TextButton" { Text = "Tambah", [OnEvent "MouseButton1Click"] = increment }
  ```

- **Penting:** Hanya panggil `Value()` di _scope_ teratas fungsi komponen Anda, jangan di dalam _loop_ atau _if_.

### 4.2.2. `Computed(function)` (State Turunan)

- **Tujuan:** Membuat _state_ baru yang nilainya dihitung berdasarkan satu atau lebih _state_ `Value` atau `Computed` lainnya. Otomatis update jika _dependency_-nya berubah.
- **Penggunaan:**

  ```lua
  local health = Value(100)
  local maxHealth = Value(100)

  -- Computed untuk teks persentase
  local healthPercentText = Computed(function()
      local h = health:get()
      local maxH = maxHealth:get()
      return string.format("%.0f%%", (h / maxH) * 100)
  end)

  -- Computed untuk warna
  local healthColor = Computed(function()
      local h = health:get()
      if h < 30 then return Color3.fromRGB(255, 50, 50) else return Color3.fromRGB(50, 255, 50) end
  end)

  -- Di dalam Render:
  New "TextLabel" { Text = healthPercentText, TextColor3 = healthColor }
  ```

- **Penting:** Fungsi di dalam `Computed` **hanya boleh membaca** _state_ lain (`:get()`), **tidak boleh mengubah** _state_ (`:set()`).

### 4.2.3. `Cleanup(function)` (Lifecycle Cleanup)

- **Tujuan:** Menjalankan kode _cleanup_ (seperti `:Disconnect()`, `unsubscribe()`, `task.cancel()`) secara otomatis saat komponen dihancurkan (unmount). Ini adalah cara utama mencegah _memory leak_ di Hooks.
- **Penggunaan:**

  ```lua
  -- Di dalam fungsi komponen
  Cleanup(function()
      print("Komponen MyHUD mulai dibuat...")

      -- Langganan event StateManager
      local unsubCoins = OVHL:Subscribe("coins", function(newCoins) ... end)

      -- Koneksi ke event Roblox
      local connection = player.Chatted:Connect(function(msg) ... end)

      -- Membuat thread
      local myThread = task.spawn(function() while true do task.wait(1) print("Ping") end end)

      -- Kembalikan fungsi cleanup
      return function()
          print("Komponen MyHUD dihancurkan, membersihkan...")
          unsubCoins()            -- Wajib unsubscribe
          connection:Disconnect() -- Wajib disconnect
          task.cancel(myThread)   -- Wajib cancel thread
      end
  end)
  ```

- **Penting:** Panggil `Cleanup()` di _scope_ teratas. Fungsi yang di-_return_ akan dipanggil otomatis.

### 4.2.4. `Observer(state)` (Side Effects / Mirip `useEffect`)

- **Tujuan:** Menjalankan _side effect_ (kode yang berinteraksi dengan dunia luar, seperti network call, logging, atau manipulasi non-Fusion) saat sebuah _state_ berubah.
- **Penggunaan:**

  ```lua
  local selectedItemId = Value(nil)

  -- Observer untuk memuat detail item saat selectedItemId berubah
  local itemDetailsObserver = Observer(selectedItemId)
  itemDetailsObserver:onChange(function(newItemId, oldItemId)
      if newItemId then
          print("Memuat detail untuk item:", newItemId)
          -- Lakukan Invoke ke server untuk ambil detail (bungkus pcall!)
          task.spawn(function()
              local success, result = pcall(OVHL.Invoke, OVHL, "Inventory:GetItemDetails", newItemId)
              if success and result.success then
                  -- Update state lain (misal: state detail item)
              end
          end)
      end
  end)

  -- Observer punya :onDestroy juga untuk cleanup
  itemDetailsObserver:onDestroy(function()
      print("Observer item details dihancurkan.")
  end)

  -- Cleanup observer itu sendiri saat komponen hancur
  Cleanup(function() return function() itemDetailsObserver:destroy() end end)
  ```

- **Penting:** Gunakan `Observer` dengan hati-hati. Lebih baik gunakan `Computed` jika hanya perlu menghitung nilai baru berdasarkan state lain. Gunakan `Observer` hanya jika perlu _side effect_.

### 4.2.5. `OnEvent(instance, eventName)` (Event Roblox)

- **Tujuan:** Cara aman dan deklaratif untuk menghubungkan fungsi ke _event_ Roblox (`MouseButton1Click`, `Touched`, dll). Otomatis disconnect saat komponen hancur.
- **Penggunaan:**
  ```lua
  New "TextButton" {
      Text = "Klik Saya",
      [OnEvent "MouseButton1Click"] = function()
          print("Tombol diklik!")
          -- Lakukan sesuatu, misal:
          -- OVHL:Fire("UI:ButtonClicked", "MyButton")
      end,
      [OnEvent "MouseEnter"] = function() ... end,
      [OnEvent "MouseLeave"] = function() ... end
  }
  ```

### 4.2.6. `Hydrate(instance)` (Untuk Coder/Builder UI)

- **Tujuan:** Mengambil _Instance_ UI yang sudah dibuat oleh Builder di Studio dan menambahkan _logic_ atau _children_ baru ke dalamnya menggunakan Fusion.
- **Penggunaan:**

  - **Builder (Studio):** Buat `ScreenGui` > `Frame` (beri nama "MainFrame") > `TextButton` (beri nama "CloseButton").
  - **Coder (VS Code):**

  ```lua
  -- Di dalam fungsi komponen client
  local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
  local screenGui = playerGui:FindFirstChild("MyBuilderUI") -- Cari UI dari Builder

  if not screenGui then return end -- Handle jika tidak ada

  local function onClose() print("Tombol Close ditekan!") end

  return Hydrate(screenGui) { -- Ambil ScreenGui yang ada
      -- Kita bisa tambahkan elemen baru jika mau
      [Children] = {
          New "TextLabel" { Name = "Title", Text = "Judul dari Kode" }
      },

      -- Kita bisa "menghidupkan" elemen yang sudah ada
      MainFrame = Hydrate(screenGui.MainFrame) { -- Ambil MainFrame
          -- Contoh: Tambah event ke tombol Close di dalamnya
          CloseButton = {
              [OnEvent "MouseButton1Click"] = onClose
          }
      }
  }
  ```

---

## 🏗️ 4.4. TEMPLATE MODUL UI (STANDAR v1 - HOOKS)

Semua modul UI di `src/client/modules/` **WAJIB** mengikuti struktur ini.

```lua
-- File: src/client/modules/MyExampleUI.lua

-- [STANDAR] 1. Ambil OVHL & Library UI (Fusion)
local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)
local Fusion = require(game.ReplicatedStorage.Packages.Fusion)
-- Impor hanya yang dibutuhkan
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Cleanup = Fusion.Cleanup
local OnEvent = Fusion.OnEvent
-- local Hydrate = Fusion.Hydrate -- Jika ini UI Coder/Builder

-- [STANDAR] 2. Komponen adalah FUNGSI (PascalCase) yang return Instance
local function MyExampleUI(props)
    -- props adalah tabel argumen yang dilewatkan saat UI ini ditampilkan

    -- [STANDAR] 3. Definisikan State (Value, Computed) di sini
    local internalCounter = Value(0)
    local message = Value(props.initialMessage or "Halo!")

    -- [STANDAR] 4. Definisikan Helper Functions (jika perlu)
    local function handleButtonClick()
        internalCounter:set(internalCounter:get() + 1)
        OVHL:Fire("UI:ExampleButtonClicked") -- Contoh kirim event ke server
    end

    -- [STANDAR] 5. Gunakan Cleanup untuk koneksi/subscribe
    Cleanup(function()
        local unsubMsg = OVHL:Subscribe("GameMessage", function(newMessage)
            message:set(newMessage)
        end)

        -- Fungsi cleanup
        return function()
            unsubMsg()
        end
    end)

    -- [STANDAR] 6. Render UI menggunakan 'New' atau 'Hydrate'
    return New "ScreenGui" {
        Name = "MyExampleUI",

        [Children] = {
            New "Frame" {
                Size = UDim2.fromOffset(300, 200),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),

                [Children] = {
                    New "TextLabel" {
                        Name = "MessageLabel",
                        Size = UDim2.fromScale(1, 0.5),
                        Text = message -- Ikat ke state 'message'
                    },
                    New "TextButton" {
                        Name = "CounterButton",
                        Size = UDim2.fromScale(1, 0.5),
                        Position = UDim2.fromScale(0, 0.5),
                        Text = Computed(function() -- Ikat ke state 'internalCounter'
                            return "Klik: " .. internalCounter:get()
                        end),
                        [OnEvent "MouseButton1Click"] = handleButtonClick -- Hubungkan event
                    }
                }
            }
        }
    }
end

-- [STANDAR] 7. Definisikan Manifest (WAJIB)
local manifest = {
    name = "MyExampleUI", -- Harus sama dengan nama file
    version = "1.0.0",
    type = "module", -- Tipe 'module' untuk UI
    domain = "ui",
    description = "Contoh UI sederhana dengan Hooks v1"
}

-- [STANDAR] 8. Wrapper 'Create' untuk UIEngine
-- UIEngine akan memanggil fungsi ini saat UI diminta tampil
local function Create(props)
    -- Lakukan validasi props awal di sini jika perlu
    local ui = MyExampleUI(props or {})
    return ui
end

-- [STANDAR] 9. Format return (WAJIB)
return { Create = Create, __manifest = manifest }
```

---

## 🎨 4.5. SISTEM THEMING & DESIGN TOKENS

Kita menggunakan `StateManager` (`OVHL:SetState`, `OVHL:GetState`, `OVHL:Subscribe`) sebagai pusat _state_ tema.

1.  **`ThemeController` (`src/client/controllers/ThemeController.lua`)**:

    - Bertanggung jawab mendefinisikan semua tema (misal: `Dark`, `Light`, `HighContrast`).
    - Menyimpan tema-tema ini di _state_ `Themes` (`OVHL:SetState("Themes", ...)`) saat `:Init()`.
    - Menyimpan tema yang aktif saat ini di _state_ `CurrentTheme` (`OVHL:SetState("CurrentTheme", Themes.Dark)`).
    - Menyediakan fungsi (mungkin via _remote event_ dari Admin Panel atau setting user) untuk mengubah `CurrentTheme`.

2.  **Custom Hook `useTheme()` (`src/shared/lib/hooks/useTheme.lua`)**:

    - Fungsi _hook_ ini membungkus logika `Value()` dan `Cleanup(OVHL:Subscribe("CurrentTheme", ...))` untuk mempermudah komponen UI mendapatkan _state_ tema yang aktif dan reaktif.

3.  **Komponen UI:**
    - Memanggil `local theme = useTheme()` untuk mendapatkan _state_ tema.
    - Menggunakan `Computed()` untuk mengikat properti UI (seperti `BackgroundColor3`, `TextColor3`, `Font`) ke nilai dari `theme:get()`.

**Contoh:**

```lua
-- File: src/shared/lib/hooks/useTheme.lua
local OVHL = require(...)
local Fusion = require(...)
local Value = Fusion.Value
local Cleanup = Fusion.Cleanup

local function useTheme()
    -- Ambil state tema awal, default ke tema kosong jika belum ada
    local theme = Value(OVHL:GetState("CurrentTheme") or {})

    -- Langganan perubahan tema
    Cleanup(function()
        local unsub = OVHL:Subscribe("CurrentTheme", function(newTheme)
            theme:set(newTheme or {}) -- Update state hook
        end)
        return unsub
    end)

    return theme -- Kembalikan state Fusion (Value)
end
return useTheme

-- Di Komponen UI (misal: MyButton.lua)
local Fusion = require(...)
local New, Computed = Fusion.New, Fusion.Computed
local useTheme = require(...) -- Path ke hook

local function MyButton(props)
    local theme = useTheme() -- Gunakan hook

    return New "TextButton" {
        Text = props.text or "Button",

        -- Ikat properti ke state tema via Computed
        BackgroundColor3 = Computed(function()
            -- Ambil warna 'primary' dari tema, fallback ke abu-abu
            return theme:get().primaryColor or Color3.fromRGB(100, 100, 100)
        end),
        TextColor3 = Computed(function()
            return theme:get().textColor or Color3.fromRGB(255, 255, 255)
        end),

        -- ... properti lain ...
    }
end
return MyButton
```

Dengan pola ini, jika `ThemeController` mengubah _state_ `CurrentTheme` (misal dari Dark ke Light), semua komponen yang menggunakan `useTheme` akan otomatis me-render ulang dengan warna/font yang baru.

---

### 🔄 Riwayat Perubahan (Changelog)

| Versi | Tanggal     | Penulis                 | Perubahan                                                                                                                                                                  |
| :---- | :---------- | :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0 | 29 Okt 2025 | OVHL Core Team & Gemini | Rilis awal file detail UI Framework Hooks v1. Dibuat dari hasil split `00_MASTER_BLUEPRINT_v1.md`. Menjelaskan filosofi, API Fusion, template standar, dan sistem theming. |
