import io
import lupa

SRC = r"C:\Users\Dmitriy\Downloads\F\FeatherCage\mod\FeatherCageCheats\Scripts\main.lua"

rt = lupa.LuaRuntime(unpack_returned_tuples=True)
g = rt.globals()

rt.execute(r"""
-- minimal UE4SS API mock ------------------------------------------------
local log_lines = {}
_G.__log_lines = log_lines

function print(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    log_lines[#log_lines + 1] = table.concat(parts, " ")
end

function StaticFindObject(path) return nil end
function FindObjects(...) return {} end
function FindObject(...) return nil end

function FName(s)
    return { ToString = function() return tostring(s) end }
end

UEHelpers = {
    GetWorld = function() return nil end,
    GetPlayerController = function() return nil end,
    GetPlayer = function() return nil end,
    GetKismetSystemLibrary = function() return nil end,
    GetKismetMathLibrary = function() return nil end,
    GetGameplayStatics = function() return nil end,
    FindFName = function(s) return FName(s) end,
}
package.preload["UEHelpers"] = function() return UEHelpers end

Key = {}
for _, k in ipairs({"F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
                    "PageUp","PageDown","A","B","C"}) do Key[k] = k end
ModifierKey = { CONTROL = 1, ALT = 2, SHIFT = 3 }

_G.__console_handler = nil
function RegisterConsoleCommandHandler(name, fn) _G.__console_handler = fn end

_G.__keybinds = {}
function RegisterKeyBind(key, a, b)
    local mods, fn
    if type(a) == "function" then fn = a else mods = a; fn = b end
    _G.__keybinds[#_G.__keybinds + 1] = { key = key, mods = mods, fn = fn }
end

function ExecuteInGameThreadWithDelay(ms, fn) return 1 end
function LoopInGameThreadWithDelay(ms, fn) return 2 end
function RegisterLoadMapPostHook(fn) return true end
function NotifyOnNewObject(...) end
""")

src = io.open(SRC, encoding="utf-8").read()
rt.execute(src)

# report what loaded
print_fn = rt.globals().print
log_lines = rt.eval("__log_lines")

def dump_log(label):
    print(f"--- {label} ---")
    n = len(log_lines)
    for i in range(1, n + 1):
        print(log_lines[i])

dump_log("load log")

handler = rt.eval("__console_handler")
print("console handler registered:", handler is not None)
print("keybinds:", len(rt.eval("__keybinds")))

def run(cmd):
    params = rt.table(*cmd.split())
    # emulate handler(FullCommand, Parameters, Ar)
    rt.execute("local h = __console_handler; __last = { h('fc', ..., nil) }", )

# simpler: call via lua with a table
def run_cmd(line):
    words = line.split()
    tbl = rt.table(*words)
    rt.globals()["__console_handler"]("fc", tbl, None)
    dump_log(f"cmd: {line}")

for c in ["help", "status", "items", "next", "kill BP_Item_Key", "spawn BP_Item_Key 2"]:
    run_cmd(c)
