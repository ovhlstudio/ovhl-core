# Server Modules Directory

Place your server modules here. They will be auto-discovered by the OVHL bootstrap system.

Each module should have:
- `__manifest` with required fields
- Proper lifecycle methods (:new, :Inject, :Init, :Start)
- Dependencies declared in manifest

Example:
```lua
local MyModule = {}
MyModule.__index = MyModule

MyModule.__manifest = {
    name = "MyModule",
    version = "1.0.0",
    type = "module",
    dependencies = {"Logger", "DataService"}
}

function MyModule.new(logger) ... end
function MyModule:Inject(services) ... end
function MyModule:Init() ... end
function MyModule:Start() ... end

return MyModule
