# 🗺️ OVHL ROADMAP - FULL STACK DEVELOPMENT

> AI Generate Code → run.sh sebagai kurir → Developer Execute

### **PROTOCOL RUN.SH:**

1. **AI selalu kasih run.sh lengkap** dengan semua code yang needed
2. **Developer cuma execute 1 command:** `bash ./lokal/tools/run.sh`
3. **run.sh handle semua:** validation, backup, deployment, verification
4. **No manual copy-paste code**, no manual file creation
5. Backup File : ./lokal/backups
6. Test File Untuk Di Copy Ke Studio ada di folder ./test/[sesuaikan foldernya]

### **STRUCTURE RUN.SH:**

```bash
#!/bin/bash
# ============================================
# OVHL-XXX: Task Name
# Anti-Human-Error Deployment
# ============================================

# PHASE 1: ENVIRONMENT VALIDATION
# - Cek project structure
# - Validate dependencies

# PHASE 2: BACKUP & PREPARATION
# - Backup existing files location ./lokal/backups
# - Create necessary directories
# - Create Test File Studio ./test/[client / server / shared]

# PHASE 3: DEPLOYMENT
# - Deploy ALL needed files atau task sekaligus
# - Include proper error handling

# PHASE 4: VERIFICATION
# - Verify files created
# - Basic syntax check
# - Generate test commands

echo "🎉 Task OVHL-XXX COMPLETED!"
echo "📝 Next: Update AI_DEV_LOG.md"
echo "kasih pesan kepada dev, apa yang harus dilakukan, play studio lihat output atau apa"
```

> **STRATEGI:** Bootstrap First → Foundation → Features → Polish

---

## 🎯 PRINSIP PENGEMBANGAN

1. **BOOTSTRAP FIRST**: Bikin sistem yang bisa auto-detect module dulu
2. **FOUNDATION SECOND**: Bikin core services yang semua butuhkan
3. **FEATURES THIRD**: Bikin game modules & UI
4. **POLISH LAST**: Optimasi & tooling

---

## 📊 CURRENT STATUS

**Phase:** 🔨 BOOTSTRAP (100% Complete)  
**Next Task:** OVHL-B001 (LoggerService)  
**Blocked Tasks:** All (waiting for bootstrap)

---

## ⚡ FASE 0: BOOTSTRAP (Foundation Layer) [DONE]

**Tujuan:** Bikin sistem auto-discovery & lifecycle management

### Why Bootstrap First?

Karena SEMUA module lainnya akan di-load via sistem ini. Kalau bootstrap belum ada, kita harus manual require everything (anti-pattern).

### 📋 TASKS:

#### **OVHL-B001**: LoggerService ⭐ START HERE

- **File:** `src/server/services/LoggerService.lua`
- **Dependencies:** NONE (Pure Lua)
- **Description:** Structured logging dengan level (Debug, Info, Warn, Error)
- **Features:**
  - Log levels filtering
  - Timestamp formatting
  - Context tracking (module name, etc)
  - Output to console & file (future)
- **Success Criteria:**
  - Can log with different levels
  - Can filter logs by level
  - Can add context to logs
- **Blockers:** NONE ✅ READY TO START

---

#### **OVHL-B002**: DependencyResolver

- **File:** `src/server/services/DependencyResolver.lua`
- **Dependencies:** Logger
- **Description:** Resolve dependency graph & calculate load order
- **Features:**
  - Parse `__manifest.dependencies`
  - Detect circular dependencies (fail fast)
  - Topological sort for load order
  - Priority-based ordering
- **Success Criteria:**
  - Can detect circular dependencies
  - Can calculate correct load order
  - Respects priority field
- **Blockers:** OVHL-B001

---

#### **OVHL-B003**: init.server.lua (Server Bootstrap)

