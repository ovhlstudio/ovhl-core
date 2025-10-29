# ❓ 10 - TROUBLESHOOTING & FAQ (v1)

### 📋 INFORMASI DOKUMEN

| Properti           | Nilai                                        |
| ------------------ | -------------------------------------------- |
| **ID Dokumen**     | `ARC-v1-010`                                 |
| **Status**         | `Aktif (Rilis Baru)`                         |
| **Lokasi Path**    | `./docs/blueprint/10_TROUBLESHOOTING_FAQ.md` |
| **Tipe Dokumen**   | `Panduan Pemecahan Masalah`                  |
| **Target Audiens** | `All Developers, AI Assistant`               |
| **Relasi**         | `Index: 00_MASTER_INDEX.md`, `Ref: 01-09`    |
| **Penulis**        | `OVHL Core Team (Direvisi oleh Gemini)`      |
| **Dibuat**         | `29 Oktober 2025`                            |

---

## 📖 PENGANTAR

Dokumen ini berisi daftar pertanyaan yang sering diajukan (FAQ) dan solusi untuk masalah umum yang mungkin Anda temui saat mengembangkan game menggunakan OVHL Core v1. Sebelum bertanya di channel support, coba cari solusi Anda di sini terlebih dahulu.

---

## 📁 KATEGORI MASALAH

