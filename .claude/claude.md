# CLAUDE.md — Arma 3 / CBA Project

## Project Overview

This is an Arma 3 addon/mod project using **CBA_A3** (Community Base Addons). The codebase is SQF (Status Quo Function scripting language) with config files in the Arma config format (`.cpp`/`.hpp`). Build tooling is **HEMTT**.

---

## Directory Structure

```
project_root/
├── addons/
│   └── <component>/               # One folder per addon component/PBO
│       ├── $PBOPREFIX$             # PBO prefix file (e.g. z\mymod\addons\component)
│       ├── config.cpp              # Component config (CfgPatches, CfgFunctions, etc.)
│       ├── CfgFunctions.hpp        # Function definitions (included in config.cpp)
│       ├── XEH_PREP.hpp            # PREP macros for all functions (included in config.cpp)
│       ├── XEH_preInit.sqf         # Runs preInit (before mission, no objects yet)
│       ├── XEH_postInit.sqf        # Runs postInit (after mission start)
│       ├── script_component.hpp    # Component-level defines (COMPONENT, PREFIX, etc.)
│       └── functions/
│           └── fnc_*.sqf           # All functions for this component
├── hemtt.toml                      # HEMTT build config
├── .hemttignore
└── CLAUDE.md
```

---

## Naming Conventions

### Prefix / Namespace

- **MOD prefix**: defined in `script_component.hpp` as `PREFIX` and `COMPONENT`
- All public functions: `PREFIX_COMPONENT_fnc_functionName`
- All variables: `PREFIX_COMPONENT_varName` or `PREFIX_COMPONENT_GVAR(varName)`
- Example: `mymod_core_fnc_doThing`, `mymod_core_isReady`

### Functions

- File: `functions/fnc_functionName.sqf`
- PREP macro in `XEH_PREP.hpp`: `PREP(functionName);`
- Referenced in SQF as: `[args] call PREFIX_COMPONENT_fnc_functionName`

---

## CBA Macros (from `script_component.hpp`)

Always use the CBA macros — never hardcode strings for mod-scoped variables or function calls.

| Macro | Expands To | Use For |
|---|---|---|
| `GVAR(x)` | `PREFIX_COMPONENT_x` | Global variables |
| `LGVAR(x)` | `PREFIX_x` | Global vars scoped to PREFIX only |
| `LVAR(x)` | `PREFIX_COMPONENT_x` (local) | Per-object/local vars (same as GVAR in practice) |
| `FUNC(x)` | `PREFIX_COMPONENT_fnc_x` | Calling own functions |
| `EFUNC(c,x)` | `PREFIX_c_fnc_x` | Calling functions from another component |
| `QUOTE(x)` | `"x"` (stringified) | Quoting macro expansions |
| `PREP(x)` | CfgFunctions entry | In `XEH_PREP.hpp` |
| `IS_ADMIN` | admin check | Common CBA shorthand |

### Settings (`CBA_settings`)

```sqf
// In XEH_preInit.sqf
[
    QGVAR(settingName),           // Setting name (quoted GVAR)
    "SLIDER",                     // Type: CHECKBOX, SLIDER, LIST, EDITBOX, COLOR, BUTTON
    ["Display Name", "Tooltip"],
    "Category",
    [0, 10, 5, 1],                // [min, max, default, step] for SLIDER
    true,                         // isGlobal (true = server forces value on all clients)
    {                             // (optional) onChange callback
        // code
    }
] call CBA_fnc_addSetting;
```

---

## XEH (Extended Event Handlers)

CBA's XEH fires on class addition. Use these instead of raw `addEventHandler` for lifecycle events.

```sqf
// Recommended pattern in XEH_postInit.sqf
["CAManBase", "InitPost", {
    params ["_unit"];
    // runs for every man spawned
}, true, [], true] call CBA_fnc_addClassEventHandler;
```

Common XEH events: `InitPost`, `Killed`, `FiredNear`, `GetInPost`, `GetOutPost`

---

## CBA Event System

Prefer CBA events over direct function calls for cross-component/cross-machine communication.

```sqf
// Add listener (usually in XEH_postInit.sqf or a function)
["mymod_eventName", {
    params ["_arg1", "_arg2"];
}] call CBA_fnc_addEventHandler;

// Fire locally
["mymod_eventName", [_arg1, _arg2]] call CBA_fnc_localEvent;

// Fire globally (all machines)
["mymod_eventName", [_arg1, _arg2]] call CBA_fnc_globalEvent;

// Fire on server only
["mymod_eventName", [_arg1, _arg2]] call CBA_fnc_serverEvent;

// Fire on specific target (object owner)
["mymod_eventName", [_arg1, _arg2], _targetObject] call CBA_fnc_targetEvent;
```

---

## SQF Coding Conventions

### Function template

