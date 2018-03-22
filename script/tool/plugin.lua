local lni = require 'lni'
local sandbox = require 'tool.sandbox'
local root = fs.current_path():remove_filename()
local plugin_path = root / 'plugin'

local function load_one_plugin(path)
    local info = lni(io.load(path / 'info.ini'))
    local plugin = {
        name = info.info.name,
        version = info.info.version,
        author = info.info.author,
        description = info.info.description,
        enable = info.config.enable,
        path = path,
    }
    if not plugin.name then
        return
    end
    return plugin
end

local function load_plugins()
    local plugins = {}
    for path in plugin_path:list_directory() do
        if fs.is_directory(path) then
            local ok, res = pcall(load_one_plugin, path)
            if ok then
                plugins[#plugins+1] = res
            end
        end
    end
    table.sort(plugins, function (a, b)
        return a.name < b.name
    end)
    return plugins
end

local function call_plugin(w2l, plugin)
    local ok, err = xpcall(sandbox, debug.traceback, plugin.path:string()..'\\', io.open, {
        ['w3x2lni'] = w2l,
    })
    if not ok then

    end
end

return function (w2l)
    local plugins = load_plugins()
    for _, plugin in ipairs(plugins) do
        if plugin.enable then
            call_plugin(w2l, plugin)
        end
    end
end