1.  [Setup & Workflow](#setup-workflow)
2.  [Auto-Discovery & Loading](#auto-discovery-loading)
3.  [Dependency Injection (DI)](#dependency-injection-di)
4.  [UI Framework (Hooks/Fusion)](#ui-framework-hooks)
5.  [Coder/Builder Workflow](#coderbuilder-workflow)
6.  [Networking (Remotes)](#networking-remotes)
7.  [Error Handling ("No Crash")](#error-handling-no-crash)
8.  [Performa](#performa)

---

## <a name="setup-workflow"></a> 🛠️ 1. SETUP & WORKFLOW

**Q: Saya dapat error "HttpError: Unauthenticated" atau "Connect failed" dari Rojo.**
**A:**

1.  **Pastikan `rojo serve default.project.json` sedang berjalan** di terminal VS Code Anda, di _root_ folder proyek.
2.  Pastikan **plugin Rojo** di Roblox Studio sudah **terbaru** dan **aktif**.
3.  Coba **restart** `rojo serve` (Ctrl+C di terminal, lalu jalankan lagi) dan **restart** Roblox Studio.
4.  Pastikan tidak ada **firewall** atau antivirus yang memblok koneksi _localhost_ pada port yang digunakan Rojo (biasanya 34872).
5.  Pastikan **hanya ada satu instance** `rojo serve` yang berjalan untuk proyek ini.

**Q: File saya di VS Code tidak muncul/update di Roblox Studio.**
**A:**

1.  Pastikan **Rojo terkoneksi** di plugin Roblox Studio (status "Connected"). Jika tidak, klik "Disconnect" lalu "Connect" lagi.
2.  Pastikan Anda **menyimpan file** (Ctrl+S) di VS Code. Rojo hanya sinkronisasi saat file disimpan.
3.  Pastikan file yang Anda edit berada **di dalam folder `src/`** dan _path_-nya sudah benar terdaftar di `default.project.json`.
4.  Cek **output terminal** tempat `rojo serve` berjalan. Apakah ada pesan error saat sinkronisasi?
5.  Coba **restart** `rojo serve`.

**Q: Perintah `wally install` gagal.**
**A:**

1.  Pastikan **Wally sudah terinstal** di sistem Anda (cek dengan `wally --version`). Jika belum, ikuti panduan instalasi Wally.
2.  Pastikan Anda menjalankan `wally install` di **folder _root_ proyek** (folder yang berisi `wally.toml`).
3.  Cek file `wally.toml`. Pastikan formatnya benar dan nama _package_ di `[dependencies]` sudah benar (nama vendor/nama package).
4.  Pastikan Anda memiliki **koneksi internet** untuk men-download _package_.
5.  Coba hapus folder `Packages/` dan file `wally.lock` (jika ada), lalu jalankan `wally install` lagi.

**Q: Saya mengedit _script_ di Studio, tapi hilang saat Play Test!**
**A:** **JANGAN PERNAH** mengedit _script_ di dalam folder yang dikelola Rojo (`OVHL_Server`, `OVHL_Client`, `OVHL_Shared`, `Packages`). VS Code adalah _Source of Truth_. Perubahan Anda di Studio akan selalu ditimpa oleh Rojo saat Anda menyimpan file di VS Code.

---

## <a name="auto-discovery-loading"></a> 🔥 2. AUTO-DISCOVERY & LOADING

**Q: Modul / Service / Controller / Component saya tidak ter-load! Tidak ada di log Auto-Discovery!**
**A:** 99% masalah ada di `__manifest` atau lokasi file. Cek:

1.  **Lokasi File:** Pastikan file `.lua` Anda berada di folder yang benar sesuai tipenya:
    - `service`: `src/server/services/`
    - `controller`: `src/client/controllers/`
    - `module` (Server): `src/server/modules/`
    - `module` (Client UI): `src/client/modules/`
    - `component` (Coder/Builder): `src/shared/components/`
2.  **`__manifest` Ada:** Pastikan ada tabel `__manifest` di dalam file.
3.  **`name` Cocok:** Pastikan `__manifest.name` (string) **sama persis** dengan nama file (Case-Sensitive). Misal: file `ShopModule.lua` harus punya `name = "ShopModule"`.
4.  **`type` Benar:** Pastikan `__manifest.type` (string) diisi dengan benar: `service`, `controller`, `module`, atau `component`.
5.  **Syntax Error:** Cek Output Studio saat startup. Jika ada _syntax error_ di file modul Anda, _loader_ mungkin gagal membacanya. Gunakan Selene Linter di VS Code untuk menangkap _error_ lebih awal.
6.  **`autoload = false`?** Cek apakah Anda tidak sengaja menambahkan `autoload = false` di `__manifest`.

**Q: Saya dapat error "Missing dependency 'NamaService'" saat startup (Fail Fast).**
**A:** Ini berarti ada modul yang `__manifest.dependencies`-nya meminta `NamaService`, tapi:

1.  **Typo:** Anda salah ketik nama dependensi di `__manifest.dependencies` (harus `PascalCase` dan sama persis dengan `name` service/modul yang dibutuhkan).
2.  **Service Belum Dibuat:** File untuk `NamaService.lua` belum ada atau belum punya `__manifest` yang valid.
3.  **Lokasi Salah:** File `NamaService.lua` ada tapi di folder yang salah (misal: service ada di `modules/`).
4.  **Circular Dependency:** Terjadi dependensi melingkar (A butuh B, B butuh A). `DependencyResolver` akan mendeteksi ini dan error. Perbaiki desain dependensi Anda.

**Q: Modul saya di-:Init() tapi tidak di-:Start().**
**A:** Kemungkinan besar fungsi `:Init()` Anda me-_return_ `false` atau `nil`. Framework hanya akan memanggil `:Start()` jika `:Init()` me-_return_ `true`. Cek logika di `:Init()` Anda dan pastikan `return true` jika sukses.

---

## <a name="dependency-injection-di"></a> 💉 3. DEPENDENCY INJECTION (DI)

**Q: Service yang saya minta di `dependencies` nilainya `nil` di `:Init()` atau `:Start()`.**
**A:**

1.  **Lupa Implementasi `:Inject()`:** Pastikan Anda sudah membuat fungsi `:Inject(services)` di modul Anda.
2.  **Lupa Menyimpan ke `self`:** Di dalam `:Inject(services)`, pastikan Anda menyimpan _service_ yang diterima ke `self`. Contoh: `self.logger = services.Logger`.
3.  **Typo di `dependencies`:** Pastikan nama di `__manifest.dependencies` sama persis dengan `name` _service_ yang dituju.
4.  **Service Gagal Load:** Cek log startup. Jika _service_ yang Anda butuhkan gagal di-load (karena error di `:Init`-nya atau dependensi dia sendiri hilang), maka _service_ itu tidak akan di-_inject_.

**Q: Fungsi `:Inject()` saya tidak pernah dipanggil.**
**A:**

1.  **Tidak Ada `dependencies`:** Fungsi `:Inject()` hanya dipanggil jika `__manifest.dependencies` berisi setidaknya satu nama _service_/modul. Jika modul Anda tidak butuh apa-apa, `:Inject()` memang tidak akan dipanggil (dan tidak perlu dibuat).
2.  **Modul Gagal Validasi:** Jika `__manifest` modul Anda sendiri tidak valid, proses _loading_ berhenti sebelum `:Inject()` dipanggil. Cek log startup.

---

## <a name="ui-framework-hooks"></a> 🎨 4. UI FRAMEWORK (HOOKS/FUSION)

**Q: Komponen UI saya tidak muncul / tidak render.**
**A:**

1.  **Manifest & Export:** Pastikan file modul UI Anda (`src/client/modules/NamaUI.lua`) memiliki `__manifest` dengan `type = "module"` dan me-_return_ tabel format `{ Create = function, __manifest = manifest }`.
2.  **Pemanggilan Tampil:** Pastikan ada kode lain (misal: di _controller_ atau modul UI lain) yang memanggil `UIController:ShowScreen("NamaUI", props)` atau _logic_ yang me-mount komponen tersebut.
3.  **Error di Fungsi Komponen:** Cek Output Client. Jika ada _error_ di dalam fungsi komponen Anda (saat _render_ awal atau _update_), Fusion mungkin berhenti merender. Bungkus bagian _logic_ yang rumit dengan `pcall` jika perlu _debug_.
4.  **Return Instance:** Pastikan fungsi komponen Anda selalu me-_return_ satu _Instance_ Roblox (hasil dari `New` atau `Hydrate`). Jangan me-_return_ `nil` kecuali memang sengaja (kondisional render).
5.  **Properti Salah:** Pastikan nama properti yang Anda set di `New "Frame" { ... }` valid untuk tipe _Instance_ tersebut.

**Q: State (Value) saya berubah (`:set()`), tapi UI tidak update.**
**A:**

1.  **Ikatan (Binding) Lupa:** Pastikan properti UI yang seharusnya update benar-benar **terikat** ke _state_ `Value` atau `Computed`. Contoh yang **SALAH**: `Text = myValue:get()`. Contoh yang **BENAR**: `Text = myValue` (jika `myValue` adalah `Value`) atau `Text = Computed(function() return "Nilai: " .. myValue:get() end)`.
2.  **Mutasi Langsung (SALAH):** Jangan pernah mengubah isi tabel atau objek _secara langsung_ jika tabel/objek itu disimpan di dalam `Value`. Fusion tidak akan mendeteksi perubahan _internal_. Buat tabel/objek baru saat `:set()`.
    - **SALAH:** `local tbl = Value({a=1}); local internal = tbl:get(); internal.a = 2; tbl:set(internal)`
    - **BENAR:** `local tbl = Value({a=1}); tbl:set({a = 2})`

**Q: Saya dapat error "Attempt to disconnect disconnected connection" atau memory leak.**
**A:** Ini biasanya karena lupa _cleanup_.

1.  **Gunakan `Cleanup(function)`:** Untuk semua langganan _event_ (`OVHL:Subscribe`, `:Connect`) atau _thread_ (`task.spawn`), **WAJIB** gunakan `Cleanup` dan kembalikan fungsi _disconnect/unsubscribe/cancel_ di dalamnya.
2.  **Gunakan `OnEvent`:** Untuk event _Instance_ Roblox di dalam UI, **utamakan** menggunakan `[OnEvent "EventName"] = function` karena otomatis _cleanup_.
3.  **Hindari Koneksi Manual di Luar Cleanup:** Jangan melakukan `:Connect()` biasa di _scope_ utama fungsi komponen tanpa mekanisme _cleanup_ yang jelas.

---

## <a name="coderbuilder-workflow"></a> 🧩 5. CODER/BUILDER WORKFLOW

**Q: Komponen Coder/Builder saya (`:Knit`) tidak dipanggil.**
**A:**

1.  **Manifest Komponen:** Pastikan file di `src/shared/components/` memiliki `__manifest` dengan `type = "component"` dan `name` yang benar.
2.  **Tagging di Studio:** Pastikan _Instance_ di Studio sudah diberi **Atribut** `ovhl:component` (String) dengan _value_ yang **sama persis** (Case-Sensitive) dengan `__manifest.name`, ATAU diberi **Tag CollectionService** `OVHL:<NamaKomponen>`.
3.  **`ComponentService` Aktif:** Pastikan `ComponentService` (Core Service Server) ter-load dengan benar (cek log startup).
4.  **Lokasi Instance:** `ComponentService` secara default hanya scan `workspace` dan `PlayerGui` (client). Jika _Instance_ Anda ada di tempat lain (misal: `ReplicatedStorage`), `ComponentService` tidak akan menemukannya kecuali dikonfigurasi ulang.
5.  **Error di `:Knit`:** Cek Output. Jika ada error di dalam `:Knit` itu sendiri (terutama sebelum `print` debug), komponen mungkin gagal aktif. Bungkus `:Knit` dengan `pcall` jika perlu _debug_.

**Q: Atribut `ovhl:xxx` yang saya set di Studio nilainya `nil` di `:Knit(instance, attributes)`.**
**A:**

1.  **Nama Atribut:** Pastikan nama Atribut di Studio **diawali `ovhl:`** (contoh: `ovhl:damage`). Di tabel `attributes`, _prefix_ `ovhl:` ini akan dihilangkan (menjadi `attributes.damage`).
2.  **Tipe Data:** Pastikan tipe data Atribut di Studio sesuai dengan yang diharapkan kode Anda (Number, String, Boolean, dll).
3.  **Case Sensitive:** Nama Atribut (setelah `ovhl:`) bersifat _case sensitive_. `ovhl:Damage` akan menjadi `attributes.Damage`, bukan `attributes.damage`. Sesuaikan di kode Anda.

**Q: Fungsi `:Destroy()` tidak dipanggil saat Part hilang.**
**A:**

1.  **Instance Hilang Tiba-tiba:** Jika Part dihapus secara paksa (`instance:Destroy()`) tanpa event `Destroying` sempat ter-trigger dengan benar, `:Destroy()` mungkin tidak terpanggil. Ini jarang terjadi.
2.  **Error di `ComponentService`:** Jika ada error internal di `ComponentService`, _cleanup_ mungkin gagal. Cek log server.
3.  **Kode Anda Tidak Menyimpan Koneksi:** Pastikan Anda benar-benar menyimpan koneksi `Destroying` jika Anda mengelolanya secara manual (seharusnya tidak perlu jika pakai `ComponentService`).

---

## <a name="networking-remotes"></a> 🔐 6. NETWORKING (REMOTES)

**Q: `OVHL:Invoke` atau `OVHL:Fire` gagal / error.**
**A:**

1.  **Schema Tidak Cocok:** Ini penyebab paling umum di v1. Pastikan:
    - `remoteName` yang Anda panggil **ada** sebagai _key_ di `src/shared/NetworkSchema.lua`.
    - **Jumlah argumen** yang Anda kirim **sama persis** dengan yang didefinisikan di _schema_ `t.tuple(...)`.
    - **Tipe data setiap argumen** **sama persis** dengan yang didefinisikan (string, integer, number, boolean, Vector3, instanceIsA, optional, dll). Perhatikan `integer` vs `number`.
    - Cek **Output Client dan Server** untuk pesan error validasi _schema_.
2.  **Rate Limit Terlampaui:** Jika Anda memanggil _remote_ terlalu sering, server akan menolaknya. Client akan menerima error "Rate limit exceeded". Kurangi frekuensi panggilan atau minta Core Team menyesuaikan _limit_ via `ConfigService`.
3.  **Handler Belum Terdaftar:** Pastikan di sisi Server, modul yang bertanggung jawab sudah memanggil `RemoteManager:RegisterHandler("NamaRemote", function...)`. Cek log startup server.
4.  **Error di Handler Server:** Jika _handler_ di server error (dan tidak dibungkus `pcall` dengan benar), `Invoke` di client akan error. Cek log **Server**.
5.  **Error Jaringan / Server Down:** Bungkus `OVHL:Invoke` dengan `pcall` di client untuk menangani ini.

**Q: Saya yakin Schema dan argumen sudah benar, tapi masih error validasi.**
**A:**

1.  **Periksa `t` Library:** Pastikan library `t` dari Wally sudah terinstal dan versi kompatibel.
2.  **Nilai `nil`:** Jika _schema_ tidak mengizinkan `optional`, mengirim `nil` akan gagal. Gunakan `t.optional(tipe)` jika `nil` diizinkan.
3.  **Perbedaan `Instance`:** Schema `t.instanceIsA("ClassName")` mengecek _class_ Roblox. Pastikan argumennya benar-benar _instance_ dari kelas tersebut.
4.  **Reload Schema:** Jika Anda baru mengubah `NetworkSchema.lua`, pastikan server di-_restart_ agar `RemoteManager` memuat versi terbaru.

---

## <a name="error-handling-no-crash"></a> ⚠️ 7. ERROR HANDLING ("NO CRASH")

**Q: Game saya freeze atau tidak responsif, tapi tidak ada error merah di Output.**
**A:** Ini bisa jadi _infinite loop_ atau _deadlock_.

1.  **Cek Loop:** Periksa `while true do` atau `repeat until` Anda. Pastikan **selalu** ada `task.wait()` atau kondisi keluar yang pasti tercapai.
2.  **Cek Event Rekursif:** Apakah ada `OVHL:Emit` yang secara tidak sengaja memicu _handler_ yang nge-`Emit` event yang sama lagi?
3.  **Cek `Invoke` Berantai:** Hindari pola Client A `Invoke` Server, lalu Server `Invoke` Client A lagi dalam proses yang sama. Ini bisa menyebabkan _deadlock_. Gunakan `Fire` jika tidak perlu balasan langsung.

**Q: Modul saya gagal load secara _graceful_, tapi saya tidak tahu kenapa.**
**A:**

1.  **Cek Log Server:** Saat modul gagal `:Init()` (return `false`), framework akan mencatat log `WARN` atau `ERROR` dengan nama modul. Cari log tersebut saat startup.
2.  **Tambahkan Logging di `:Init()`:** Taruh `self.logger:Info("Tahap X...")` di dalam `:Init()` Anda untuk melihat sampai mana eksekusi berjalan sebelum gagal. Pastikan `Logger` sudah di-_inject_ dengan benar.
3.  **Cek Dependensi:** Apakah ada _service_ yang Anda panggil di `:Init()` yang mungkin belum siap atau _error_?

**Q: Kenapa `pcall` wajib dipakai di mana-mana? Kodenya jadi ramai.**
**A:** Ini adalah **inti filosofi "No Crash"**.

- Satu _error_ tak terduga di _handler event_ atau _remote_ bisa menghentikan _thread_ tersebut dan berpotensi merusak _state_ game atau bahkan menghentikan _script_ lain.
- `pcall` memastikan _error_ terisolasi, bisa dicatat dengan baik oleh `Logger`, dan _script_ lain bisa terus berjalan. Ini krusial untuk stabilitas game _live_.
- Anggap `pcall` sebagai "jaring pengaman" wajib untuk semua interaksi antar modul atau dengan dunia luar (network, datastore).

---

## <a name="performa"></a> ⚡ 8. PERFORMA

**Q: Game saya terasa lag / FPS drop.**
**A:** Ini topik luas, tapi beberapa area umum di OVHL v1:

1.  **UI Hooks (Fusion):**
    - **Terlalu Banyak `Computed` Kompleks:** Hindari komputasi berat di dalam `Computed`. Jika perlu, lakukan komputasi di _background thread_ dan simpan hasilnya di `Value`.
    - **Render List Panjang Tanpa Optimasi:** Gunakan `ForPairs` atau `ForKeys` dari Fusion untuk merender daftar. Jika daftarnya sangat besar, pertimbangkan _virtual scrolling_ (merender hanya item yang terlihat).
    - **Terlalu Sering `:set()`:** Hindari mengubah _state_ `Value` berkali-kali dalam satu _frame_ jika tidak perlu.
2.  **Coder/Builder Komponen:**
    - **Logic di `:Knit` Terlalu Berat:** Jangan lakukan operasi mahal (network, loop besar) di `:Knit`. Lakukan di _background thread_ jika perlu.
    - **Terlalu Banyak Komponen Aktif:** Jika ada ribuan komponen Coder/Builder aktif (misal: koin berputar), pastikan _logic_ per komponen sangat ringan. Pertimbangkan menonaktifkan _logic_ komponen yang jauh dari pemain.
3.  **Networking:**
    - **Terlalu Banyak `Invoke`:** Ganti ke `Fire` jika tidak perlu balasan langsung.
    - **Payload Terlalu Besar:** Jangan kirim data yang tidak perlu via _remote_. Kirim ID, biarkan sisi lain mengambil detailnya jika perlu.
4.  **EventBus:**
    - **Terlalu Banyak `Emit` per Frame:** Hindari `Emit` di dalam _loop_ yang berjalan setiap _frame_.
    - **Handler `Subscribe` Lambat:** Pastikan logika di _handler_ `Subscribe` cepat dan tidak memblok _thread_. Gunakan `task.spawn` jika perlu operasi lama.
5.  **Memory Leak:** Pastikan semua koneksi (`:Connect`, `OVHL:Subscribe`) di-_disconnect_/_unsubscribe_ saat tidak lagi diperlukan (gunakan `Cleanup` di UI Hooks, `:Destroy` di Komponen). Gunakan _MicroProfiler_ dan _Developer Console_ untuk memantau memori.

**Tools Debug Performa:**

- **Roblox MicroProfiler (Ctrl+F6):** Alat utama untuk melihat _bottleneck_ di _script_ Anda.
- **Developer Console (F9):** Pantau _Script Performance_, _Memory Usage_, dan _Network Traffic_.
- **Log dari `NetworkMonitorService`:** Analisa _latency_ dan frekuensi _remote call_.

---

## 🆘 9. MEMINTA BANTUAN

Jika Anda sudah mencoba solusi di FAQ ini dan masih mengalami masalah:

1.  **Kumpulkan Informasi:**
    - **Deskripsi Masalah:** Jelaskan apa yang terjadi, apa yang Anda harapkan, dan langkah-langkah untuk mereproduksi masalah.
    - **Pesan Error:** Salin **teks lengkap** pesan error dari Output Studio (Client dan Server).
    - **Kode Relevan:** Siapkan potongan kode yang terkait dengan masalah (misal: `__manifest`, fungsi `:Inject`/`:Init`/`:Start`, _handler_ event/remote, komponen UI).
    - **Log:** Jika ada log relevan dari `Logger`, sertakan juga.
2.  **Tanyakan di Channel Support:** Sampaikan informasi di atas di channel Discord atau platform komunikasi tim yang sesuai.

Semakin lengkap informasi yang Anda berikan, semakin cepat tim bisa membantu!

---

### 🔄 Riwayat Perubahan (Changelog)

| Versi | Tanggal     | Penulis                 | Perubahan                                                                                                                            |
| :---- | :---------- | :---------------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0 | 29 Okt 2025 | OVHL Core Team & Gemini | Rilis awal file detail Troubleshooting & FAQ v1. Dibuat dari nol berdasarkan potensi masalah umum dari arsitektur OVHL v1 yang baru. |
