local gui = require 'yue.gui'
local ext = require 'yue-ext'
local backend = require 'gui.backend'
local messagebox = require 'ffi.messagebox'
require 'filesystem'

local worker

local mini = {}

function mini:init()
    local win = gui.Window.create  { frame = false }
    win:settitle('w3x2lni-mini')
    ext.register_window('w3x2lni-mini')
    
    local view = gui.Container.create()
    view:setstyle { FlexGrow = 1 }
    view:setmousedowncanmovewindow(true)

    local title = gui.Container.create()
    title:setstyle { FlexGrow = 1, Height = 25, FlexDirection = 'row', AlignItems = 'center' }
    title:setbackgroundcolor('#28c')
    title:setmousedowncanmovewindow(true)
    view:addchildview(title)

    local title_label = gui.Label.create('')
    title_label:setstyle { Height = 20, Width = 80 }
    title_label:setcolor('#eee')
    title_label:setfont(gui.Font.create('宋体', 16, "bold", "normal"))
    title_label:setmousedowncanmovewindow(true)
    title:addchildview(title_label)
    
    local label = gui.Label.create('')
    label:setstyle { Margin = 5, Height = 20 }
    label:setmousedowncanmovewindow(true)
    view:addchildview(label)
    
    local pb = gui.ProgressBar.create()
    pb:setstyle { Margin = 5, Height = 40 }
    view:addchildview(pb)
    
    win:setcontentview(view)
    win:sethasshadow(true)
    win:setresizable(false)
    win:setmaximizable(false)
    win:setminimizable(false)
    win:setalwaysontop(true)
    win:setcontentsize { width = 400, height = 110 }
    win:center()
    win:activate()
    ext.hide_in_taskbar()

    self._label = label
    self._title = title_label
    self._progressbar = pb
    self._window = win
    self._view = view
end

function mini:select()
    local win = gui.Window.create  { frame = false }
    win:settitle('w3x2lni-mini')
    ext.register_window('w3x2lni-mini')

    local view = gui.Container.create()
    view:setstyle { Border = 2 }
    view:setbackgroundcolor('#222222')
    view:setmousedowncanmovewindow(true)

    local lni = gui.Button.create('转为Lni')
    lni:setstyle { Height = 100, Width = 392, AlignItems = 'center', Margin = 2 }
    lni:setbackgroundcolor('#00add9')
    lni:setfont(gui.Font.create('黑体', 20, "normal", "normal"))
    view:addchildview(lni)

    local slk = gui.Button.create('转为Slk')
    slk:setstyle { Height = 100, Width = 392, AlignItems = 'center', Margin = 2 }
    slk:setbackgroundcolor('#00ad3c')
    slk:setfont(gui.Font.create('黑体', 20, "normal", "normal"))
    view:addchildview(slk)

    local obj = gui.Button.create('转为Obj')
    obj:setstyle { Height = 100, Width = 392, AlignItems = 'center', Margin = 2 }
    obj:setbackgroundcolor('#d9a33c')
    obj:setfont(gui.Font.create('黑体', 20, "normal", "normal"))
    view:addchildview(obj)

    win:setcontentview(view)
    win:sethasshadow(true)
    win:setresizable(false)
    win:setmaximizable(false)
    win:setminimizable(false)
    win:setalwaysontop(true)
    win:setcontentsize { width = 400, height = 316 }
    win:center()
    win:activate()
    ext.hide_in_taskbar()

    self._window = win
    self._view = view

    function lni:onclick()
        win:close()
        arg[#arg+1] = '-lni'
        mini:backend()
    end

    function slk:onclick()
        win:close()
        arg[#arg+1] = '-slk'
        mini:backend()
    end

    function obj:onclick()
        win:close()
        arg[#arg+1] = '-obj'
        mini:backend()
    end
end

function mini:settext(text)
    self._label:settext(text)
end

function mini:settitle(title)
    self._title:settext(title)
end

function mini:setvalue(value)
    self._progressbar:setvalue(value)
    self._view:schedulepaint()
end

function mini:close()
    self._window:close()
end

function mini:event_close(f)
    self._window.onclose = f
end

local function pack_arg()
    local buf = {}
    for i, command in ipairs(arg) do
        buf[i] = '"' .. command .. '"'
    end
    return table.concat(buf, ' ')
end

local function need_select()
    for _, command in ipairs(arg) do
        if command == '-slk' or command == '-lni' or command == '-obj' then
            return false
        end
    end
    return true
end

local function sortpairs(t)
    local sort = {}
    for k, v in pairs(t) do
        sort[#sort+1] = {k, v}
    end
    table.sort(sort, function (a, b)
        return a[1] < b[1]
    end)
    local n = 1
    return function()
        local v = sort[n]
        if not v then
            return
        end
        n = n + 1
        return v[1], v[2]
    end
end

local function create_report()
    for type, report in sortpairs(backend.report) do
        if type ~= '' then
            type = type:sub(2)
            print('================')
            print(type)
            print('================')
            for _, s in ipairs(report) do
                if s[2] then
                    print(('%s - %s'):format(s[1], s[2]))
                else
                    print(s[1])
                end
            end
            print('')
        end
    end
    local report = backend.report['']
    if report then
        for _, s in ipairs(report) do
            if s[2] then
                print(('%s - %s'):format(s[1], s[2]))
            else
                print(s[1])
            end
        end
    end
end

local function update()
    worker:update()
    mini:settext(backend.message)
    mini:settitle(backend.title)
    mini:setvalue(backend.progress)
    if #worker.error > 0 then
        messagebox('错误', worker.error)
        worker.error = ''
        return 0, 1
    end
    if worker.exited then
        create_report()
        if worker.exit_code == 0 then
            return 1000, 0
        else
            return 0, worker.exit_code
        end
    end
end

local function delayedtask()
    local ok, r, code = xpcall(update, debug.traceback)
    if not ok then
        messagebox('错误', r)
        mini:close()
        os.exit(1, true)
        return
    end
    if r then
        if r > 0 then
            gui.MessageLoop.postdelayedtask(r, function()
                mini:close()
                os.exit(code, true)
            end)
        else
            mini:close()
            os.exit(code, true)
        end
        return
    end
    gui.MessageLoop.postdelayedtask(100, delayedtask)
end

local function getexe()
	local i = 0
	while arg[i] ~= nil do
		i = i - 1
	end
	return fs.path(arg[i + 1])
end

function mini:backend()
    mini:init()
    mini:event_close(gui.MessageLoop.quit)
    backend:init(getexe(), fs.current_path())
    worker = backend:open('map.lua', pack_arg())
    backend.message = '正在初始化...'
    backend.progress = 0
    gui.MessageLoop.postdelayedtask(100, delayedtask)
    gui.MessageLoop.run()
end

function mini:frontend()
    mini:select()
    mini:event_close(gui.MessageLoop.quit)
    gui.MessageLoop.run()
end

if need_select() then
    mini:frontend()
else
    mini:backend()
end