- **File:** `src/server/init.server.lua`
- **Dependencies:** Logger, DependencyResolver
- **Description:** Server startup & auto-discovery orchestrator
- **Features:**
  - Manual load Logger & DependencyResolver
  - Auto-scan `services/` folder
  - Auto-scan `modules/` folder
  - Validate `__manifest` for each
  - Create instances in dependency order
  - Call lifecycle methods (:Inject, :Init, :Start)
  - Error handling (Fail Fast vs Fail Graceful)
- **Success Criteria:**
  - Server starts without errors
  - Services auto-discovered and loaded
  - Modules auto-discovered and loaded
  - Dependency order respected
  - Errors logged properly
- **Blockers:** OVHL-B001, OVHL-B002

---

#### **OVHL-B004**: init.client.lua (Client Bootstrap)

- **File:** `src/client/init.client.lua`
- **Dependencies:** Logger (client copy), DependencyResolver (client copy)
- **Description:** Client startup & auto-discovery orchestrator
- **Features:**
  - Same as server but for controllers/
  - Auto-scan `controllers/` folder
  - Auto-scan `modules/` folder (client UI modules)
- **Success Criteria:**
  - Client starts without errors
  - Controllers auto-discovered
  - Client modules auto-discovered
- **Blockers:** OVHL-B001, OVHL-B002

---

#### **OVHL-B005**: OVHL_Global.lua (API Accessor)

- **File:** `src/shared/OVHL_Global.lua`
- **Dependencies:** Logger
- **Description:** Global API `_G.OVHL` untuk akses services/modules
- **Features:**
  - `OVHL:GetService(name)`
  - `OVHL:GetModule(name)`
  - `OVHL:GetConfig(name)`
  - `OVHL:Emit(event, ...)`
  - `OVHL:Subscribe(event, callback)`
  - `OVHL:Fire(remote, ...)` (client)
  - `OVHL:Invoke(remote, ...)` (client)
- **Success Criteria:**
  - Can access services by name
  - Can access modules by name
  - API consistent between server/client
- **Blockers:** OVHL-B003, OVHL-B004

---

### ✅ FASE 0 SUCCESS CRITERIA (ALL MUST PASS):

1. ✅ Server dapat startup tanpa error
2. ✅ Client dapat startup tanpa error
3. ✅ Logger berfungsi di server & client
4. ✅ Auto-discovery scan folders (services/, modules/, controllers/)
5. ✅ Dependency resolution berfungsi (no circular deps)
6. ✅ Lifecycle methods dipanggil dengan urutan benar
7. ✅ `_G.OVHL` tersedia dan berfungsi
8. ✅ Error handling (Fail Fast untuk critical, Fail Graceful untuk features)

### 🚀 OUTPUT FASE 0:

```
📦 src/
├── 📁 server/
│   ├── 📄 init.server.lua          ✅ WORKS
│   └── 📁 services/
│       ├── 📄 LoggerService.lua    ✅ WORKS
│       └── 📄 DependencyResolver.lua ✅ WORKS
│
├── 📁 client/
│   ├── 📄 init.client.lua          ✅ WORKS
│   └── 📁 controllers/
│       ├── 📄 LoggerService.lua    ✅ WORKS (copy)
│       └── 📄 DependencyResolver.lua ✅ WORKS (copy)
│
└── 📁 shared/
    └── 📄 OVHL_Global.lua          ✅ WORKS
```

**AFTER FASE 0:** Semua module baru tinggal taruh di folder yang bener, auto-detect!

---

## 🏗️ FASE 1: CORE SERVICES (Foundation)

**Tujuan:** Services yang SEMUA module butuhkan

**BLOCKED UNTIL:** Fase 0 complete

### 📋 TASKS:

#### **OVHL-001**: ConfigService

- **File:** `src/server/services/ConfigService.lua`
- **Dependencies:** Logger
- **Description:** Manage game configuration (default & live)
- **Features:**
  - Read `__config` from modules
  - Get/Set config by module name
  - Emit "ConfigChanged" events
  - Admin panel integration (future)
