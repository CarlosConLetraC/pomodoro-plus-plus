-- config_manager.lua
api = {}
local json = require("json")

-- Función prettyprint en Lua (idéntica a la versión de Bash)
local function prettyprint(level, ...)
    local handle = io.popen("date +%H:%M:%S.%N")
    local currentTime = handle and handle:read("*a") or "00:00:00.0000"
    if handle then handle:close() end
    currentTime = currentTime:sub(1, 12)

    local messages = {...}
    local msg = table.concat(messages, " ")

    local color, label
    if level == 0 then
        color = "\27[0;36m" -- Cyan [INFO]
        label = "[INFO]:"
    elseif level == 1 then
        color = "\27[0;33m" -- Yellow [WARN]
        label = "[WARN]:"
    else
        color = "\27[0;31m" -- Red [FAIL]
        label = "[FAIL]:"
    end

    local reset = "\27[0m"
    io.write(string.format("[%s]%s%s%s %s\n", currentTime, color, label, reset, msg))
end

local function get_config_dir()
    local home = os.getenv("HOME") or os.getenv("USERPROFILE") or "."
    return home .. "/.config/pomodoro-plus-plus/config/"
end

local function ensure_dir(path)
    os.execute("mkdir -p \"" .. path .. "\"")
end

local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        return io.close(f)
    end
    return false
end

local defaults = {
    ["pomodoro-config.json"] = [[{
  "popup": {
    "position": "bottom-right",
    "width": 310,
    "height": 210,
    "offsetMargin": 20,
    "topmost": true
  }
}
]],
    ["theme.json"] = [[{
  "mode": "light"
}
]],
    ["last-session-info.json"] = [[{
  "lastCycle": 1,
  "totalCycles": 4,
  "mode": "Trabajo"
}
]]
}

function api.init()
    local dir = get_config_dir()
    ensure_dir(dir)
    
    for filename, content in pairs(defaults) do
        local filepath = dir .. filename
        if not file_exists(filepath) then
            prettyprint(0, "Generando template por defecto: " .. filename)
            local f = io.open(filepath, "w")
            if f then
                f:write(content)
                f:close()
            end
        end
    end
    prettyprint(0, "Configuraciones de Pomodoro++ verificadas exitosamente.")
end

function api.rebuild()
    local dir = get_config_dir()
    prettyprint(0, "Reconstruyendo configuraciones desde cero...")
    for filename, _ in pairs(defaults) do
        local filepath = dir .. filename
        if file_exists(filepath) then
            os.remove(filepath)
            prettyprint(0, "Eliminado anterior: " .. filename)
        end
    end
    api.init()
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

local function write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

function api.add(target_arg, raw_snippet)
    api.init()
    local dir = get_config_dir()
    
    local filename = target_arg
    if not filename:match("%.json$") then
        filename = filename .. ".json"
    end
    local filepath = dir .. filename

    if not file_exists(filepath) then
        prettyprint(2, "El archivo de configuración destino no existe: " .. filename)
        os.exit(2) -- Error de ejecución
    end

    local content = read_file(filepath)
    prettyprint(0, "Actualizando " .. filename .. " con: " .. raw_snippet)

    local data, _, err = json.decode(content)
    if not data then
        prettyprint(2, "Error al decodificar el archivo JSON existente: " .. tostring(err))
        os.exit(2)
    end

    local snippet_data, _, snippet_err = json.decode(raw_snippet)
    if not snippet_data or type(snippet_data) ~= "table" then
        snippet_data, _, snippet_err = json.decode("{" .. raw_snippet .. "}")
        if not snippet_data or type(snippet_data) ~= "table" then
            prettyprint(2, "El formato JSON proporcionado no es válido: " .. tostring(snippet_err))
            os.exit(2) -- Error de formato
        end
    end

    for k, v in pairs(snippet_data) do
        data[k] = v
    end

    local new_content = json.encode(data, { indent = true })
    if not new_content then
        prettyprint(2, "Error al codificar la nueva configuración JSON.")
        os.exit(2)
    end

    write_file(filepath, new_content .. "\n")
    prettyprint(0, "Archivo " .. filename .. " modificado exitosamente.")
end

function api.run(raw_action, ...)
    local action = raw_action
    
    if not action then
        action = "init"
    else
        -- Limpiar el guion inicial (-) directamente en Lua
        action = action:gsub("^%-", "")
    end

    -- print(string.format("raw_action: %s", raw_action))
    -- print(string.format("arg #0: <%s>", action))
    -- for n = 1, select("#", ...), 1 do
    --     print(string.format("arg #%d: <%s>", n, (select(n, ...))))
    -- end

    local func = api[action]
    if func and type(func) == "function" then
        local success, err = pcall(func, ...)
        if not success then
            prettyprint(2, "Error interno: " .. tostring(err))
            os.exit(2)
        end
        os.exit(0)
    else
        os.exit(1) -- Código 1: Método no encontrado (argumento inválido)
    end
end

return api