```sqf
#include "script_component.hpp"
/*
 * Author: [Name]
 * Description of what this function does.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Value <NUMBER> (default: 1)
 *
 * Return Value:
 * Success <BOOL>
 *
 * Example:
 * [player, 5] call FUNC(doThing)
 *
 * Public: Yes/No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_value", 1, [0]]
];

// Guard clauses first
if (isNull _unit) exitWith {
    ERROR("Unit is null");
    false
};

// Logic here

true
```

### Style rules

- Always `params` at the top with type validation — never `_this select N` without params
- Use `exitWith {}` for early returns rather than deep nesting
- One blank line between logical blocks
- Comments on non-obvious logic
- No magic numbers — define constants as `#define MY_CONST 42` in `script_component.hpp`
- Prefer `private _var` declarations; avoid polluting global scope
- Never use `call compile preprocessFileLineNumbers` in runtime code — use `FUNC()` macro
- Format: tabs for indentation (matches existing `.sqf` files)

### Locality

- Always be explicit about locality — document in function header whether it must run on server, client, or any
- Use `hasInterface`, `isServer`, `isDedicated` guards where needed
- Never assume `player` exists on server

---

## config.cpp Patterns

### CfgPatches (required in every component)

```cpp
class CfgPatches {
    class PREFIX_COMPONENT {
        name = "My Mod - Component Name";
        units[] = {};
        weapons[] = {};
        requiredVersion = 1.98;
        requiredAddons[] = {
            "cba_main"
        };
        authors[] = {"YourName"};
        VERSION_CONFIG;  // Macro from script_component.hpp
    };
};
```

### Including sub-configs

```cpp
// In config.cpp
#include "script_component.hpp"
#include "CfgFunctions.hpp"
// Other includes as needed
```

---

## Build Tooling — PBO Manager

PBOs are packed manually using **PBO Manager** (by Kegetys).

### Packing a PBO

1. Right-click the addon component folder in Explorer
2. Select **PBO Manager → Pack into PBO**
3. Output goes to the same directory as the folder (move it to your mod's `addons/` folder)

### Folder → PBO naming

The folder name becomes the PBO filename. The `$PBOPREFIX$` file inside sets the internal prefix path, e.g.:

```
z\mymod\addons\core
```

This must match what is declared in `CfgPatches`.

### Dev workflow (no pack needed)

For faster iteration during development, use **file patching**:

- Launch Arma 3 with `-filePatching` in launch parameters
- Symlink or copy your addon folder directly into `Arma 3\@MyMod\addons\` as an **unpacked folder** (not a PBO)
- Arma will load the raw folder; changes to `.sqf` files take effect on mission restart without repacking
- Config changes (`.cpp`/`.hpp`) still require a full game restart

### Release

Pack each `addons/<component>` folder individually into a `.pbo`, then place all PBOs under:

```
@MyMod/
└── addons/
    ├── mymod_core.pbo
    ├── mymod_core.pbo.mymod.bisign  (if signing)
    └── ...
```

---

## Debugging

- Use `diag_log TEXT(GVAR(varName))` — the `TEXT()` macro stringifies safely
- `systemChat` for quick in-game visibility (remove before commit)
- Enable `filePatching` and `-showScriptErrors` in launch params during dev
- CBA provides `LOG`, `INFO`, `WARNING`, `ERROR` macros when `DISABLE_COMPILE_CACHE` is defined:
  ```sqf
  LOG("Function reached");
  WARNING_1("Unexpected value: %1", _value);
  ERROR_1("Critical failure: %1", _reason);
  ```
- `bis_fnc_scriptProfiler` for performance profiling
- Use `isNil "VARNAME"` to check if a global var is initialised before use

---

## Common Pitfalls

- **PBO prefix mismatch**: `$PBOPREFIX$` content must exactly match what's in `CfgPatches` and function paths
- **PREP missing**: forgetting to add a new function to `XEH_PREP.hpp` means it won't compile into `CfgFunctions`
- **Wrong locality**: running `player` on the server, or server-only logic on clients
- **Race conditions in postInit**: objects may not be fully initialised; use `waitUntil` or XEH `InitPost` instead
- **String vs macro**: never hardcode `"mymod_core_fnc_foo"` — use `QUOTE(FUNC(foo))` or `FUNC(foo)` directly
- **Missing `#include "script_component.hpp"`**: macros won't resolve without this at the top of every file

---

## Dependencies

- **CBA_A3** (required): `cba_main`, and component-specific CBA modules as needed
- Workshop ID: `450814997`
- Steam branch: `stable` (or `development` for cutting-edge)

---

## References

- [CBA Wiki](https://cbateam.github.io/CBA_A3/docs/)
- [CBA GitHub](https://github.com/CBATeam/CBA_A3)
- [Bohemia SQF Reference](https://community.bistudio.com/wiki/SQF_syntax)
- [BI Community Wiki — Functions](https://community.bistudio.com/wiki/Arma_3:_Functions_Library)


## Existing Projects
If you are working on adding things to an existing mod/mission, you must look at how other modules function to ensure new modules and edits will work.