- **Manifest:**
  ```lua
  name = "ConfigService"
  version = "1.0.0"
  type = "service"
  dependencies = {"Logger"}
  priority = 70
  ```
- **Blockers:** OVHL-B003

---

#### **OVHL-002**: EventBusService

- **File:** `src/server/services/EventBusService.lua`
- **Dependencies:** Logger
- **Description:** Internal pub/sub (server-only)
- **Features:**
  - Emit(eventName, ...)
  - Subscribe(eventName, callback) → unsubscribe function
  - Wildcard subscriptions (optional)
  - Event history (debug mode)
- **Manifest:**
  ```lua
  name = "EventBusService"
  version = "1.0.0"
  type = "service"
  dependencies = {"Logger"}
  priority = 70
  ```
- **Blockers:** OVHL-B003

---

#### **OVHL-003**: DataService

- **File:** `src/server/services/DataService.lua`
- **Dependencies:** Logger, ConfigService
- **Description:** DataStore wrapper dengan session lock
- **Features:**
  - Get/Set player data
  - Auto-save interval
  - Session locking
  - Retry logic
  - Data migration support
- **Manifest:**
  ```lua
  name = "DataService"
  version = "1.0.0"
  type = "service"
  dependencies = {"Logger", "ConfigService"}
  priority = 60
  ```
- **Blockers:** OVHL-001

---

### ✅ FASE 1 SUCCESS CRITERIA:

1. ConfigService dapat load/save config
2. EventBusService dapat emit/subscribe
3. DataService dapat save/load player data
4. Semua service ter-auto-discover
5. No manual registration needed

---

## 🌐 FASE 2: NETWORKING (Client ↔ Server)

**Tujuan:** Safe & fast client-server communication

**BLOCKED UNTIL:** Fase 1 complete

### 📋 TASKS:

#### **OVHL-004**: NetworkSchema.lua

- **File:** `src/shared/NetworkSchema.lua`
- **Dependencies:** NONE (Pure schema)
- **Description:** Validation schema untuk RemoteManager
- **Features:**
  - Define types untuk setiap remote
  - Use 't' library for validation
  - Type definitions (string, number, boolean, etc)
- **Example:**
  ```lua
  NetworkSchema = {
      ["Shop:BuyItem"] = {
          t.string, -- itemName
          t.integer -- quantity
      }
  }
  ```
- **Blockers:** OVHL-B005

---

#### **OVHL-005**: RemoteManagerService

- **File:** `src/server/services/RemoteManagerService.lua`
- **Dependencies:** Logger, EventBus, NetworkSchema
- **Description:** Server-side remote handler
- **Features:**
  - RegisterHandler(remoteName, handler)
  - FireClient(player, remoteName, ...)
  - FireAllClients(remoteName, ...)
  - Middleware: Schema validation
  - Middleware: Rate limiting
  - Middleware: Error handling
- **Manifest:**
  ```lua
  name = "RemoteManagerService"
  version = "1.0.0"
  type = "service"
  dependencies = {"Logger", "EventBusService", "NetworkSchema"}
  priority = 50
  ```
- **Blockers:** OVHL-002, OVHL-004

---

#### **OVHL-006**: RemoteClient

- **File:** `src/client/controllers/RemoteClient.lua`
- **Dependencies:** Logger (client), NetworkSchema
- **Description:** Client-side remote caller
- **Features:**
  - Fire(remoteName, ...)
  - Invoke(remoteName, ...) → Promise
  - Listen(remoteName, callback)
  - Error handling & retry
- **Manifest:**
  ```lua
  name = "RemoteClient"
  version = "1.0.0"
  type = "controller"
  dependencies = {"Logger"}
  priority = 70
  ```
- **Blockers:** OVHL-B004, OVHL-004

---

### ✅ FASE 2 SUCCESS CRITERIA:

1. Client dapat Fire/Invoke ke server
2. Server dapat FireClient/FireAllClients
3. Schema validation aktif
4. Rate limiting mencegah spam
5. Errors handled gracefully

---

## 🎨 FASE 3: UI FRAMEWORK (Client)

**Tujuan:** Reactive UI dengan Fusion

**BLOCKED UNTIL:** Fase 2 complete

### 📋 TASKS:

#### **OVHL-007**: Fusion Integration (Wally)

- **File:** `wally.toml` → `src/shared/lib/fusion/`
- **Dependencies:** External (Wally package)
- **Description:** Install Fusion via Wally
- **Commands:**
  ```bash
  wally install
  rojo build
  ```
- **Blockers:** OVHL-B004

---

#### **OVHL-008**: StateManager

- **File:** `src/client/controllers/StateManager.lua`
- **Dependencies:** Logger (client), Fusion
- **Description:** Global UI state management
- **Features:**
  - Create reactive states (Fusion.Value)
  - Computed states (Fusion.Computed)
  - State persistence (optional)
- **Manifest:**
  ```lua
  name = "StateManager"
  version = "1.0.0"
  type = "controller"
  dependencies = {"Logger"}
  priority = 60
  ```
- **Blockers:** OVHL-007

---

#### **OVHL-009**: UIEngine

- **File:** `src/client/controllers/UIEngine.lua`
- **Dependencies:** Logger (client), StateManager, Fusion
- **Description:** UI component manager
- **Features:**
  - Mount/Unmount UI components
  - Component lifecycle
  - Props & state management
- **Manifest:**
  ```lua
  name = "UIEngine"
  version = "1.0.0"
  type = "controller"
  dependencies = {"Logger", "StateManager"}
  priority = 50
  ```
- **Blockers:** OVHL-008

---

#### **OVHL-010**: ThemeController

- **File:** `src/client/controllers/ThemeController.lua`
- **Dependencies:** StateManager
- **Description:** Theme system (light/dark mode)
- **Features:**
  - Define theme colors
  - Switch theme at runtime
  - Reactive theme changes
- **Manifest:**
  ```lua
  name = "ThemeController"
  version = "1.0.0"
  type = "controller"
  dependencies = {"StateManager"}
  priority = 40
  ```
- **Blockers:** OVHL-008

---

### ✅ FASE 3 SUCCESS CRITERIA:

1. Fusion ter-import dengan benar
2. StateManager dapat create reactive states
3. UIEngine dapat mount/unmount components
4. Theme switching work
5. UI reactive to state changes

---

## 🧪 FASE 4: TEST MODULES (Validation)

**Tujuan:** End-to-end test full stack

**BLOCKED UNTIL:** Fase 3 complete

### 📋 TASKS:

#### **MOD-001**: TestService

- **File:** `src/server/modules/TestService.lua`
- **Dependencies:** Logger, EventBusService, RemoteManagerService
- **Description:** Server test module
- **Features:**
  - Register remote handler "Test:Ping"
  - Emit event "TestEvent"
  - Return data to client
- **Manifest:**
  ```lua
  name = "TestService"
  version = "1.0.0"
  type = "module"
  dependencies = {"Logger", "EventBusService", "RemoteManagerService"}
  ```

---

#### **MOD-002**: TestController

- **File:** `src/client/modules/TestController.lua`
- **Dependencies:** Logger, RemoteClient, StateManager
- **Description:** Client test module
- **Features:**
  - Invoke "Test:Ping"
  - Listen to "TestEvent"
  - Update state with response
- **Manifest:**
  ```lua
  name = "TestController"
  version = "1.0.0"
  type = "module"
  dependencies = {"Logger", "RemoteClient", "StateManager"}
  ```

---

#### **MOD-003**: TestUI

- **File:** `src/client/modules/TestUI.lua`
- **Dependencies:** UIEngine, ThemeController, TestController
- **Description:** UI test component
- **Features:**
  - Button: "Ping Server"
  - Label: Display response
  - Theme toggle button
- **Manifest:**
  ```lua
  name = "TestUI"
  version = "1.0.0"
  type = "module"
  dependencies = {"UIEngine", "ThemeController", "TestController"}
  ```

---

### ✅ FASE 4 SUCCESS CRITERIA:

1. Button click → Invoke server
2. Server respond → Update UI
3. Event from server → UI reacts
4. Theme toggle → UI changes
5. Full stack communication confirmed

---

## 🧩 FASE 5: CODER/BUILDER WORKFLOW

**Tujuan:** Tag-based component system

**BLOCKED UNTIL:** Fase 4 complete

### 📋 TASKS:

#### **OVHL-011**: ComponentService

- **File:** `src/server/services/ComponentService.lua`
- **Dependencies:** Logger, EventBusService
- **Description:** Auto-knit components via CollectionService tags
- **Features:**
  - Scan for `ovhl:component` attribute
  - Auto-require component from `shared/components/`
  - Call `:Knit(instance)` when tagged
  - Call `:Destroy()` when untagged
- **Manifest:**
  ```lua
  name = "ComponentService"
  version = "1.0.0"
  type = "service"
  dependencies = {"Logger", "EventBusService"}
  priority = 40
  ```

---

#### **MOD-COMP-001**: SpinningCoin

- **File:** `src/shared/components/SpinningCoin.lua`
- **Description:** Example component (rotating coin)
- **Features:**
  - :Knit(part) → Start rotation
  - :Destroy() → Stop rotation
- **Manifest:**
  ```lua
  name = "SpinningCoin"
  version = "1.0.0"
  type = "component"
  dependencies = {}
  ```

---

### ✅ FASE 5 SUCCESS CRITERIA:

1. Builder tag Part with `ovhl:component = "SpinningCoin"`
2. Component auto-knit
3. Coin rotates
4. Remove tag → rotation stops
5. Multiple instances work

---

## 🚀 FASE 6: ADVANCED FEATURES

**Tujuan:** Production-ready enhancements

**BLOCKED UNTIL:** Fase 5 complete

### 📋 TASKS:

- **OVHL-012**: Rate Limiting Enhancement
- **OVHL-013**: Network Batching
- **OVHL-014**: Network Caching
- **OVHL-015**: Network Monitoring
- **OVHL-016**: Hot Reloading (Dev)
- **OVHL-017**: Admin Panel Module

---

## 🛠️ FASE 7: DEVELOPER TOOLS

**Tujuan:** CLI & SDK

**BLOCKED UNTIL:** Fase 6 complete

### 📋 TASKS:

- **OVHL-018**: CLI Generator (create:service, create:module, create:component)
- **OVHL-019**: Documentation Generator
- **OVHL-020**: Performance Profiler

---

## 📊 SUMMARY

| Fase              | Tasks | Dependencies | Status         |
| ----------------- | ----- | ------------ | -------------- |
| 0 - Bootstrap     | 5     | None         | 🔨 IN PROGRESS |
| 1 - Core Services | 3     | Fase 0       | ⏸️ BLOCKED     |
| 2 - Networking    | 3     | Fase 1       | ⏸️ BLOCKED     |
| 3 - UI Framework  | 4     | Fase 2       | ⏸️ BLOCKED     |
| 4 - Test Modules  | 3     | Fase 3       | ⏸️ BLOCKED     |
| 5 - Components    | 2     | Fase 4       | ⏸️ BLOCKED     |
| 6 - Advanced      | 6     | Fase 5       | ⏸️ BLOCKED     |
| 7 - Tooling       | 3     | Fase 6       | ⏸️ BLOCKED     |

---

## 🎯 NEXT ACTION

**START:** OVHL-B001 (LoggerService)

**WHY THIS FIRST?**
Karena ini adalah foundation dari foundation. Semua module butuh logging. Tanpa logger, debugging jadi nightmare.

**COMMAND:**

```bash
bash ./lokal/tools/run.sh OVHL-B001
```

---

**END OF ROADMAP**
