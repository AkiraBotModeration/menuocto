local startupArgs = ({...})[1] or {}

local function envTable()
    if typeof(getgenv) == 'function' then
        local ok, env = pcall(getgenv)
        if ok and type(env) == 'table' then
            return env
        end
    end
    return _G
end

do
    local env = envTable()
    if type(env.library) == 'table' and type(env.library.Unload) == 'function' then
        pcall(function()
            env.library:Unload()
        end)
    end
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local function safeClone(obj)
    local ok, cloned = pcall(function()
        if cloneref then return cloneref(obj) end
        if clonereference then return clonereference(obj) end
        return obj
    end)
    return ok and cloned or obj
end
local function gs(a)
    return safeClone(game:GetService(a))
end

local function safeB64Decode(str)
    if type(str) ~= 'string' or str == '' then
        return ''
    end
    local candidates = {
        function()
            return syn.crypt.base64.decode(str)
        end,
        function()
            return crypt.base64decode(str)
        end,
        function()
            return crypt.base64.decode(str)
        end,
        function()
            return base64_decode(str)
        end,
        function()
            return base64.decode(str)
        end,
    }
    for _, fn in candidates do
        local ok, decoded = pcall(fn)
        if ok and type(decoded) == 'string' and #decoded > 0 then
            return decoded
        end
    end
    local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local data = string.gsub(str, '[^' .. alphabet .. '=]', '')
    local okLua, decoded = pcall(function()
        return (data:gsub('.', function(x)
            if x == '=' then
                return ''
            end
            local r, f = '', (alphabet:find(x, 1, true) - 1)
            for i = 6, 1, -1 do
                r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
            end
            return r
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if #x ~= 8 then
                return ''
            end
            local c = 0
            for i = 1, 8 do
                c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
            end
            return string.char(c)
        end))
    end)
    return (okLua and type(decoded) == 'string') and decoded or ''
end

local WHITE_PIXEL_PNG = safeB64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==')

local players, http, runservice, inputservice, tweenService, stats, actionservice = gs('Players'), gs('HttpService'), gs('RunService'), gs('UserInputService'), gs('TweenService'), gs('Stats'), gs('ContextActionService')
local localplayer = players.LocalPlayer

local setByConfig = false
local floor, ceil, huge, pi, clamp = math.floor, math.ceil, math.huge, math.pi, math.clamp
local c3new, fromrgb, fromhsv = Color3.new, Color3.fromRGB, Color3.fromHSV
local next, newInstance, newUDim2, newVector2 = next, Instance.new, UDim2.new, Vector2.new
local isexecutorclosure = isexecutorclosure or is_synapse_function or is_sirhurt_closure or iskrnlclosure;
local executor = (
    syn and 'syn' or
    getexecutorname and getexecutorname() or
    'unknown'
)

local library = {
    windows = {};
    indicators = {};
    flags = {};
    options = {};
    connections = {};
    drawings = {};
    instances = {};
    utility = {};
    notifications = {};
    tweens = {};
    theme = {};
    anim = {
        sliderDrag = 0.08;
        sliderSet = 0.28;
        menuOpen = 0.26;
        menuClose = 0.22;
        notify = 0.24;
        notifyStack = 0.2;
        scrollLerp = 14;
        scrollStep = 22;
        openLock = 0.28;
        easing = Enum.EasingStyle.Quart;
        direction = Enum.EasingDirection.Out;
    };
    zindexOrder = {
        ['indicator'] = 950;
        ['window'] = 1000;
        ['dropdown'] = 1200;
        ['colorpicker'] = 1100;
        ['watermark'] = 1300;
        ['notification'] = 1400;
        ['cursor'] = 1500;
    },
    stats = {
        ['fps'] = 0;
        ['ping'] = 0;
    };
    images = {
        ['gradientp90'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/gradient90.png';
        ['gradientp45'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/gradient45.png';
        ['colorhue'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/lgbtqshit.png';
        ['colortrans'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/trans.png';
        ['pixel'] = WHITE_PIXEL_PNG;
    };
    numberStrings = {['Zero'] = 0, ['One'] = 1, ['Two'] = 2, ['Three'] = 3, ['Four'] = 4, ['Five'] = 5, ['Six'] = 6, ['Seven'] = 7, ['Eight'] = 8, ['Nine'] = 9};
    signal = (function()
        local Signal = {}
        Signal.__index = Signal
        function Signal.new()
            return setmetatable({ _bindings = {} }, Signal)
        end
        function Signal:Connect(fn)
            local binding = { fn = fn, connected = true }
            table.insert(self._bindings, binding)
            if self._drawing then
                self._drawing._interactive = true
                if library.interactiveDrawings and self._drawing.Object then
                    library.interactiveDrawings[self._drawing.Object] = self._drawing
                end
            end
            return {
                Disconnect = function()
                    if not binding.connected then
                        return
                    end
                    binding.connected = false
                    binding.fn = nil
                    local idx = table.find(self._bindings, binding)
                    if idx then
                        table.remove(self._bindings, idx)
                    end
                end,
            }
        end
        function Signal:Fire(...)
            local snapshot = {}
            for i, binding in self._bindings do
                snapshot[i] = binding
            end
            for _, binding in snapshot do
                if binding.connected and binding.fn then
                    binding.fn(...)
                end
            end
        end
        return Signal
    end)();
    open = false;
    opening = false;
    hasInit = false;
    uiDragging = false;
    uiRadius = 3;
    cheatname = startupArgs.cheatname or 'sonata';
    gamename = startupArgs.gamename or 'rivals';
    fileext = startupArgs.fileext or '.txt';
}

do
    local function shade(c3, delta)
        local r = clamp((c3.R * 255) + delta, 0, 255)
        local g = clamp((c3.G * 255) + delta, 0, 255)
        local b = clamp((c3.B * 255) + delta, 0, 255)
        return fromrgb(r, g, b)
    end

    local function buildTheme(accent, bg, surface, light)
        surface = surface or shade(bg, light and -8 or 10)
        local section = shade(bg, light and -4 or 4)
        local option = shade(bg, light and -12 or 17)
        local border1 = shade(bg, light and -30 or 37)
        local border2 = shade(bg, light and -10 or 14)
        local border3 = shade(bg, light and -40 or -8)
        local text = light and fromrgb(40, 40, 45) or fromrgb(235, 235, 235)
        local textMid = light and fromrgb(70, 70, 78) or fromrgb(195, 195, 195)
        local textDim = light and fromrgb(110, 110, 120) or fromrgb(145, 145, 145)
        return {
            ['Accent'] = accent;
            ['Background'] = bg;
            ['Border'] = light and fromrgb(200, 200, 205) or fromrgb(0, 0, 0);
            ['Border 1'] = border1;
            ['Border 2'] = border2;
            ['Border 3'] = border3;
            ['Primary Text'] = text;
            ['Group Background'] = surface;
            ['Selected Tab Background'] = shade(surface, light and -4 or 4);
            ['Unselected Tab Background'] = bg;
            ['Selected Tab Text'] = text;
            ['Unselected Tab Text'] = textDim;
            ['Section Background'] = section;
            ['Option Text 1'] = text;
            ['Option Text 2'] = textMid;
            ['Option Text 3'] = textDim;
            ['Option Border 1'] = shade(bg, light and -24 or 32);
            ['Option Border 2'] = light and fromrgb(190, 190, 195) or fromrgb(0, 0, 0);
            ['Option Background'] = option;
            ['Risky Text'] = fromrgb(175, 21, 21);
            ['Risky Text Enabled'] = fromrgb(255, 41, 41);
        }
    end

    local function T(name, accent, bg, surface, light)
        return { name = name, theme = buildTheme(accent, bg, surface, light) }
    end

    local function sonataDefault()
        local theme = buildTheme(fromrgb(196,148,255), fromrgb(12,12,14), fromrgb(20,20,24))
        theme['Border 1'] = fromrgb(42,42,48)
        theme['Border 2'] = fromrgb(20,20,24)
        theme['Border 3'] = fromrgb(8,8,10)
        theme['Primary Text'] = fromrgb(244,244,246)
        theme['Option Text 1'] = fromrgb(244,244,246)
        theme['Option Text 2'] = fromrgb(186,186,194)
        theme['Option Text 3'] = fromrgb(140,140,150)
        theme['Section Background'] = fromrgb(16,16,20)
        theme['Selected Tab Background'] = fromrgb(28,28,34)
        theme['Unselected Tab Background'] = fromrgb(12,12,14)
        theme['Selected Tab Text'] = fromrgb(244,244,246)
        theme['Unselected Tab Text'] = fromrgb(150,150,160)
        theme['Option Background'] = fromrgb(24,24,28)
        theme['Option Border 1'] = fromrgb(48,48,56)
        theme['Risky Text'] = fromrgb(235,64,90)
        theme['Risky Text Enabled'] = fromrgb(255,45,80)
        return { name = 'Sonata', theme = theme }
    end

    library.themes = {
        sonataDefault();
        T('Default (Kanagawa)', fromrgb(235,163,255), fromrgb(31,31,40), fromrgb(42,42,55));
        T('Catppuccin Mocha', fromrgb(203,166,247), fromrgb(30,30,46), fromrgb(49,50,68));
        T('Catppuccin Macchiato', fromrgb(198,160,246), fromrgb(36,39,58), fromrgb(54,58,79));
        T('Catppuccin Frappe', fromrgb(202,158,230), fromrgb(48,52,70), fromrgb(65,69,89));
        T('Catppuccin Latte', fromrgb(136,57,239), fromrgb(239,241,245), fromrgb(230,233,239), true);
        T('Coffee', fromrgb(198,146,98), fromrgb(28,22,18), fromrgb(42,34,28));
        T('Espresso', fromrgb(180,120,80), fromrgb(20,16,14), fromrgb(34,28,24));
        T('Latte Soft', fromrgb(166,120,80), fromrgb(245,240,232), fromrgb(232,224,212), true);
        T('Tokyo Night', fromrgb(122,162,247), fromrgb(26,27,38), fromrgb(36,40,59));
        T('Tokyo Storm', fromrgb(125,207,255), fromrgb(36,40,59), fromrgb(45,50,72));
        T('Dracula', fromrgb(189,147,249), fromrgb(40,42,54), fromrgb(68,71,90));
        T('Nord', fromrgb(136,192,208), fromrgb(46,52,64), fromrgb(59,66,82));
        T('Gruvbox Dark', fromrgb(251,184,108), fromrgb(40,40,40), fromrgb(60,56,54));
        T('Gruvbox Soft', fromrgb(254,128,25), fromrgb(50,48,47), fromrgb(60,56,54));
        T('Everforest', fromrgb(167,192,128), fromrgb(39,46,51), fromrgb(55,64,70));
        T('Rose Pine', fromrgb(235,188,186), fromrgb(25,23,36), fromrgb(38,35,50));
        T('Rose Pine Moon', fromrgb(196,167,231), fromrgb(35,33,54), fromrgb(42,39,63));
        T('Rose Pine Dawn', fromrgb(215,130,126), fromrgb(250,244,237), fromrgb(242,233,222), true);
        T('One Dark', fromrgb(97,175,239), fromrgb(40,44,52), fromrgb(50,56,66));
        T('One Dark Pro', fromrgb(198,120,221), fromrgb(33,37,43), fromrgb(44,49,58));
        T('Kanagawa', fromrgb(122,168,159), fromrgb(31,31,40), fromrgb(45,45,58));
        T('Kanagawa Dragon', fromrgb(140,160,140), fromrgb(24,24,29), fromrgb(36,36,44));
        T('Oxocarbon', fromrgb(120,169,255), fromrgb(22,22,22), fromrgb(38,38,38));
        T('Ayu Dark', fromrgb(255,180,84), fromrgb(15,20,25), fromrgb(28,35,43));
        T('Ayu Mirage', fromrgb(255,204,102), fromrgb(31,36,48), fromrgb(45,52,70));
        T('Solarized Dark', fromrgb(38,139,210), fromrgb(0,43,54), fromrgb(7,54,66));
        T('Solarized Light', fromrgb(38,139,210), fromrgb(253,246,227), fromrgb(238,232,213), true);
        T('Monokai Pro', fromrgb(255,216,102), fromrgb(45,42,46), fromrgb(56,53,58));
        T('Synthwave', fromrgb(255,123,201), fromrgb(30,20,40), fromrgb(46,32,62));
        T('Cyberpunk', fromrgb(0,255,200), fromrgb(12,12,20), fromrgb(24,24,40));
        T('Neon Pink', fromrgb(255,80,180), fromrgb(16,12,18), fromrgb(30,22,34));
        T('Ocean', fromrgb(80,190,255), fromrgb(12,20,28), fromrgb(22,34,46));
        T('Forest', fromrgb(120,200,120), fromrgb(14,20,16), fromrgb(24,34,28));
        T('Crimson', fromrgb(220,60,80), fromrgb(20,12,14), fromrgb(36,20,24));
        T('Amber', fromrgb(255,180,60), fromrgb(20,18,12), fromrgb(36,32,20));
        T('Mint', fromrgb(120,230,190), fromrgb(14,20,18), fromrgb(24,36,32));
        T('Slate', fromrgb(148,163,184), fromrgb(15,23,42), fromrgb(30,41,59));
        T('Zinc', fromrgb(161,161,170), fromrgb(9,9,11), fromrgb(24,24,27));
        T('Graphite', fromrgb(180,180,185), fromrgb(22,22,24), fromrgb(36,36,40));
        T('Midnight', fromrgb(99,102,241), fromrgb(8,10,20), fromrgb(18,22,36));
        T('Purple Haze', fromrgb(168,85,247), fromrgb(18,12,28), fromrgb(32,22,48));
        T('Blood', fromrgb(190,30,45), fromrgb(18,10,12), fromrgb(32,16,20));
        T('Matrix', fromrgb(0,255,70), fromrgb(6,10,6), fromrgb(12,20,12));
        T('Vaporwave', fromrgb(255,113,206), fromrgb(26,16,48), fromrgb(42,28,72));
        T('Ice', fromrgb(165,220,255), fromrgb(16,22,30), fromrgb(28,38,50));
        T('Sunset', fromrgb(255,140,90), fromrgb(28,16,20), fromrgb(44,26,32));
        T('Gamesense', fromrgb(147,184,26), fromrgb(17,17,17), fromrgb(28,28,28));
        T('Twitch', fromrgb(169,112,255), fromrgb(14,14,14), fromrgb(31,31,35));
        T('Nekocheat', fromrgb(226,30,112), fromrgb(18,18,18), fromrgb(23,23,23));
        T('Fatality', fromrgb(197,7,83), fromrgb(25,19,53), fromrgb(29,23,66));
        T('Breeze', fromrgb(61,174,233), fromrgb(35,38,41), fromrgb(49,54,59));
        T('Material Dark', fromrgb(128,203,196), fromrgb(33,33,33), fromrgb(48,48,48));
        T('GitHub Dark', fromrgb(88,166,255), fromrgb(13,17,23), fromrgb(22,27,34));
        T('Cursor Dark', fromrgb(130,160,255), fromrgb(20,20,22), fromrgb(32,32,36));
        T('Ember', fromrgb(255,110,70), fromrgb(22,12,10), fromrgb(38,20,16));
        T('Cobalt', fromrgb(56,140,255), fromrgb(10,14,24), fromrgb(18,28,46));
        T('Sakura', fromrgb(255,150,190), fromrgb(24,16,22), fromrgb(40,26,36));
        T('Nocturne', fromrgb(120,100,255), fromrgb(8,8,14), fromrgb(18,18,30));
        T('Honey', fromrgb(255,196,70), fromrgb(22,18,10), fromrgb(38,32,18));
        T('Poison', fromrgb(160,255,80), fromrgb(10,16,10), fromrgb(18,30,18));
        T('Arctic', fromrgb(180,230,255), fromrgb(12,18,24), fromrgb(22,32,42));
        T('Copper', fromrgb(210,120,70), fromrgb(20,14,12), fromrgb(36,24,20));
        T('Phantom', fromrgb(200,200,220), fromrgb(10,10,14), fromrgb(22,22,28));
    }
    library.currentTheme = 'Sonata'
end

function library:SelectTheme(name)
    if typeof(name) ~= 'string' then
        return false
    end
    for _, entry in self.themes do
        if entry.name == name then
            self.currentTheme = name
            if type(self.SetTheme) == 'function' then
                self:SetTheme(entry.theme)
            else
                for k, v in next, entry.theme do
                    self.theme[k] = v
                end
                if type(self.UpdateThemeColors) == 'function' then
                    self.UpdateThemeColors()
                end
            end
            local accentOpt = self.options and self.options.ui_accent
            if accentOpt and type(accentOpt.SetColor) == 'function' then
                pcall(function()
                    accentOpt:SetColor(self.theme.Accent, true)
                end)
            end
            return true
        end
    end
    return false
end

local blacklistedKeys = {
    Enum.KeyCode.Unknown,
    Enum.KeyCode.W,
    Enum.KeyCode.A,
    Enum.KeyCode.S,
    Enum.KeyCode.D,
    Enum.KeyCode.Slash,
    Enum.KeyCode.Tab,
    Enum.KeyCode.Escape
}

local whitelistedBoxKeys = {
    Enum.KeyCode.Zero,
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Six,
    Enum.KeyCode.Seven,
    Enum.KeyCode.Eight,
    Enum.KeyCode.Nine,
    Enum.KeyCode.Period,
    Enum.KeyCode.Slash,
    Enum.KeyCode.Comma,
    Enum.KeyCode.Semicolon,
    Enum.KeyCode.Quote,
    Enum.KeyCode.LeftBracket,
    Enum.KeyCode.RightBracket,
    Enum.KeyCode.BackSlash,
    Enum.KeyCode.Minus,
    Enum.KeyCode.Equals,
    Enum.KeyCode.Backquote,
    Enum.KeyCode.Space,
}

local boxKeyChars = {
    [Enum.KeyCode.Space] = {' ', ' '},
    [Enum.KeyCode.Period] = {'.', '>'},
    [Enum.KeyCode.Slash] = {'/', '?'},
    [Enum.KeyCode.Comma] = {',', '<'},
    [Enum.KeyCode.Semicolon] = {';', ':'},
    [Enum.KeyCode.Quote] = {"'", '"'},
    [Enum.KeyCode.LeftBracket] = {'[', '{'},
    [Enum.KeyCode.RightBracket] = {']', '}'},
    [Enum.KeyCode.BackSlash] = {'\\', '|'},
    [Enum.KeyCode.Minus] = {'-', '_'},
    [Enum.KeyCode.Equals] = {'=', '+'},
    [Enum.KeyCode.Backquote] = {'`', '~'},
    [Enum.KeyCode.Zero] = {'0', ')'},
    [Enum.KeyCode.One] = {'1', '!'},
    [Enum.KeyCode.Two] = {'2', '@'},
    [Enum.KeyCode.Three] = {'3', '#'},
    [Enum.KeyCode.Four] = {'4', '$'},
    [Enum.KeyCode.Five] = {'5', '%'},
    [Enum.KeyCode.Six] = {'6', '^'},
    [Enum.KeyCode.Seven] = {'7', '&'},
    [Enum.KeyCode.Eight] = {'8', '*'},
    [Enum.KeyCode.Nine] = {'9', '('},
}

local function boxKeyToChar(keyCode)
    if typeof(keyCode) ~= 'EnumItem' then
        return nil
    end
    local shifted = inputservice:IsKeyDown(Enum.KeyCode.LeftShift) or inputservice:IsKeyDown(Enum.KeyCode.RightShift)
    local pair = boxKeyChars[keyCode]
    if pair then
        return shifted and pair[2] or pair[1]
    end
    local name = keyCode.Name
    if type(name) == 'string' and #name == 1 then
        return shifted and string.upper(name) or string.lower(name)
    end
    return nil
end

local keyNames = {
    [Enum.KeyCode.LeftControl] = 'LCTRL';
    [Enum.KeyCode.RightControl] = 'RCTRL';
    [Enum.KeyCode.LeftShift] = 'LSHIFT';
    [Enum.KeyCode.RightShift] = 'RSHIFT';
    [Enum.UserInputType.MouseButton1] = 'MB1';
    [Enum.UserInputType.MouseButton2] = 'MB2';
    [Enum.UserInputType.MouseButton3] = 'MB3';
}

library.interactiveDrawings = {}
library.button1down = library.signal.new()
library.button1up   = library.signal.new()
library.mousemove   = library.signal.new()
library.unloaded    = library.signal.new();

local button1down, button1up, mousemove = library.button1down, library.button1up, library.mousemove
local mb1down = false;

local utility = library.utility
do

    function utility:Connection(signal, func)
        local c = signal:Connect(func)
        table.insert(library.connections, c)
        return c
    end

    function utility:Instance(class, properties)
        local inst = newInstance(class)
        for prop, val in next, properties or {} do
            local s,e = pcall(function()
                inst[prop] = val
            end)
            if not s then
                if printconsole then printconsole(e, 255,0,0) end
            end
        end
        return inst
    end

    function utility:HasProperty(obj, prop)
        return ({(pcall(function() local a = obj[prop] end))})[1]
    end

    function utility:ToRGB(c3)
        return c3.R*255,c3.G*255,c3.B*255
    end

    function utility:AddRGB(a,b)
        local r1,g1,b1 = self:ToRGB(a);
        local r2,g2,b2 = self:ToRGB(b);
        return fromrgb(clamp(r1+r2,0,255),clamp(g1+g2,0,255),clamp(b1+b2,0,255))
    end

    function utility:ConvertNumberRange(val,oldmin,oldmax,newmin,newmax)
        return (((val - oldmin) * (newmax - newmin)) / (oldmax - oldmin)) + newmin
    end

    function utility:UDim2ToVector2(udim2, vector2)
        local x,y
        x = udim2.X.Offset + self:ConvertNumberRange(udim2.X.Scale,0,1,0,vector2.X)
        y = udim2.Y.Offset + self:ConvertNumberRange(udim2.Y.Scale,0,1,0,vector2.Y)
        return newVector2(x,y)
    end

    function utility:Lerp(a,b,c)
        return a + (b-a) * c
    end

    function utility:Tween(obj, prop, val, time, direction, style)
        if self:HasProperty(obj, prop) then
            if library.tweens[obj] then
                if library.tweens[obj][prop] then
                    library.tweens[obj][prop]:Cancel()
                end
            end

            local startVal = obj[prop];
            local a = 0;
            local duration = math.max(typeof(time) == 'number' and time or 0.2, 0.001);
            local easeStyle = style or (library.anim and library.anim.easing) or Enum.EasingStyle.Quart;
            local easeDir = direction or (library.anim and library.anim.direction) or Enum.EasingDirection.Out;
            local tween = {
                Completed = library.signal.new();
            };

            library.tweens[obj] = library.tweens[obj] or {};
            library.tweens[obj][prop] = tween;

            tween.Connection = self:Connection(runservice.RenderStepped, function(dt)
                a = math.clamp(a + (dt / duration), 0, 1);
                local done = a >= 1 or obj == nil;
                pcall(function()
                    local progress = tweenService:GetValue(a, easeStyle, easeDir)
                    local newVal
                    if typeof(startVal) == 'number' then
                        newVal = utility:Lerp(startVal, val, progress);
                    else
                        newVal = startVal:Lerp(val, progress);
                    end
                    obj[prop] = newVal;
                end)
                if done then
                    pcall(function()
                        obj[prop] = val;
                    end)
                    tween:Cancel();
                end
            end)

            function tween:Cancel()
                if tween.Connection then
                    tween.Connection:Disconnect();
                    tween.Connection = nil
                end
                if library.tweens[obj] and library.tweens[obj][prop] == tween then
                    library.tweens[obj][prop] = nil;
                end
                if tween.Completed then
                    tween.Completed:Fire();
                end
            end

            return tween;
        else
            if printconsole then printconsole('unable to tween: invalid property '..tostring(prop)..' for object '..tostring(obj), 255,0,0) end
        end
    end

    function utility:DetectTableChange(indexcallback,newindexcallback)
        if indexcallback == nil then
            warn('DetectTableChange: Argument #1 (indexcallback) is nil, function may not work as expected.')
        elseif newindexcallback == nil then
            warn('DetectTableChange: Argument #2 (newindexcallback) is nil, function may not work as expected.')
        end
        local proxy = newproxy(true);
        local mt = getmetatable(proxy);
        mt.__index = indexcallback
        mt.__newindex = newindexcallback
        return proxy
    end

    function utility:MouseOver(obj, mPos)
        local mousePos = mPos or utility:MouseLocation();
        local p = obj.Position
        local s = obj.Size
        local x1 = p.X
        local y1 = p.Y
        return (mousePos.X >= x1 and mousePos.Y >= y1 and mousePos.X <= x1 + s.X and mousePos.Y <= y1 + s.Y)
    end

    function utility:GetHoverObject(mPos)
        if library.uiDragging then
            return nil
        end
        local mousePos = mPos or utility:MouseLocation()
        local mx = mousePos.X
        local my = mousePos.Y

        local bestObj = nil
        local bestZ = -math.huge
        local list = library.interactiveDrawings or library.drawings
        for _, v in next, list do
            local obj = v.Object
            if obj and obj.Visible and (v.Class == 'Square' or v.Class == 'Image') then
                local z = obj.ZIndex
                if z > bestZ then
                    local p = obj.Position
                    local s = obj.Size
                    local x1 = p.X
                    local y1 = p.Y
                    if mx >= x1 and my >= y1 and mx <= x1 + s.X and my <= y1 + s.Y then
                        bestObj = obj
                        bestZ = z
                    end
                end
            end
        end
        return bestObj
    end

    function utility:ApplyThemeColor(drawing)
        if not drawing or not drawing.Object then
            return
        end
        if drawing.ThemeColor and library.theme[drawing.ThemeColor] then
            drawing.Object.Color = utility:AddRGB(
                library.theme[drawing.ThemeColor],
                fromrgb(drawing.ThemeColorOffset or 0, drawing.ThemeColorOffset or 0, drawing.ThemeColorOffset or 0)
            )
        end
        local outlineKey = drawing.OutlineThemeColor or drawing.ThemeColorOutline
        if outlineKey and library.theme[outlineKey] then
            local offset = drawing.OutlineThemeColorOffset or 0
            drawing.Object.OutlineColor = utility:AddRGB(
                library.theme[outlineKey],
                fromrgb(offset, offset, offset)
            )
        end
        if drawing._roundGeom then
            utility:SyncRoundGeometry(drawing)
        end
    end

    function utility:DestroyRoundGeometry(drawing)
        if not drawing or type(drawing._roundGeom) ~= 'table' then
            return
        end
        for _, part in next, drawing._roundGeom do
            pcall(function()
                part:Remove()
            end)
        end
        drawing._roundGeom = nil
    end

    function utility:EnsureRoundGeometry(drawing)
        if not drawing or drawing._roundGeom or not drawing.Object then
            return
        end
        local geom = {}
        local function makeSquare()
            local s = Drawing.new('Square')
            s.Filled = true
            s.Thickness = 0
            s.Visible = false
            return s
        end
        local function makeCircle()
            local c = Drawing.new('Circle')
            c.Filled = true
            c.Thickness = 0
            c.NumSides = 24
            c.Visible = false
            return c
        end
        geom.mid = makeSquare()
        geom.top = makeSquare()
        geom.bottom = makeSquare()
        geom.left = makeSquare()
        geom.right = makeSquare()
        geom.tl = makeCircle()
        geom.tr = makeCircle()
        geom.bl = makeCircle()
        geom.br = makeCircle()
        drawing._roundGeom = geom
        drawing._roundBaseTransparency = 1
    end

    function utility:SyncRoundGeometry(drawing)
        local geom = drawing and drawing._roundGeom
        local obj = drawing and drawing.Object
        if not geom or not obj then
            return
        end
        if not obj.Visible then
            if geom._lastVis ~= false then
                geom._lastVis = false
                for k, part in next, geom do
                    if type(k) == "string" and k:sub(1, 1) ~= "_" and part then
                        pcall(function() part.Visible = false end)
                    end
                end
            end
            return
        end
        local pos, size = utility:RealRect(obj)
        if typeof(size) ~= 'Vector2' or typeof(pos) ~= 'Vector2' then
            return
        end
        local want = math.floor((library.uiRadius or 5) * (library.dpi or 1) + 0.5)
        local r = math.min(want, math.floor(math.min(size.X, size.Y) * 0.5))
        local baseT = drawing._roundBaseTransparency
        if typeof(baseT) ~= 'number' then
            baseT = 1
        end
        if r < 2 or size.X < 4 or size.Y < 4 or baseT <= 0.001 then
            obj.Transparency = baseT
            if geom._lastVis ~= false then
                geom._lastVis = false
                for k, part in next, geom do
                    if type(k) == "string" and k:sub(1, 1) ~= "_" and part then
                        pcall(function() part.Visible = false end)
                    end
                end
            end
            return
        end

        local color = obj.Color
        local z = obj.ZIndex
        if geom._lastVis == true and geom._lastPos == pos and geom._lastSize == size and geom._lastColor == color and geom._lastZ == z and geom._lastT == baseT and geom._lastR == r then
            return
        end
        geom._lastVis = true
        geom._lastPos = pos
        geom._lastSize = size
        geom._lastColor = color
        geom._lastZ = z
        geom._lastT = baseT
        geom._lastR = r

        local w, h = size.X, size.Y
        local innerW = math.max(0, w - 2 * r)
        local innerH = math.max(0, h - 2 * r)

        obj.Transparency = 0

        local function paintSquare(part, p, s)
            part.Color = color
            part.ZIndex = z
            part.Transparency = baseT
            part.Position = p
            part.Size = s
            part.Visible = s.X > 0 and s.Y > 0
        end
        local function paintCircle(part, center)
            part.Color = color
            part.ZIndex = z
            part.Transparency = baseT
            part.Radius = r
            part.Position = center
            part.Visible = true
        end

        paintSquare(geom.mid, pos + newVector2(r, r), newVector2(innerW, innerH))
        paintSquare(geom.top, pos + newVector2(r, 0), newVector2(innerW, r))
        paintSquare(geom.bottom, pos + newVector2(r, h - r), newVector2(innerW, r))
        paintSquare(geom.left, pos + newVector2(0, r), newVector2(r, innerH))
        paintSquare(geom.right, pos + newVector2(w - r, r), newVector2(r, innerH))
        paintCircle(geom.tl, pos + newVector2(r, r))
        paintCircle(geom.tr, pos + newVector2(w - r, r))
        paintCircle(geom.bl, pos + newVector2(r, h - r))
        paintCircle(geom.br, pos + newVector2(w - r, h - r))
    end

    function utility:DetachChild(parent, child)
        if type(parent) ~= 'table' or type(child) ~= 'table' or type(parent.Children) ~= 'table' then
            return
        end
        local kids = parent.Children
        for i = #kids, 1, -1 do
            if kids[i] == child then
                table.remove(kids, i)
            end
        end
        kids[child] = nil
        if child.Object then
            kids[child.Object] = nil
        end
    end

    function utility:OffsetDrawingTree(rootDrawing, delta)
        if not rootDrawing or not rootDrawing.Object then
            return
        end
        local seen = {}
        local stack = { rootDrawing }
        while #stack > 0 do
            local node = table.remove(stack)
            if seen[node] then
                continue
            end
            seen[node] = true
            local obj = node.Object
            if obj then
                obj.Position = obj.Position + delta
            end
            if node._roundGeom then
                pcall(utility.SyncRoundGeometry, utility, node)
            end
            local children = node.Children
            if children then
                for _, child in next, children do
                    if typeof(child) == 'table' and not seen[child] then
                        stack[#stack + 1] = child
                    end
                end
            end
        end
    end

    library.dpi = library.dpi or 1
    library.dpiChanged = library.dpiChanged or library.signal.new()
    local objectMeta = setmetatable({}, { __mode = 'k' })
    library.objectMeta = objectMeta
    local ZERO2 = newVector2(0, 0)

    local function snap(v)
        return math.floor(v + 0.5)
    end

    local function scaleOffset(v, d)
        if v > -2.5 and v < 2.5 then
            return snap(v)
        end
        return snap(v * d)
    end

    function utility:Viewport()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize
        local d = library.dpi or 1
        if typeof(vp) ~= 'Vector2' or vp.X < 2 or vp.Y < 2 then
            if library._lastViewport then
                return library._lastViewport
            end
            vp = newVector2(1280, 720)
        end
        local scaled = d == 1 and vp or vp / d
        library._lastViewport = scaled
        return scaled
    end

    function utility:MouseLocation()
        local pos = inputservice:GetMouseLocation()
        local d = library.dpi or 1
        return d == 1 and pos or pos / d
    end

    function utility:RealRect(obj)
        local meta = objectMeta[obj]
        if meta and meta.rpos then
            return meta.rpos, meta.rsize or ZERO2
        end
        return obj.Position, obj.Size
    end

    local function parentMetaOf(meta)
        local owner = meta.owner
        local parent = owner and owner.Parent
        local parentObj = parent and parent.Object
        return parentObj and objectMeta[parentObj] or nil
    end

    local function applyRect(meta)
        local raw = meta.raw
        local d = library.dpi or 1
        local L = meta.pos or ZERO2
        local pm = parentMetaOf(meta)
        local rx, ry
        if pm and pm.rpos then
            local pl = pm.pos or ZERO2
            rx = pm.rpos.X + scaleOffset(L.X - pl.X, d)
            ry = pm.rpos.Y + scaleOffset(L.Y - pl.Y, d)
        else
            rx = snap(L.X * d)
            ry = snap(L.Y * d)
        end
        local rpos = newVector2(rx, ry)
        meta.rpos = rpos
        if meta.hasRect then
            local W = meta.size or ZERO2
            local rw, rh
            if pm and pm.rsize and pm.size then
                local dw = W.X - pm.size.X
                local dh = W.Y - pm.size.Y
                rw = (dw > -4.5 and dw < 4.5) and (pm.rsize.X + snap(dw)) or snap(W.X * d)
                rh = (dh > -4.5 and dh < 4.5) and (pm.rsize.Y + snap(dh)) or snap(W.Y * d)
            else
                rw = snap(W.X * d)
                rh = snap(W.Y * d)
            end
            local rsize = newVector2(math.max(0, rw), math.max(0, rh))
            meta.rsize = rsize
            if raw.Size ~= rsize then
                raw.Size = rsize
            end
        end
        if raw.Position ~= rpos then
            raw.Position = rpos
        end
    end

    local function applyScalar(meta, key)
        local raw = meta.raw
        local d = library.dpi or 1
        local v = meta.scalars[key]
        if v == nil then
            return
        end
        if key == 'TextSize' then
            raw.Size = math.max(1, snap(v * d))
        elseif key == 'Radius' then
            raw.Radius = v * d
        elseif typeof(v) == 'Vector2' then
            raw[key] = v * d
        end
    end

    local pointKeys = { PointA = true, PointB = true, PointC = true, PointD = true, From = true, To = true }

    function utility:NewObject(class, owner)
        local raw = Drawing.new(class)
        local meta = {
            raw = raw,
            owner = owner,
            class = class,
            hasRect = class == 'Square' or class == 'Image',
            scalars = {},
        }
        local wrapper = {}
        local function remove()
            pcall(function()
                raw:Remove()
            end)
        end
        meta.reapply = function()
            for key in next, meta.scalars do
                applyScalar(meta, key)
            end
            if meta.pos or meta.size then
                applyRect(meta)
            end
        end
        setmetatable(wrapper, {
            __index = function(_, k)
                if k == 'Position' then
                    if meta.pos then
                        return meta.pos
                    end
                    local d = library.dpi or 1
                    return raw.Position / d
                elseif k == 'Size' then
                    if class == 'Text' then
                        return meta.scalars.TextSize or raw.Size
                    end
                    if meta.size then
                        return meta.size
                    end
                    local d = library.dpi or 1
                    return raw.Size / d
                elseif k == 'TextBounds' then
                    local d = library.dpi or 1
                    local tb = raw.TextBounds
                    return d == 1 and tb or tb / d
                elseif k == 'Radius' then
                    return meta.scalars.Radius or raw.Radius
                elseif pointKeys[k] then
                    return meta.scalars[k] or raw[k]
                elseif k == 'Remove' or k == 'Destroy' then
                    return remove
                end
                return raw[k]
            end,
            __newindex = function(_, k, v)
                if k == 'Position' and typeof(v) == 'Vector2' then
                    meta.pos = v
                    applyRect(meta)
                elseif k == 'Size' and class == 'Text' and typeof(v) == 'number' then
                    meta.scalars.TextSize = v
                    applyScalar(meta, 'TextSize')
                elseif k == 'Size' and meta.hasRect and typeof(v) == 'Vector2' then
                    meta.size = v
                    applyRect(meta)
                elseif k == 'Radius' and typeof(v) == 'number' then
                    meta.scalars.Radius = v
                    applyScalar(meta, 'Radius')
                elseif pointKeys[k] and typeof(v) == 'Vector2' then
                    meta.scalars[k] = v
                    applyScalar(meta, k)
                else
                    raw[k] = v
                end
            end,
        })
        objectMeta[wrapper] = meta
        return wrapper
    end

    function library:SetDPI(scale)
        scale = math.clamp(tonumber(scale) or 1, 0.5, 2)
        if math.abs(scale - (self.dpi or 1)) < 1e-3 then
            return
        end
        self.dpi = scale
        for _, meta in next, objectMeta do
            for key in next, meta.scalars do
                pcall(applyScalar, meta, key)
            end
        end
        for _, drawing in next, self.drawings do
            if type(drawing) == 'table' and drawing.Parent == nil and drawing.Update then
                pcall(drawing.Update, drawing)
            end
        end
        local vp = utility:Viewport()
        for _, window in next, self.windows or {} do
            pcall(function()
                local bg = window.objects.background
                local obj = bg.Object
                local maxX = math.max(0, vp.X - obj.Size.X)
                local maxY = math.max(0, vp.Y - obj.Size.Y)
                local x = math.clamp(obj.Position.X, 0, maxX)
                local y = math.clamp(obj.Position.Y, 0, maxY)
                if x ~= obj.Position.X or y ~= obj.Position.Y then
                    bg.Position = newUDim2(0, math.floor(x + 0.5), 0, math.floor(y + 0.5))
                end
                window:UpdateTabs()
            end)
        end
        for _, indicator in next, self.indicators or {} do
            pcall(function()
                indicator:Update()
            end)
        end
        pcall(function()
            if self.watermark and self.watermark.Update then
                self.watermark:Update()
            end
        end)
        pcall(function()
            self.dpiChanged:Fire(scale)
        end)
    end

    function utility:Draw(class, properties)
        local blacklistedProperties = {'Object','Children','Class','_rounded','_roundGeom','_roundBaseTransparency','Rounded','RoundCorners'}
        properties = typeof(properties) == 'table' and properties or {}

        if class == 'Square' and properties.Filled == nil then
            properties.Filled = true;
        end
        if properties.Visible == nil then
            properties.Visible = true;
        end

        local wantRound = class == 'Square'
            and (properties.Rounded == true or properties.RoundCorners == true)
            and properties.Filled ~= false
            and properties.Transparency ~= 0
        properties.Rounded = nil
        properties.RoundCorners = nil

        local drawing = {
            Children = {};
            ThemeColor = '';
            OutlineThemeColor = '';
            ThemeColorOffset = 0;
            OutlineThemeColorOffset = 0;
            Parent = nil;
            Size = newUDim2(0,0,0,0);
            Position = newUDim2(0,0,0,0);
            AbsoluteSize = newVector2(0,0);
            AbsolutePosition = newVector2(0,0);
            Hover = false;
            Visible = true;
            MouseButton1Down = library.signal.new();
            MouseButton2Down = library.signal.new();
            MouseButton1Up = library.signal.new();
            MouseButton2Up = library.signal.new();
            MouseEnter = library.signal.new();
            MouseLeave = library.signal.new();
            Class = class;
            _rounded = wantRound;
            _roundBaseTransparency = 1;
            From = newUDim2(0,0,0,0);
            To = newUDim2(0,0,0,0);
        }
        drawing.MouseButton1Down._drawing = drawing
        drawing.MouseButton2Down._drawing = drawing
        drawing.MouseButton1Up._drawing = drawing
        drawing.MouseButton2Up._drawing = drawing
        drawing.MouseEnter._drawing = drawing
        drawing.MouseLeave._drawing = drawing
        drawing.Object = utility:NewObject(class, drawing)

        if wantRound then
            utility:EnsureRoundGeometry(drawing)
        end

        function drawing:Update()
            local parent = drawing.Parent ~= nil and library.drawings[drawing.Parent.Object] or nil
            local parentSize,parentPos,parentVis = utility:Viewport(), Vector2.new(0,0), true;
            if parent ~= nil then
                parentSize = (parent.Class == 'Square' or parent.Class == 'Image') and parent.Object.Size or parent.Class == 'Text' and parent.Object.TextBounds or utility:Viewport()
                parentPos = parent.Object.Position
                parentVis = parent.Object.Visible
            end

            local isVis = (parentVis and drawing.Visible) and true or false
            if drawing.Object.Visible ~= isVis then
                drawing.Object.Visible = isVis
            end

            if not isVis then
                if drawing._roundGeom and drawing._roundGeom._lastVis ~= false then
                    utility:SyncRoundGeometry(drawing)
                end
                for _, v in next, drawing.Children do
                    if typeof(v) == 'table' and v.Object and v.Object.Visible then
                        v.Object.Visible = false
                    end
                    if typeof(v) == 'table' and v.Update then
                        v:Update()
                    end
                end
                return
            end

            local sizeKnown = parentSize.X >= 1 and parentSize.Y >= 1
            if sizeKnown and (drawing.Class == 'Square' or drawing.Class == 'Image') then
                drawing.Object.Size = typeof(drawing.Size) == 'Vector2' and drawing.Size or typeof(drawing.Size) == 'UDim2' and utility:UDim2ToVector2(drawing.Size,parentSize)
            end

            if sizeKnown and (drawing.Class == 'Square' or drawing.Class == 'Image' or drawing.Class == 'Circle' or drawing.Class == 'Text') then
                drawing.Object.Position = parentPos + (typeof(drawing.Position) == 'Vector2' and drawing.Position or utility:UDim2ToVector2(drawing.Position,parentSize))
            end

            if sizeKnown and drawing.Class == 'Line' then
                if drawing.From then
                    local pt = typeof(drawing.From) == 'Vector2' and drawing.From or utility:UDim2ToVector2(drawing.From, parentSize)
                    drawing.Object.From = parentPos + pt
                end
                if drawing.To then
                    local pt = typeof(drawing.To) == 'Vector2' and drawing.To or utility:UDim2ToVector2(drawing.To, parentSize)
                    drawing.Object.To = parentPos + pt
                end
            end

            if drawing.Class == 'Text' then
                if typeof(drawing.Text) == 'string' and drawing.Object.Text ~= drawing.Text then
                    drawing.Object.Text = drawing.Text
                end
                if typeof(drawing.Size) == 'number' then
                    drawing.Object.Size = drawing.Size
                end
                local textT = typeof(drawing.Transparency) == 'number' and drawing.Transparency or 0
                if drawing.Object.Transparency ~= textT then
                    drawing.Object.Transparency = textT
                end
                utility:ApplyThemeColor(drawing)
            end

            if drawing._roundGeom then
                utility:SyncRoundGeometry(drawing)
            end
            drawing:UpdateChildren()
        end

        function drawing:UpdateChildren()
            for i,v in next, drawing.Children do
                if typeof(v) == 'table' and v.Update then
                    v:Update()
                end
            end
        end

        function drawing:GetDescendants()
            local descendants = {};
            local seen = {}
            local function a(t)
                for _,v in next, t.Children do
                    if typeof(v) == 'table' and not seen[v] then
                        seen[v] = true
                        table.insert(descendants, v);
                        a(v)
                    end
                end
            end
            a(self)
            return descendants;
        end

        library.drawings[drawing.Object] = drawing

        local proxy = utility:DetectTableChange(
        function(obj,i)
            return drawing[i] == nil and drawing.Object[i] or drawing[i]
        end,
        function(obj,i,v)
            if not table.find(blacklistedProperties,i) then

                local lastval = drawing[i]
                if lastval == v and i ~= 'Parent' then
                    return
                end

                if i == 'Size' and (class == 'Square' or class == 'Image') then
                    drawing.Object.Size = utility:UDim2ToVector2(v,drawing.Parent == nil and utility:Viewport() or drawing.Parent.Object.Size);
                    drawing.AbsoluteSize = drawing.Object.Size;
                elseif i == 'Position' and (class == 'Square' or class == 'Image' or class == 'Text') then
                    drawing.Object.Position =  utility:UDim2ToVector2(v,drawing.Parent == nil and newVector2(0,0) or drawing.Parent.Object.Position);
                    drawing.AbsolutePosition = drawing.Object.Position;
                elseif (i == 'From' or i == 'To') and class == 'Line' then
                    local parent = drawing.Parent ~= nil and library.drawings[drawing.Parent.Object] or nil
                    local pPos = parent ~= nil and parent.Object.Position or newVector2(0,0)
                    local pSize = parent ~= nil and ((parent.Class == 'Square' or parent.Class == 'Image') and parent.Object.Size or utility:Viewport()) or utility:Viewport()
                    local pt = typeof(v) == 'Vector2' and v or utility:UDim2ToVector2(v, pSize)
                    drawing.Object[i] = pPos + pt
                elseif i == 'Parent' then
                    if drawing.Parent == v then
                        drawing[i] = v
                        return
                    end
                    if drawing.Parent ~= nil then
                        utility:DetachChild(drawing.Parent, drawing)
                    end
                    if v ~= nil then
                        table.insert(v.Children, drawing)
                    end
                elseif i == 'Visible' then
                    drawing.Visible = v
                elseif i == 'Transparency' and drawing._roundGeom then
                    drawing._roundBaseTransparency = v
                elseif i == 'Font' and v == 2 and executor == 'ScriptWare' then
                    v = 1
                end

                local isGeomProp = (i == 'Size' or i == 'Position' or i == 'From' or i == 'To' or i == 'Parent')
                if not isGeomProp then
                    pcall(function()
                        drawing.Object[i] = v
                    end)
                end
                drawing[i] = v

                if table.find({'Size','Position','Visible','Parent','Transparency','Color','ZIndex','From','To'},i) then
                    drawing:Update()
                end
                if table.find({'ThemeColor','OutlineThemeColor','ThemeColorOffset','OutlineThemeColorOffset'},i) and lastval ~= v then
                    utility:ApplyThemeColor(drawing)
                end

            end
        end)

        function drawing:Remove()
            for i,v in next, self.Children do
                if typeof(v) == 'table' and v.Remove then
                    v:Remove();
                end
            end

            if drawing.Parent then
                utility:DetachChild(drawing.Parent, drawing)
            end

            utility:DestroyRoundGeometry(drawing)
            library.drawings[drawing.Object] = nil;
            if library.interactiveDrawings then
                library.interactiveDrawings[drawing.Object] = nil
            end
            drawing.Object:Remove();
            table.clear(drawing);

        end

        for i,v in next, properties do
            proxy[i] = v
        end

        if drawing._roundGeom then
            if typeof(properties.Transparency) == 'number' then
                drawing._roundBaseTransparency = properties.Transparency
            end
            utility:SyncRoundGeometry(drawing)
        else
            local r = library.uiRadius or 5
            pcall(function()
                drawing.Object.Radius = r
            end)
            pcall(function()
                drawing.Object.Roundness = r
            end)
        end

        drawing:Update()
        return proxy
    end
end

library.utility = utility

function library:Unload()
    library.unloaded:Fire();
    for _,c in next, self.connections do
        c:Disconnect()
    end
    for obj, drawing in next, self.drawings do
        if type(drawing) == 'table' then
            utility:DestroyRoundGeometry(drawing)
        end
        pcall(function()
            obj:Remove()
        end)
    end
    table.clear(self.drawings)
    envTable().library = nil
end

function library:init()
    if self.hasInit then
        return
    end

    local tooltipObjects = {};

    local function ensureFolder(path)
        if typeof(makefolder) ~= 'function' then
            return
        end
        if typeof(isfolder) == 'function' then
            local ok, exists = pcall(isfolder, path)
            if ok and exists then
                return
            end
        end
        pcall(makefolder, path)
    end
    ensureFolder(self.cheatname)
    ensureFolder(self.cheatname..'/assets')
    ensureFolder(self.cheatname..'/'..self.gamename)
    ensureFolder(self.cheatname..'/'..self.gamename..'/configs');

    function self:SetTheme(theme)
        for i,v in next, theme do
            self.theme[i] = v;
        end
        self.UpdateThemeColors();
    end

    function self:GetConfig(name)
        if isfile(self.cheatname..'/'..self.gamename..'/configs/'..name..self.fileext) then
            return readfile(self.cheatname..'/'..self.gamename..'/configs/'..name..self.fileext);
        end
    end

    function self:LoadConfig(name)
        local cfg = self:GetConfig(name)
        if not cfg then
            self:SendNotification('missing · '..tostring(name), 3.5);
            return
        end

        local s,e = pcall(function()
            setByConfig = true
            for flag,value in next, http:JSONDecode(cfg) do
                local option = library.options[flag]
                if option ~= nil then
                    if option.class == 'toggle' then
                        option:SetState(value == nil and false or (value == 1 and true or false));
                    elseif option.class == 'slider' then
                        option:SetValue(value == nil and 0 or value)
                    elseif option.class == 'bind' then
                        option:SetBind(value == nil and 'none' or (utility:HasProperty(Enum.KeyCode, value) and Enum.KeyCode[value] or Enum.UserInputType[value]));
                    elseif option.class == 'color' then
                        local r = value and value[1] or 1
                        local g = value and value[2] or 1
                        local b = value and value[3] or 1
                        if r > 1 or g > 1 or b > 1 then
                            option:SetColor(Color3.fromRGB(r, g, b))
                        else
                            option:SetColor(value == nil and c3new(1,1,1) or c3new(r, g, b))
                        end
                        option:SetTrans(value == nil and 1 or value[4]);
                    elseif option.class == 'list' then
                        option:Select(value == nil and '' or value);
                    elseif option.class == 'box' then
                        option:SetInput(value == nil and '' or value)
                    end
                end
            end
            setByConfig = false
        end)

        if s then
            self:SendNotification('loaded · '..tostring(name), 3.5);
        else
            self:SendNotification('load failed · '..tostring(name), 4);
        end
    end

    function self:SaveConfig(name)
        if not self:GetConfig(name) then
            self:SendNotification('missing · '..tostring(name), 3.5);
            return
        end

        local s,e = pcall(function()
            local cfg = {};
            for flag,option in next, self.options do
                if option.class == 'toggle' then
                    cfg[flag] = option.state and 1 or 0;
                elseif option.class == 'slider' then
                    cfg[flag] = option.value;
                elseif option.class == 'bind' then
                    cfg[flag] = option.bind.Name;
                elseif option.class == 'color' then
                    local c = option.color
                    cfg[flag] = {
                        c.R,
                        c.G,
                        c.B,
                        option.trans,
                    }
                elseif option.class == 'list' then
                    cfg[flag] = option.selected;
                elseif option.class == 'box' then
                    cfg[flag] = option.input
                elseif option.class == 'curve' then
                    cfg[flag] = option.points
                end
            end
            writefile(self.cheatname..'/'..self.gamename..'/configs/'..name..self.fileext, http:JSONEncode(cfg));
        end)

        if s then
            self:SendNotification('saved · '..tostring(name), 3.5);
        else
            self:SendNotification('save failed · '..tostring(name), 4);
        end
    end

    for i,v in next, self.images do
        if type(v) == 'string' and not string.find(v, '^https?://') then
            if v == '' and i == 'pixel' and type(WHITE_PIXEL_PNG) == 'string' then
                self.images[i] = WHITE_PIXEL_PNG
            end
            continue
        end
        local path = self.cheatname..'/assets/'..i..'.oh'
        local hasFile = false
        if typeof(isfile) == 'function' then
            local okFile, exists = pcall(isfile, path)
            hasFile = okFile and exists == true
        end
        if not hasFile and typeof(writefile) == 'function' then
            local okGet, body = pcall(function()
                return game:HttpGet(v)
            end)
            if okGet and type(body) == 'string' and #body > 0 then
                pcall(writefile, path, body)
                hasFile = true
            end
        end
        if hasFile and typeof(readfile) == 'function' then
            local okRead, data = pcall(readfile, path)
            if okRead and type(data) == 'string' then
                self.images[i] = data
            else
                self.images[i] = ''
            end
        else
            self.images[i] = ''
        end
    end

    local CURSOR_RADIUS = 2.2
    local CURSOR_OUTLINE = 1.1
    local CURSOR_A = newVector2(2.4, 2.4)
    local CURSOR_B = newVector2(13.5, 7.2)
    local CURSOR_C = newVector2(7.2, 13.5)

    local function newCursorShape(color, z)
        local shape = { quads = {}, dots = {} }
        shape.tri = utility:Draw('Triangle', {Filled = true, Thickness = 1, Color = color, ZIndex = z})
        for i = 1, 3 do
            shape.quads[i] = utility:Draw('Quad', {Filled = true, Thickness = 1, Color = color, ZIndex = z})
            shape.dots[i] = utility:Draw('Circle', {Filled = true, Thickness = 1, NumSides = 24, Color = color, ZIndex = z})
        end
        return shape
    end

    local function setCursorShapeVisible(shape, visible)
        shape.tri.Visible = visible
        for i = 1, 3 do
            shape.quads[i].Visible = visible
            shape.dots[i].Visible = visible
        end
    end

    local function layoutCursorShape(shape, a, b, c, r)
        local pts = {a, b, c}
        local centroid = (a + b + c) / 3
        shape.tri.PointA = a
        shape.tri.PointB = b
        shape.tri.PointC = c
        for i = 1, 3 do
            local p, q = pts[i], pts[i % 3 + 1]
            local d = q - p
            local n = newVector2(-d.Y, d.X).Unit
            if n:Dot(centroid - p) > 0 then
                n = -n
            end
            local o = n * r
            local quad = shape.quads[i]
            quad.PointA = p
            quad.PointB = q
            quad.PointC = q + o
            quad.PointD = p + o
            local dot = shape.dots[i]
            dot.Position = p
            dot.Radius = r
        end
    end

    self.cursorFill = nil
    self.cursorOutline = nil
    pcall(function()
        self.cursorOutline = newCursorShape(fromrgb(14,14,18), self.zindexOrder.cursor - 1)
        self.cursorFill = newCursorShape(fromrgb(255,255,255), self.zindexOrder.cursor)
    end)

    local lastCursorX, lastCursorY = -1, -1
    local function updateCursor(mPos)
        local fill, outline = self.cursorFill, self.cursorOutline
        if not fill or not outline then
            return
        end
        local show = self.open
        setCursorShapeVisible(fill, show)
        setCursorShapeVisible(outline, show)
        if show then
            local pos = mPos or utility:MouseLocation()
            local px, py = pos.X, pos.Y
            if px == lastCursorX and py == lastCursorY then
                return
            end
            lastCursorX, lastCursorY = px, py
            local a, b, c = pos + CURSOR_A, pos + CURSOR_B, pos + CURSOR_C
            layoutCursorShape(outline, a, b, c, CURSOR_RADIUS + CURSOR_OUTLINE)
            layoutCursorShape(fill, a, b, c, CURSOR_RADIUS)
        else
            lastCursorX, lastCursorY = -1, -1
        end
    end

    local screenGui = Instance.new('ScreenGui');
    screenGui.Name = 'sonata_drawing_input';
    screenGui.ResetOnSpawn = false;
    screenGui.IgnoreGuiInset = true;
    screenGui.DisplayOrder = 999999999;
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(screenGui) end
    end)
    local inputSink = utility:Instance('TextButton', {
        Parent = screenGui,
        Name = 'InputSink',
        Text = '',
        AutoButtonColor = false,
        Modal = true,
        Active = true,
        Selectable = false,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        TextTransparency = 1,
        ZIndex = 1,
    });
    pcall(function()
        inputSink.Interactable = true
    end)

    local function applyMenuCursor(open)
        pcall(function()
            if open then
                inputservice.MouseIconEnabled = false
                inputservice.MouseBehavior = Enum.MouseBehavior.Default
                pcall(function()
                    inputservice.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceHide
                end)
            else
                pcall(function()
                    inputservice.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
                end)
                inputservice.MouseIconEnabled = true
            end
        end)
        local lp = players.LocalPlayer
        local mouse = lp and lp:GetMouse()
        if mouse then
            pcall(function()
                mouse.Icon = ''
            end)
        end
    end

    screenGui.Parent = gs('CoreGui');
    screenGui.Enabled = true;
    applyMenuCursor(true)

    local cursorApplied = false
    utility:Connection(runservice.RenderStepped, function()
        if library.open then
            if not cursorApplied or inputservice.MouseIconEnabled or inputservice.MouseBehavior ~= Enum.MouseBehavior.Default then
                cursorApplied = true
                applyMenuCursor(true)
            end
            updateCursor()
        else
            cursorApplied = false
        end
    end)

    utility:Connection(library.unloaded, function()
        applyMenuCursor(false)
        screenGui:Destroy()
    end)

    utility:Connection(inputservice.InputBegan, function(input, gpe)
        if self.hasInit then
            if input.KeyCode == self.toggleKey and not gpe then
                self:SetOpen(not self.open)
            end
            if library.open then
                local hoverObj = utility:GetHoverObject();
                local hoverObjData = library.drawings[hoverObj];
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mb1down = true;
                    button1down:Fire()
                    if hoverObj and hoverObjData then
                        hoverObjData.MouseButton1Down:Fire(utility:MouseLocation())
                    end

                    if library.draggingSlider ~= nil then
                        local rel = utility:MouseLocation() - library.draggingSlider.objects.background.Object.Position;
                        local val = utility:ConvertNumberRange(rel.X, 0 , library.draggingSlider.objects.background.Object.Size.X, library.draggingSlider.min, library.draggingSlider.max);
                        library.draggingSlider:SetValue(val)
                    end

                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    if hoverObj and hoverObjData then
                        hoverObjData.MouseButton2Down:Fire(utility:MouseLocation())
                    end
                end
            end
        end
    end)

    utility:Connection(inputservice.InputEnded, function(input, gpe)
        if self.hasInit and library.open then
            local hoverObj = utility:GetHoverObject();
            local hoverObjData = library.drawings[hoverObj];

            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mb1down = false;
                if library.draggingSlider then
                    library.draggingSlider.dragging = false
                    library.draggingSlider = nil
                end
                if library.draggingCurve then
                    library.draggingCurve._dragging = false
                    library.draggingCurve._draggingIdx = nil
                    library.draggingCurve = nil
                end
                button1up:Fire();
                if hoverObj and hoverObjData then
                    hoverObjData.MouseButton1Up:Fire(utility:MouseLocation())
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                if hoverObj and hoverObjData then
                    hoverObjData.MouseButton2Up:Fire(utility:MouseLocation())
                end
            end
        end
    end)

    utility:Connection(inputservice.InputChanged, function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if library.open then
                local mousePos = utility:MouseLocation()
                mousemove:Fire(mousePos);
                updateCursor(mousePos);

                if library.uiDragging then
                    return
                end

                if library.draggingSlider ~= nil then
                    if mb1down then
                        local rel = mousePos - library.draggingSlider.objects.background.Object.Position;
                        local val = utility:ConvertNumberRange(rel.X, 0 , library.draggingSlider.objects.background.Object.Size.X, library.draggingSlider.min, library.draggingSlider.max);
                        library.draggingSlider:SetValue(val)
                    else
                        library.draggingSlider.dragging = false
                        library.draggingSlider = nil
                    end
                    return
                end

                if library.draggingCurve ~= nil then
                    local curve = library.draggingCurve
                    if mb1down and curve.objects and curve.objects.graph then
                        local gPos = curve.objects.graph.Object.Position
                        local gSize = curve.objects.graph.Object.Size
                        if gSize.X > 0 and gSize.Y > 0 then
                            local relX = math.clamp((mousePos.X - gPos.X) / gSize.X, 0, 1)
                            local n = #curve.points
                            local idx = curve._draggingIdx or math.clamp(math.round(relX * (n - 1)) + 1, 1, n)
                            curve._draggingIdx = idx
                            local relY = 1 - math.clamp((mousePos.Y - gPos.Y) / gSize.Y, 0, 1)
                            curve.points[idx] = math.clamp(math.round(relY * 100) / 100, 0, 1)
                            curve.preset = 'Custom'
                            if curve.onPresetChanged then
                                curve.onPresetChanged('Custom')
                            end
                            curve:RenderPoints()
                            if curve.flag then
                                library.flags[curve.flag] = curve.points
                            end
                            curve.callback(curve.points, curve)
                        end
                    else
                        curve._dragging = false
                        curve._draggingIdx = nil
                        library.draggingCurve = nil
                    end
                    return
                end

                if library.CurrentTooltip ~= nil then
                    tooltipObjects.background.Position = UDim2.new(0,mousePos.X + 15,0,mousePos.Y + 15)
                    tooltipObjects.background.Size = UDim2.new(0,tooltipObjects.text.TextBounds.X + 6 + (library.CurrentTooltip.risky and 60 or 0),0,tooltipObjects.text.TextBounds.Y + 2)
                end

                local hoverObj = utility:GetHoverObject(mousePos);
                if hoverObj ~= library._lastHoverObj then
                    local prevData = library._lastHoverData
                    if prevData and prevData.Hover then
                        prevData.Hover = false
                        prevData.MouseLeave:Fire(mousePos)
                    end
                    local nextData = hoverObj and library.drawings[hoverObj]
                    if nextData and not nextData.Hover then
                        nextData.Hover = true
                        nextData.MouseEnter:Fire(mousePos)
                    end
                    library._lastHoverObj = hoverObj
                    library._lastHoverData = nextData
                end
            end
        end
    end)

    local function pointerFrom(input)
        local p = input and input.Position
        if typeof(p) == 'Vector3' then
            return newVector2(p.X, p.Y)
        end
        return utility:MouseLocation()
    end

    local function hoverAt(pos)
        return utility:GetHoverObject(pos)
    end

    local function pressAt(pos)
        mb1down = true
        button1down:Fire()
        local hoverObj = hoverAt(pos)
        local hoverObjData = hoverObj and library.drawings[hoverObj]
        if hoverObjData then
            hoverObjData.MouseButton1Down:Fire(pos)
        end
        mousemove:Fire(pos)
    end

    local function releaseAt(pos)
        mb1down = false
        if library.draggingSlider then
            library.draggingSlider.dragging = false
            library.draggingSlider = nil
        end
        if library.draggingCurve then
            library.draggingCurve._dragging = false
            library.draggingCurve._draggingIdx = nil
            library.draggingCurve = nil
        end
        button1up:Fire()
        local hoverObj = hoverAt(pos)
        local hoverObjData = hoverObj and library.drawings[hoverObj]
        if hoverObjData then
            hoverObjData.MouseButton1Up:Fire(pos)
        end
        library.uiDragging = false
    end

    local function moveAt(pos)
        mousemove:Fire(pos)
        if library.draggingSlider ~= nil and mb1down then
            local rel = pos - library.draggingSlider.objects.background.Object.Position
            local val = utility:ConvertNumberRange(rel.X, 0, library.draggingSlider.objects.background.Object.Size.X, library.draggingSlider.min, library.draggingSlider.max)
            library.draggingSlider:SetValue(val)
        end
    end

    local function scrollAt(pos, dy)
        local win = library.windows and library.windows[1]
        if not win or not win.open or not win.selectedTab then
            return false
        end
        if win.dropdown and win.dropdown.selected and win.dropdown.objects and win.dropdown.objects.background and win.dropdown.objects.background.Object then
            local bg = win.dropdown.objects.background.Object
            if bg.Visible and utility:MouseOver(bg, pos) then
                local list = win.dropdown.selected
                local maxVisible = win.dropdown.max or 10
                local maxScroll = math.max(0, #list.values - maxVisible)
                local dir = dy > 0 and -1 or 1
                win.dropdown.scroll = math.clamp((win.dropdown.scroll or 0) + dir, 0, maxScroll)
                win.dropdown:Refresh()
                return true
            end
        end
        local tab = win.selectedTab
        for _, section in next, tab.sections do
            if section.objects.background.Visible then
                for _, opt in next, section.options do
                    if opt.class == 'scrolllist' and opt.enabled and opt.mouseOverList and opt.mouseOverList(pos) then
                        local maxScroll = math.max(0, #opt.values - opt.max)
                        if maxScroll > 0 then
                            local dir = dy > 0 and -1 or 1
                            opt.scroll = math.clamp((opt.scroll or 0) + dir, 0, maxScroll)
                            opt:Refresh()
                        end
                        return true
                    end
                end
            end
        end
        local col1 = win.objects.columnholder1 and win.objects.columnholder1.Object
        local col2 = win.objects.columnholder2 and win.objects.columnholder2.Object
        local view = win.columnView
        local winBg = win.objects.background.Object
        local over1 = col1 and utility:MouseOver(col1, pos)
        local over2 = col2 and utility:MouseOver(col2, pos)
        if not over1 and not over2 and winBg and utility:MouseOver(winBg, pos) then
            local midX = winBg.Position.X + winBg.Size.X * 0.5
            if pos.X < midX then
                over1 = true
            else
                over2 = true
            end
        end
        local idx = over1 and 1 or (over2 and 2 or nil)
        if not idx then
            return false
        end
        local col = idx == 1 and col1 or col2
        local viewH = (view and view[idx]) or (col and col.Size.Y) or 0
        local maxScroll = math.max(0, (win.columnContent[idx] or 0) - viewH)
        local cur = win.columnScrollTarget[idx] or win.columnScroll[idx] or 0
        win.columnScrollTarget[idx] = math.clamp(cur - dy, 0, maxScroll)
        return true
    end

    local touches = {}
    local function cancelTouches()
        for _, touch in next, touches do
            if touch.pressed then
                releaseAt(touch.pos)
            end
        end
        table.clear(touches)
        mb1down = false
        library.uiDragging = false
        if library.touchCancelled then
            library.touchCancelled:Fire()
        end
    end
    library.touchCancelled = library.signal.new()

    utility:Connection(inputservice.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if not self.hasInit or not library.open then
            return
        end
        local pos = pointerFrom(input)
        local function insideGui(gui)
            if not gui or gui.Visible == false then
                return false
            end
            local p = gui.AbsolutePosition
            local s = gui.AbsoluteSize
            return pos.X >= p.X and pos.Y >= p.Y and pos.X <= p.X + s.X and pos.Y <= p.Y + s.Y
        end
        if insideGui(library.menuButton) then
            return
        end
        if library.holdButtons then
            for _, api in next, library.holdButtons do
                if insideGui(api.button) then
                    return
                end
            end
        end
        local hoverObj = hoverAt(pos)
        local data = hoverObj and library.drawings[hoverObj]
        local immediate = data and data._touchDrag == true
        local win = library.windows and library.windows[1]
        if win and win.objects and win.objects.dragdetector and hoverObj == win.objects.dragdetector.Object then
            immediate = true
        end
        touches[input] = { pos = pos, start = pos, pressed = immediate == true, scrolling = false, hover = hoverObj }
        if immediate then
            pressAt(pos)
        end
    end)

    utility:Connection(inputservice.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local touch = touches[input]
        if not touch or not library.open then
            return
        end
        local pos = pointerFrom(input)
        local delta = pos - touch.pos
        local travel = pos - touch.start
        touch.pos = pos
        if touch.pressed then
            moveAt(pos)
            return
        end
        if math.abs(travel.Y) > 12 and math.abs(travel.Y) > math.abs(travel.X) * 0.85 then
            touch.scrolling = true
            scrollAt(touch.start, delta.Y)
            return
        end
        if math.abs(travel.X) > 14 and math.abs(travel.X) > math.abs(travel.Y) then
            touch.pressed = true
            pressAt(touch.start)
            moveAt(pos)
        end
    end)

    utility:Connection(inputservice.InputEnded, function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local touch = touches[input]
        touches[input] = nil
        if not touch or not library.open then
            return
        end
        local pos = pointerFrom(input)
        if touch.pressed then
            releaseAt(pos)
        elseif not touch.scrolling and (pos - touch.start).Magnitude <= 12 then
            pressAt(touch.start)
            releaseAt(pos)
        end
    end)

    utility:Connection(inputservice.WindowFocusReleased, function()
        cancelTouches()
    end)

    local mobileGui = utility:Instance('ScreenGui', {
        Name = 'sonata_mobile',
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 1000000001,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(mobileGui) end
    end)
    mobileGui.Parent = gs('CoreGui')
    library.mobileGui = mobileGui

    local osBox = utility:Instance('TextBox', {
        Parent = mobileGui,
        Size = UDim2.new(0, 1, 0, 1),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        TextTransparency = 1,
        Text = '',
        ClearTextOnFocus = false,
    })
    library._osBox = osBox

    local menuBtn = utility:Instance('TextButton', {
        Parent = mobileGui,
        Name = 'Menu',
        Text = 'menu',
        AutoButtonColor = false,
        BackgroundColor3 = fromrgb(36, 24, 52),
        TextColor3 = fromrgb(244, 244, 246),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Size = UDim2.new(0, 58, 0, 58),
        Position = UDim2.new(0, 14, 0.42, 0),
        ZIndex = 20,
    })
    utility:Instance('UICorner', { Parent = menuBtn, CornerRadius = UDim.new(0, 10) })
    library.menuButton = menuBtn

    local function clampMenuButton()
        local cam = workspace.CurrentCamera
        local vs = cam and cam.ViewportSize or newVector2(800, 600)
        local inset = gs('GuiService'):GetGuiInset()
        local sz = menuBtn.AbsoluteSize
        local x = math.clamp(menuBtn.Position.X.Offset, 6, math.max(6, vs.X - sz.X - 6))
        local y = math.clamp(menuBtn.Position.Y.Offset, inset.Y + 6, math.max(inset.Y + 6, vs.Y - sz.Y - 6))
        menuBtn.Position = UDim2.new(0, x, 0, y)
    end
    library.clampMenuButton = clampMenuButton

    local function applyMenuButtonStyle()
        local size = math.clamp(tonumber(library.flags.mobile_size) or 58, 44, 96)
        local rawOpacity = tonumber(library.flags.mobile_opacity) or 92
        local opacity = math.clamp(rawOpacity > 1 and rawOpacity / 100 or rawOpacity, 0.35, 1)
        menuBtn.Size = UDim2.new(0, size, 0, size)
        menuBtn.TextSize = math.clamp(math.floor(size * 0.26), 12, 22)
        menuBtn.BackgroundTransparency = 1 - opacity
        menuBtn.TextTransparency = 1 - opacity
        if typeof(library.flags.mobile_x) == 'number' and typeof(library.flags.mobile_y) == 'number' then
            menuBtn.Position = UDim2.new(0, library.flags.mobile_x, 0, library.flags.mobile_y)
        end
        clampMenuButton()
    end
    library.applyMenuButtonStyle = applyMenuButtonStyle
    applyMenuButtonStyle()

    local dragBtn = false
    local btnStart = nil
    local btnOrigin = nil
    local btnMoved = false
    menuBtn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        dragBtn = true
        btnMoved = false
        btnStart = newVector2(input.Position.X, input.Position.Y)
        btnOrigin = menuBtn.Position
    end)
    menuBtn.InputChanged:Connect(function(input)
        if not dragBtn then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local pos = newVector2(input.Position.X, input.Position.Y)
        if (pos - btnStart).Magnitude > 8 then
            btnMoved = true
        end
        if btnMoved then
            menuBtn.Position = UDim2.new(0, btnOrigin.X.Offset + (pos.X - btnStart.X), 0, btnOrigin.Y.Offset + (pos.Y - btnStart.Y))
            clampMenuButton()
        end
    end)
    menuBtn.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        dragBtn = false
        if btnMoved then
            library.flags.mobile_x = menuBtn.Position.X.Offset
            library.flags.mobile_y = menuBtn.Position.Y.Offset
            return
        end
        if self.hasInit then
            self:SetOpen(not self.open)
        end
    end)

    library.holdButtons = {}
    function library:HoldButton(id, label)
        local existing = self.holdButtons[id]
        if existing then
            existing.button.Text = label or existing.button.Text
            return existing
        end
        local count = 0
        for _ in next, self.holdButtons do
            count += 1
        end
        local button = utility:Instance('TextButton', {
            Parent = mobileGui,
            Name = 'Hold_' .. tostring(id),
            Text = label or 'hold',
            AutoButtonColor = false,
            BackgroundColor3 = fromrgb(48, 32, 68),
            TextColor3 = fromrgb(244, 244, 246),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Size = UDim2.new(0, 92, 0, 48),
            Position = UDim2.new(1, -106, 1, -64 - count * 56),
            Visible = false,
            ZIndex = 20,
        })
        utility:Instance('UICorner', { Parent = button, CornerRadius = UDim.new(0, 10) })
        local api = { button = button, held = false, onDown = function() end, onUp = function() end }
        local function down()
            if api.held then
                return
            end
            api.held = true
            button.BackgroundColor3 = fromrgb(150, 90, 210)
            api.onDown()
        end
        local function up()
            if not api.held then
                return
            end
            api.held = false
            button.BackgroundColor3 = fromrgb(48, 32, 68)
            api.onUp()
        end
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                down()
            end
        end)
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                up()
            end
        end)
        self.touchCancelled:Connect(up)
        self.holdButtons[id] = api
        return api
    end

    utility:Connection(library.unloaded, function()
        mobileGui:Destroy()
    end)

    local function fitOpenWindow()
        local win = library.windows and library.windows[1]
        if not win or not win.objects or not win.objects.background then
            return
        end
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local vs = cam.ViewportSize
        if typeof(vs) ~= 'Vector2' or vs.X < 50 or vs.Y < 50 then
            return
        end
        local inset = gs('GuiService'):GetGuiInset()
        local wantW = tonumber(library.flags.menu_width) or 520
        local wantH = tonumber(library.flags.menu_height) or 420
        local maxW = math.max(280, vs.X - 12)
        local maxH = math.max(240, vs.Y - inset.Y - 12)
        win:SetSize(math.min(wantW, maxW), math.min(wantH, maxH))
        local bg = win.objects.background
        local obj = bg.Object
        if obj then
            local x = math.clamp(obj.Position.X, 4, math.max(4, vs.X - obj.Size.X - 4))
            local y = math.clamp(obj.Position.Y, inset.Y + 4, math.max(inset.Y + 4, vs.Y - obj.Size.Y - 4))
            if x ~= obj.Position.X or y ~= obj.Position.Y then
                bg.Position = newUDim2(0, x, 0, y)
            end
        end
        if library.open and bg.Update then
            bg:Update()
        end
        if library.clampMenuButton then
            library.clampMenuButton()
        end
    end
    library.fitOpenWindow = fitOpenWindow
    local function bindViewport(cam)
        if library._viewportConn then
            library._viewportConn:Disconnect()
            library._viewportConn = nil
        end
        if not cam then
            return
        end
        library._viewportConn = utility:Connection(cam:GetPropertyChangedSignal('ViewportSize'), function()
            task.defer(fitOpenWindow)
        end)
    end
    bindViewport(workspace.CurrentCamera)
    utility:Connection(workspace:GetPropertyChangedSignal('CurrentCamera'), function()
        bindViewport(workspace.CurrentCamera)
        task.defer(fitOpenWindow)
    end)
    utility:Connection(inputservice.WindowFocused, function()
        task.defer(fitOpenWindow)
    end)
    utility:Connection(inputservice.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.TextInput then
            task.defer(function()
                local win = library.windows and library.windows[1]
                local bg = win and win.objects and win.objects.background
                local obj = bg and bg.Object
                if not obj then
                    return
                end
                local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                if not vs then
                    return
                end
                local lift = math.floor(vs.Y * 0.38)
                if obj.Position.Y + obj.Size.Y > vs.Y - lift then
                    bg.Position = newUDim2(0, obj.Position.X, 0, math.max(8, vs.Y - lift - obj.Size.Y))
                end
            end)
        end
    end)

    function self:SetOpen(bool)
        bool = bool == true
        self.open = bool
        self._openGen = (self._openGen or 0) + 1
        local openGen = self._openGen
        library.opening = false
        screenGui.Enabled = bool
        applyMenuCursor(bool)
        mb1down = false
        library.uiDragging = false
        if library.draggingSlider then
            library.draggingSlider.dragging = false
            library.draggingSlider = nil
        end
        if library._osBox and library._osBox.ReleaseFocus then
            pcall(function()
                library._osBox:ReleaseFocus()
            end)
        end

        if bool and library.flags.disablemenumovement then
            actionservice:BindAction(
                'FreezeMovement',
                function()
                    return Enum.ContextActionResult.Sink
                end,
                false,
                unpack(Enum.PlayerActions:GetEnumItems())
            )
        else
            actionservice:UnbindAction('FreezeMovement');
        end

        updateCursor();
        for _,window in next, self.windows do
            window:SetOpen(bool);
        end

        library.CurrentTooltip = nil;
        tooltipObjects.background.Visible = false
        if bool then
            task.defer(function()
                if self.open and self._openGen == openGen then
                    for _, window in next, self.windows do
                        local root = window.objects and window.objects.background
                        if root and root.Update then
                            root:Update()
                        end
                        if window.selectedTab and window.selectedTab.UpdateSections then
                            window.selectedTab:UpdateSections()
                        end
                    end
                end
            end)
        end
    end

    function self.UpdateThemeColors()
        for _,v in next, library.drawings do
            utility:ApplyThemeColor(v)
        end
    end

    function self:SendNotification(message, time, title, _color)
        local notifyTitle = "getsonata.xyz"
        if typeof(message) == 'table' then
            notifyTitle = message.title or notifyTitle
            time = message.time or time
            _color = message.color or _color
            message = message.text or message.message or ""
        elseif typeof(title) == 'string' and title ~= "" then
            notifyTitle = title
        end

        time = typeof(time) == 'number' and math.clamp(time, 0.75, 20) or 3.5
        if typeof(message) ~= 'string' then
            message = tostring(message or "")
        end
        message = string.gsub(message, '^Successfully%s+', '')
        message = string.gsub(message, '^Error%s+', '')
        message = string.gsub(message, '%s+', ' ')
        message = string.gsub(message, '^%s+', '')
        message = string.gsub(message, '%s+$', '')

        local notification = {};
        self.notifications[notification] = true

        do
            local z = self.zindexOrder.notification;

            notification.holder = utility:Draw('Square', {
                Position = newUDim2(0, 0, 0, 72);
                Transparency = 0;
                Filled = false;
            })

            notification.background = utility:Draw('Square', {
                Size = newUDim2(1, 0, 1, 0);
                Position = newUDim2(0, -420, 0, 0);
                Parent = notification.holder;
                ThemeColor = 'Background';
                ZIndex = z;
                Rounded = true;
            })

            notification.border1 = utility:Draw('Square', {
                Size = newUDim2(1, 2, 1, 2);
                Position = newUDim2(0, -1, 0, -1);
                ThemeColor = 'Border 2';
                Parent = notification.background;
                ZIndex = z - 1;
                Rounded = true;
            })

            notification.border2 = utility:Draw('Square', {
                Size = newUDim2(1, 2, 1, 2);
                Position = newUDim2(0, -1, 0, -1);
                ThemeColor = 'Border 3';
                Parent = notification.border1;
                ZIndex = z - 2;
                Rounded = true;
            })

            notification.title = utility:Draw('Text', {
                Position = newUDim2(0, 14, 0, 6);
                Color = Color3.fromRGB(245, 245, 250);
                Text = notifyTitle;
                Outline = true;
                Font = 2;
                Size = 13;
                ZIndex = z + 4;
                Parent = notification.background;
            })

            notification.text = utility:Draw('Text', {
                Position = newUDim2(0, 14, 0, 22);
                Color = Color3.fromRGB(195, 200, 212);
                Text = message;
                Outline = true;
                Font = 2;
                Size = 12;
                ZIndex = z + 4;
                Parent = notification.background;
            })

            -- Accent underline matching Image 3 style directly beneath the text
            notification.underline = utility:Draw('Square', {
                Size = newUDim2(0, 40, 0, 2);
                Position = newUDim2(0, 14, 0, 37);
                Parent = notification.background;
                ThemeColor = if typeof(_color) == 'Color3' then nil else 'Accent';
                Color = if typeof(_color) == 'Color3' then _color else nil;
                ZIndex = z + 5;
            })
        end

        function notification:Remove()
            library.notifications[notification] = nil;
            self.holder:Remove();
            library:UpdateNotifications()
        end

        task.spawn(function()
            self:UpdateNotifications();
            local tW = notification.title.TextBounds.X
            local mW = notification.text.TextBounds.X
            local width = math.clamp(math.max(tW, mW) + 28, 200, 480)
            local height = 44
            notification.background.Size = newUDim2(0, width, 0, height)
            if notification.underline then
                notification.underline.Size = newUDim2(0, math.max(mW, 30), 0, 2)
            end
            task.wait();
            local anim = library.anim or {}
            local notifyDur = anim.notify or 0.22
            utility:Tween(notification.background, 'Position', newUDim2(0, 14, 0, 0), notifyDur, Enum.EasingDirection.Out, Enum.EasingStyle.Quart);
            task.wait(time);
            for _, v in next, notification do
                if typeof(v) ~= 'function' and typeof(v) ~= 'boolean' then
                    pcall(function()
                        utility:Tween(v, 'Transparency', 0, notifyDur * 0.7);
                    end)
                end
            end
            utility:Connection(utility:Tween(notification.background, 'Position', newUDim2(0, -450, 0, 0), notifyDur, Enum.EasingDirection.In, Enum.EasingStyle.Quart).Completed, function()
                notification:Remove();
            end)
        end)
    end

    function self:UpdateNotifications()
        local i = 0
        local stackDur = (library.anim and library.anim.notifyStack) or 0.2
        for v in next, self.notifications do
            utility:Tween(v.holder, 'Position', newUDim2(0, 0, 0, 72 + (i * 48)), stackDur, Enum.EasingDirection.Out, Enum.EasingStyle.Quart)
            i += 1
        end
    end

    function self.NewIndicator(data)
        local indicator = {
            title = data.title or 'indicator',
            enabled = data.enabled or false,
            position = data.position or newUDim2(0,15,0,300),
            values = {},
            objects = {valueObjects = {}},
            spacing = '   ',
        };

        table.insert(self.indicators, indicator)

        do
            local z = self.zindexOrder.indicator;
            local objs = indicator.objects;

            objs.background = utility:Draw('Square', {
                Size = newUDim2(0, 200, 0, 16);
                Position = indicator.position;
                ThemeColor = 'Background';
                ZIndex = z;
            })

            objs.border1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 2';
                Parent = objs.background;
                ZIndex = z-1;
            })

            objs.border2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                Parent = objs.border1;
                ZIndex = z-2;
            })

            objs.topborder = utility:Draw('Square', {
                Size = newUDim2(1,0,0,1);
                ThemeColor = 'Accent';
                Parent = objs.background;
                ZIndex = z+1;
            })

            objs.textlabel = utility:Draw('Text', {
                Position = newUDim2(.5,0,0,1);
                ThemeColor = 'Primary Text';
                Text = indicator.title;
                Size = 13;
                Font = 2;
                ZIndex = z+2;
                Center = true;
                Outline = true;
                Parent = objs.background;
            });

        end

        function indicator:Update()
            local xSize  = 125
            local yPos  = 0
            table.sort(self.values, function(a,b)
                return a.order < b.order;
            end)

            for _,v in next, self.values do
                v.objects.keyLabel.Text = tostring(v.key);
                v.objects.valueLabel.Text = tostring(v.value);

                v.objects.valueLabel.Position = newUDim2(1,-(v.objects.valueLabel.TextBounds.X + 3),0,0)
                v.objects.background.Position = newUDim2(0,0,1,3 + yPos)
                v.objects.background.Visible = v.enabled

                if v.enabled then
                    yPos = yPos + 16 + 3
                    local x = (v.objects.keyLabel.TextBounds.X + 10 + v.objects.valueLabel.TextBounds.X)
                    if x > xSize then
                        xSize = x
                    end
                end
            end

            self.objects.background.Size = newUDim2(0,xSize + 8,0,16)
            self.objects.background.Position = self.position
        end

        function indicator:AddValue(data)
            local value = {
                key = data.key or '',
                value = data.value or '',
                order = data.order or #self.values+1,
                enabled = data.enabled == nil and true or data.enabled,
                objects = {},
            }

            table.insert(self.values, value);

            do
                local z = library.zindexOrder.indicator;
                local objs = value.objects;

                objs.background = utility:Draw('Square', {
                    Size = newUDim2(1, 0, 0, 16);
                    ThemeColor = 'Background';
                    ZIndex = z;
                    Parent = indicator.objects.background;
                })

                objs.border1 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 2';
                    Parent = objs.background;
                    ZIndex = z-1;
                })

                objs.border2 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 3';
                    Parent = objs.border1;
                    ZIndex = z-2;
                })

                objs.keyLabel = utility:Draw('Text', {
                    Position = newUDim2(0,3,0,1);
                    ThemeColor = 'Option Text 2';
                    Size = 13;
                    Font = 2;
                    ZIndex = z+2;
                    Outline = true;
                    Parent = objs.background;
                });

                objs.valueLabel = utility:Draw('Text', {
                    Position = newUDim2(0,0,0,1);
                    ThemeColor = 'Option Text 2';
                    Size = 13;
                    Font = 2;
                    ZIndex = z+2;
                    Outline = true;
                    Parent = objs.background;
                });

            end

            function value:Remove()
                table.remove(indicator.values, table.find(indicator.values, value))
                self.objects.background:Remove()
                table.clear(self)
                indicator:Update();
            end

            function value:SetEnabled(bool)
                if typeof(bool) == 'boolean' then
                    self.enabled = bool
                    indicator:Update()
                end
            end

            function value:SetValue(str)
                if typeof(str) == 'string' then
                    self.value = str
                    indicator:Update()
                end
            end

            function value:SetKey(str)
                if typeof(str) == 'string' then
                    self.key = str
                    indicator:Update()
                end
            end

            self:Update()
            return value
        end

        function indicator:GetValue(idx)
            if typeof(idx) == 'number' then
                return self.values[idx]
            else
                for i,v in next, self.values do
                    if v.key == idx then
                        return v
                    end
                end
            end
        end

        function indicator:SetEnabled(bool)
            if typeof(bool) == 'boolean' then
                self.enabled = bool;
                self.objects.background.Visible = bool;
                self:Update();
            end
        end

        function indicator:SetPosition(udim2)
            if typeof(udim2) == 'UDim2' then
                self.position = udim2
                self.objects.background.Position = udim2;
            end
        end

        for i,v in next, data.values or {} do
            indicator:AddValue({key = tostring(i), value = tostring(v)})
        end

        indicator:SetEnabled(indicator.enabled);
        return indicator
    end

    function self.NewWindow(data)
        local window = {
            title = data.title or '',
            selectedTab = nil;
            tabs = {},
            objects = {},
            columnScroll = { [1] = 0, [2] = 0 },
            columnScrollTarget = { [1] = 0, [2] = 0 },
            columnContent = { [1] = 0, [2] = 0 },
            colorpicker = {
                objects = {};
                color = c3new(1,0,0);
                trans = 0;
            };
            dropdown = {
                objects = {
                    values = {};
                };
                max = 10;
                scroll = 0;
            }
        };

        table.insert(library.windows, window);

        do
            local size = data.size or newUDim2(0, 520, 0, 420);
            local position = data.position or newUDim2(0, 250, 0, 150);
            local objs = window.objects;
            local z = library.zindexOrder.window;

            objs.background = utility:Draw('Square', {
                Size = size;
                Position = position;
                ThemeColor = 'Background';
                ZIndex = z;
                Rounded = true;
            })

            objs.innerBorder1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                ZIndex = z-1;
                Parent = objs.background;
                Rounded = true;
            })

            objs.innerBorder2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 1';
                ZIndex = z-2;
                Parent = objs.innerBorder1;
                Rounded = true;
            })

            objs.midBorder = utility:Draw('Square', {
                Size = newUDim2(1,10,1,25);
                Position = newUDim2(0,-5,0,-20);
                ThemeColor = 'Border 2';
                ZIndex = z-3;
                Parent = objs.innerBorder2;
                Rounded = true;
            })

            objs.outerBorder1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 1';
                ZIndex = z-4;
                Parent = objs.midBorder;
                Rounded = true;
            })

            objs.outerBorder2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                ZIndex = z-5;
                Parent = objs.outerBorder1;
                Rounded = true;
            })

            objs.topBorder = utility:Draw('Square', {
                Size = newUDim2(1,0,0,1);
                ThemeColor = 'Accent';
                ZIndex = z+55;
                Parent = objs.background;
            })

            objs.titleGet = utility:Draw('Text', {
                Position = newUDim2(0,7,0,2);
                Color = fromrgb(255,255,255);
                ThemeColor = 'Primary Text';
                Text = 'get';
                Font = 2;
                Size = 13;
                ZIndex = z+55;
                Outline = true;
                Parent = objs.midBorder;
            })
            objs.titleName = utility:Draw('Text', {
                Position = newUDim2(0,26,0,2);
                ThemeColor = 'Accent';
                Text = 'sonata';
                Font = 2;
                Size = 13;
                ZIndex = z+55;
                Outline = true;
                Parent = objs.midBorder;
            })
            objs.titleSuffix = utility:Draw('Text', {
                Position = newUDim2(0,68,0,2);
                Color = fromrgb(255,255,255);
                ThemeColor = 'Primary Text';
                Text = '.xyz';
                Font = 2;
                Size = 13;
                ZIndex = z+55;
                Outline = true;
                Parent = objs.midBorder;
            })
            objs.titleRole = utility:Draw('Text', {
                Position = newUDim2(1,-70,0,3);
                Color = fromrgb(255,255,255);
                ThemeColor = 'Primary Text';
                Text = 'developer';
                Font = 2;
                Size = 13;
                ZIndex = z+55;
                Outline = true;
                Parent = objs.midBorder;
            })

            objs.groupBackground = utility:Draw('Square', {
                Size = newUDim2(1,-16,1,-(16+23));
                Position = newUDim2(0,8,0,8+23);
                ThemeColor = 'Group Background';
                ZIndex = z+5;
                Parent = objs.background;
            })

            objs.groupInnerBorder = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 1';
                ZIndex = z+4;
                Parent = objs.groupBackground;
            })

            objs.groupOuterBorder = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                ZIndex = z+3;
                Parent = objs.groupInnerBorder;
            })

            objs.tabHolder = utility:Draw('Square', {
                Size = newUDim2(1,0,0,20);
                Position = newUDim2(0,0,0,-21);
                Parent = objs.groupBackground;
                Transparency = 0;
                Filled = false;
                ZIndex = z+55;
            })

            local contentTop = 10;
            objs.columnholder1 = utility:Draw('Square', {
                Size = newUDim2(.485, 0, 1, -(contentTop + 8));
                Position = newUDim2(.01, 0, 0, contentTop);
                Transparency = 0;
                Filled = false;
                ZIndex = z+6;
                Parent = objs.groupBackground;
            })

            objs.columnholder2 = utility:Draw('Square', {
                Size = newUDim2(.485, 0, 1, -(contentTop + 8));
                Position = newUDim2(1 - (.485 + .01), 0, 0, contentTop);
                Transparency = 0;
                Filled = false;
                ZIndex = z+6;
                Parent = objs.groupBackground;
            })

            objs.contentClipTop = utility:Draw('Square', {
                Size = newUDim2(1, 0, 0, contentTop);
                Position = newUDim2(0, 0, 0, 0);
                ThemeColor = 'Group Background';
                ZIndex = z+70;
                Parent = objs.groupBackground;
            })
            objs.contentClipBottom = utility:Draw('Square', {
                Size = newUDim2(1, 0, 0, 8);
                Position = newUDim2(0, 0, 1, -8);
                ThemeColor = 'Group Background';
                ZIndex = z+70;
                Parent = objs.groupBackground;
            })

            local contentBottom = 12;
            function window:ApplyColumnLayout(topPad)
                topPad = typeof(topPad) == 'number' and topPad or 10
                if window._topPad == topPad then
                    return
                end
                window._topPad = topPad
                objs.columnholder1.Position = newUDim2(.01, 0, 0, topPad)
                objs.columnholder2.Position = newUDim2(1 - (.485 + .01), 0, 0, topPad)
                objs.columnholder1.Size = newUDim2(.485, 0, 1, -(topPad + contentBottom))
                objs.columnholder2.Size = newUDim2(.485, 0, 1, -(topPad + contentBottom))
                if objs.columnholder1.Update then objs.columnholder1:Update() end
                if objs.columnholder2.Update then objs.columnholder2:Update() end
                objs.contentClipTop.Position = newUDim2(0, 0, 0, 0)
                objs.contentClipTop.Size = newUDim2(1, 0, 0, math.max(0, topPad))
                local gb = objs.groupBackground.Object
                local c1 = objs.columnholder1.Object
                if gb and c1 then
                    local bottomY = (c1.Position.Y - gb.Position.Y) + c1.Size.Y
                    local bottomH = math.max(0, gb.Size.Y - bottomY)
                    objs.contentClipBottom.Position = newUDim2(0, 0, 0, bottomY)
                    objs.contentClipBottom.Size = newUDim2(1, 0, 0, math.max(contentBottom, bottomH))
                    window._clipBottom = math.max(contentBottom, bottomH)
                end
            end
            window:ApplyColumnLayout(contentTop)

            function window:ClipSectionToColumn(section, colObj, viewH)
                if window._uiDragging then
                    return
                end
                if not section or not colObj or not section.objects or not section.objects.background then
                    return
                end
                local sec = section.objects.background
                local objs = section.objects
                if not sec.Object then
                    return
                end
                local fullH = section._contentHeight or section._layoutHeight or sec.Object.Size.Y
                if typeof(fullH) ~= 'number' or fullH <= 0 then
                    fullH = 20
                end
                local y = section._layoutY
                if typeof(y) ~= 'number' then
                    y = (sec.Position and sec.Position.Y and sec.Position.Y.Offset) or 0
                end

                local function hideAllOptions()
                    for _, opt in next, section.options do
                        local h = opt.objects and opt.objects.holder
                        if h then
                            if h.Visible ~= false then
                                h.Visible = false
                            end
                            if h.Update then
                                h:Update()
                            end
                        end
                    end
                end

                -- Scrolled completely off top or bottom
                if y >= viewH or (y + fullH) <= 0 then
                    sec.Visible = false
                    if objs.textlabel then objs.textlabel.Visible = false end
                    if objs.topBorder1 then objs.topBorder1.Visible = false end
                    if objs.topBorder2 then objs.topBorder2.Visible = false end
                    hideAllOptions()
                    return
                end

                local optHolder = objs.optionholder
                local wScale = (section.span == 2 and sec.Size and sec.Size.X.Scale) or 1
                if typeof(wScale) ~= 'number' or wScale <= 0 then
                    wScale = 1
                end

                -- Clip section background to column view boundaries
                local secVisibleTop = math.max(0, y)
                local secVisibleBottom = math.min(viewH, y + fullH)
                local secVisibleH = math.max(0, secVisibleBottom - secVisibleTop)

                if secVisibleH <= 2 then
                    sec.Visible = false
                    hideAllOptions()
                    return
                end

                sec.Visible = true
                sec.Position = newUDim2(0, 0, 0, secVisibleTop)
                sec.Size = newUDim2(wScale, 0, 0, secVisibleH)
                if sec.Update then
                    sec:Update()
                end

                if optHolder then
                    local holderRelY = 13 + (y < 0 and y or 0)
                    optHolder.Position = newUDim2(.015, 0, 0, holderRelY)
                end

                local showTitle = y >= -4
                if objs.textlabel then objs.textlabel.Visible = showTitle and sec.Visible end
                if objs.topBorder1 then objs.topBorder1.Visible = showTitle and sec.Visible end
                if objs.topBorder2 then objs.topBorder2.Visible = showTitle and sec.Visible end

                local colTop = colObj.Position.Y
                local colBottom = colTop + viewH

                local function getOptH(option)
                    if not option then return 18 end
                    if option.class == 'curve' then
                        return 96
                    elseif option.class == 'scrolllist' then
                        local maxV = option.max or 6
                        local hasLabel = option.text ~= nil and option.text ~= ''
                        return 4 + maxV * 20 + (hasLabel and 18 or 4)
                    elseif option.class == 'list' then
                        return 40
                    elseif option.class == 'slider' then
                        return 28
                    elseif option.class == 'textbox' or option.class == 'box' then
                        return 38
                    elseif option.class == 'button' then
                        return 24
                    elseif option.class == 'toggle' then
                        return 20
                    elseif option.class == 'label' then
                        return 16
                    end
                    local h = option.objects and option.objects.holder
                    if h then
                        if h.Size and h.Size.Y and typeof(h.Size.Y.Offset) == 'number' and h.Size.Y.Offset > 0 then
                            return h.Size.Y.Offset
                        end
                        if h.Object and typeof(h.Object.Size.Y) == 'number' and h.Object.Size.Y > 0 then
                            return h.Object.Size.Y
                        end
                    end
                    return 18
                end

                -- Strict clipping: option is visible ONLY if fully inside the column and inside the group box!
                for _, opt in next, section.options do
                    local holder = opt.objects and opt.objects.holder
                    if not holder or not holder.Object then
                        continue
                    end
                    if opt.enabled == false then
                        if holder.Visible ~= false then
                            holder.Visible = false
                        end
                        if holder.Update then
                            holder:Update()
                        end
                        continue
                    end

                    local optRelY = (holder.Position and holder.Position.Y and holder.Position.Y.Offset) or 0
                    local optH = opt._layoutHeight or getOptH(opt)

                    -- Position in column space
                    local optAbsTop = colTop + y + 13 + optRelY
                    local optAbsBottom = optAbsTop + optH

                    -- Must be fully within column top and column bottom (never hanging off menu!)
                    local inCol = (optAbsBottom > colTop + 2) and (optAbsTop < colBottom - 2)
                    -- Must not poke past the bottom of the section content or visible groupbox bottom
                    local inSec = (optRelY + optH <= fullH + 2) and (y + 13 + optRelY + optH <= secVisibleBottom + 1)

                    local shouldShow = sec.Visible and inCol and inSec
                    if holder.Visible ~= shouldShow then
                        holder.Visible = shouldShow
                    end
                    if holder.Update then
                        holder:Update()
                    end
                end
            end

            objs.dragdetector = utility:Draw('Square',{
                Size = newUDim2(1,0,0,25);
                Position = newUDim2(0,0,0,0);
                Parent = objs.midBorder;
                Transparency = 0;
                ZIndex = z+2;
            })
            objs.dragdetector._touchDrag = true

            local dragging, mouseStart, objStart;

            utility:Connection(objs.dragdetector.MouseButton1Down, function(pos)
                dragging = true;
                window._uiDragging = true;
                library.uiDragging = true;
                mouseStart = pos;
                objStart = objs.background.Position;
            end)

            utility:Connection(button1up, function()
                dragging = false;
                window._uiDragging = false;
                library.uiDragging = false;
            end)

            utility:Connection(mousemove, function(pos)
                if not dragging then
                    return
                end
                if not window.open then
                    dragging = false
                    window._uiDragging = false
                    library.uiDragging = false
                    return
                end
                local delta = pos - mouseStart
                objs.background.Position = objStart + newUDim2(0, delta.X, 0, delta.Y)
                if library.fitOpenWindow then
                    local camNow = workspace.CurrentCamera
                    local vs = camNow and camNow.ViewportSize
                    local obj = objs.background.Object
                    if vs and obj then
                        local inset = gs('GuiService'):GetGuiInset()
                        local x = math.clamp(obj.Position.X, 4, math.max(4, vs.X - obj.Size.X - 4))
                        local y = math.clamp(obj.Position.Y, inset.Y + 4, math.max(inset.Y + 4, vs.Y - obj.Size.Y - 4))
                        objs.background.Position = newUDim2(0, x, 0, y)
                    end
                end
            end)

        end

        do
            do
                local objs = window.colorpicker.objects;
                local z = library.zindexOrder.colorpicker;

                objs.background = utility:Draw('Square', {
                    Visible = false;
                    Size = newUDim2(0,200,0,222);
                    Position = newUDim2(1,-200,1,10);
                    ThemeColor = 'Background';
                    Rounded = true;
                    ZIndex = z;
                    Parent = window.objects.background;
                })

                objs.border1 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-1;
                    Parent = objs.background;
                })

                objs.border2 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 1';
                    ZIndex = z-2;
                    Parent = objs.border1;
                })

                objs.border3 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-3;
                    Parent = objs.border2;
                })

                objs.statusText = utility:Draw('Text', {
                    Position = newUDim2(0,5,0,4);
                    Text = 'colorpicker_status_text';
                    ThemeColor = 'Option Text 1';
                    Size = 13;
                    Font = 2;
                    Outline = true;
                    ZIndex = z+1;
                    Parent = objs.background;
                })

                objs.mainColor = utility:Draw('Square', {
                    Size = newUDim2(0, 175, 0, 175);
                    Position = newUDim2(0, 5, 0, 25);
                    Color = c3new(1,0,0);
                    ZIndex = z+2;
                    Parent = objs.background;
                })

                objs.sat1 = utility:Draw('Image', {
                    Size = newUDim2(1,0,1,0);
                    Data = safeB64Decode("iVBORw0KGgoAAAANSUhEUgAAAaQAAAGkCAQAAADURZm+AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JQAAgIMAAPn/AACA6QAAdTAAAOpgAAA6mAAAF2+SX8VGAAAAAmJLR0QA/4ePzL8AAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQflBwwSLzK3wl3KAAADrElEQVR42u3TORLCMBBFwT+6/50hMqXSZgonBN0BWCDGYPwqeSWVZPWYVHd0Pc5H86v9areu4Sz9u7XZXT/vvtZtu6dtJtYw525iGya05afnWW17ltPE8fzfTZy/yf3vmCes59xf0Sf/42l3lnvGOyyH+y/bo/X689wCPCYkEBIICYQECAmEBEICIQFCAiGBkEBIgJBASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZAAIYGQQEggJEBIICQQEggJEBIICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIICRASCAmEBAgJhARCAiEBQgIhgZBASICQQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQQEguAQgJhARCAoQEQgIhgZAAIYGQQEggJEBIICQQEggJEBIICYQEQgKEBEICIYGQACGBkEBIgJBASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZBASICQQEggJBASICQQEggJhAQICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIICRASCAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQQEiAkEBIICQQEiAkEBIICYQECAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASCAkQEggJhARCAoQEQgIhgZAAIYGQQEggJEBIICQQEiAkEBIICYQECAmEBEICIQFCAiGBkEBIgJBASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZAAIYGQQEggJEBIICQQEggJEBIICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZBASICQQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQACGBkEBIICRASCAkEBIICRASCAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASCAkQEggJhAQICYQEQgIhAUICIYGQQEiAkEBIICQQEiAkEBIICYQECAmEBEICIQFCAiGBkEBILgEICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIICRASCAmEBEIChARCAiGBkAAhgZBASICQQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQQEiAkEBIICQQEiAkEBIICYQECAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASCAkQEggJhARCAoQEQgIhgZAAIYGQQEggJEBIICQQEiAkEBL8lzft9AVFFzN+ywAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wNy0xMlQxODo0Nzo1MCswMDowMIxlM90AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDctMTJUMTg6NDc6NTArMDA6MDD9OIthAAAAAElFTkSuQmCC");
                    ZIndex = z+3;
                    Parent = objs.mainColor;
                })

                objs.sat2 = utility:Draw('Image', {
                    Size = newUDim2(1,0,1,0);
                    Data = safeB64Decode("iVBORw0KGgoAAAANSUhEUgAAAaQAAAGkCAQAAADURZm+AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JQAAgIMAAPn/AACA6QAAdTAAAOpgAAA6mAAAF2+SX8VGAAAAAmJLR0QA/4ePzL8AAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQflBwwSLyBEeyyCAAAD4klEQVR42u3YwQnAQAhFQTek/5pz9eBtEYzMlBD4PDcRADDBieMjwK3HJwBDghFepx0oEhgSOO0ARQJDAqcdKBJgSGBI4I0EhgQ47cCQwJDAGwlQJDAkcNqBIgGKBIoEhgROO0CRQJFAkQBDAqcdGBI47QBFAkUCQwKnHaBIoEigSKBIgCKBIYHTDhQJUCQwJHDagSIBigSGBE47UCRAkcCQwGkHKBIoEigSGBLgtANDAkMCbyTAkMBpB4oEigQoEhgSOO1AkQBDAqcdKBIoEqBIYEjgtANFUiRQJFAkMCTAaQeKBIoEigQYEjjtQJFAkQBFAkMCpx0oEmBI4LQDRQJFAhQJDAmcdqBIgCKBIoEhAU47UCRQJFAkwJDAaQeKBIYEOO1AkUCRYHuRTAmcduC0A0UCFAkUCQwJnHaAIoEigSKBIQFOO2gvkimBIoE3EhgS4LQDRQJDAqcdoEigSKBIYEiAIYEhwXx+NoAigSGB0w5QJDAkMCQwJKDiZwMoEhgSOO0ARQJFgnlFMiVw2oHTDhQJUCRQJDAkcNoBVZFMCRQJvJHAkACnHSgSKBIoElANSZPAaQdOOzAkwGkHigSGBIYEGBK08LMBFAkUCRQJMCQwJDAkWMjPBlAkMCRw2gG5SKYEigTeSGBIgNMOFAkMCQwJMCRo4WcDKBIYEjjtgFwkUwJFAm8kMCTAaQeKBIoEigRUQ9IkcNqB0w4MCXDagSKBIsHCIpkSOO3AaQeKBCgSKBIYEhgSYEjQws8GUCQwJHDaAblIpgSKBN5IYEiA0w4UCQwJDAkwJGjhZwMoEhgSOO0ARQJDAkMCQwIqfjaAIoEigSIBhgROO5hXJFMCpx047UCRAEUCRQJDAqcdUBXJlECRwBsJDAlw2oEigSKBIgGGBIYEhgSL+dkAigSGBE47QJHAkMBpB4oEGBIYEhgSrOZnAygSKBIoEmBI4LQDRQJFAhQJDAmcdrC8SKYEigTeSGBIgNMOFAkMCZx2gCKBIoEigSEBTjtQJFAkUCTAkMBpB4oEigQoEhgSOO1AkQBDAqcdKBKgSKBIYEjgtAMUCRQJFAkMCXDagSKBIoEiAYYETjtQJFAkQJHAkMBpB4oEGBI47UCRQJEARQJDAqcdoEigSGBI4LQDFAkUCRQJFAkwJHDagSKBIQFOOzAkMCTwRgIMCZx2oEigSIAigSKBIYHTzkcARQJFAkMCnHZgSGBI4I0EGBI47UCRQJEAQwKnHSgSKBKgSGBI4LQDRQIUCRQJDAmcdoAigSGB0w5QJFAkUCQwJMBpB4oEhgROO0CRwJDAkMAbCVAkMCT4gw/reQYigE05fAAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wNy0xMlQxODo0NzozMiswMDowMN2VK3MAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDctMTJUMTg6NDc6MzIrMDA6MDCsyJPPAAAAAElFTkSuQmCC");
                    ZIndex = z+4;
                    Parent = objs.mainColor;
                })

                objs.colorBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z+1;
                    Parent = objs.mainColor;
                })

                objs.mainDetector = utility:Draw('Square',{
                    Size = newUDim2(1,0,1,0);
                    Color = c3new(1,1,1);
                    Transparency = 1;
                    ZIndex = z+10;
                    Parent = objs.mainColor;
                })

                objs.hue = utility:Draw('Image', {
                    Size = newUDim2(0,175,0,10);
                    Position = newUDim2(0,5,0,205);
                    Data = library.images.colorhue;
                    ZIndex = z+2;
                    Parent = objs.background;
                })

                objs.hueBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z+1;
                    Parent = objs.hue;
                })

                objs.hueDetector = utility:Draw('Square',{
                    Size = newUDim2(1,0,1,0);
                    Color = c3new(1,1,1);
                    Transparency = 1;
                    ZIndex = z+10;
                    Parent = objs.hue;
                })

                objs.transColor = utility:Draw('Square', {
                    Size = newUDim2(0,10,0,175);
                    Position = newUDim2(0,185,0,25);
                    Color = c3new(1,0,0);
                    ZIndex = z+2;
                    Parent = objs.background;
                })

                objs.trans = utility:Draw('Image', {
                    Size = newUDim2(1,0,1,0);
                    Data = library.images.colortrans;
                    ZIndex = z+3;
                    Parent = objs.transColor;
                })

                objs.transBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z+1;
                    Parent = objs.transColor;
                })

                objs.transDetector = utility:Draw('Square',{
                    Size = newUDim2(1,0,1,0);
                    Color = c3new(1,1,1);
                    Transparency = 1;
                    ZIndex = z+10;
                    Parent = objs.transColor;
                })

                objs.pointer = utility:Draw('Square', {
                    Size = newUDim2(0,2,0,2);
                    Position = newUDim2(0,0,0,0);
                    Color = c3new(1,1,1);
                    ZIndex = z+6;
                    Parent = objs.mainColor;
                })

                objs.pointerBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+5;
                    Parent = objs.pointer;
                })

                objs.hueSlider = utility:Draw('Square', {
                    Size = newUDim2(0,1,1,0);
                    Color = c3new(1,1,1);
                    ZIndex = z+4;
                    Parent = objs.hue;
                })

                objs.hueSliderBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+3;
                    Parent = objs.hueSlider;
                })

                objs.transSlider = utility:Draw('Square', {
                    Size = newUDim2(1,0,0,1);
                    Color = c3new(1,1,1);
                    ZIndex = z+5;
                    Parent = objs.trans;
                })

                objs.transSliderBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+4;
                    Parent = objs.transSlider;
                })

                objs.sat1.Visible = false
                objs.sat2.Visible = false
                objs.sat1.Transparency = 1
                objs.sat2.Transparency = 1
                objs.hue.Transparency = 1
                objs.trans.Transparency = 1

                local SAT_N = 16
                local HUE_N = 24
                objs.satCells = {}
                for y = 0, SAT_N - 1 do
                    objs.satCells[y] = {}
                    for x = 0, SAT_N - 1 do
                        objs.satCells[y][x] = utility:Draw('Square', {
                            Size = newUDim2(1 / SAT_N, 1, 1 / SAT_N, 1);
                            Position = newUDim2(x / SAT_N, 0, y / SAT_N, 0);
                            Color = c3new(1, 0, 0);
                            ZIndex = z+5;
                            Parent = objs.mainColor;
                        })
                    end
                end
                objs.hueCells = {}
                for i = 0, HUE_N - 1 do
                    objs.hueCells[i] = utility:Draw('Square', {
                        Size = newUDim2(1 / HUE_N, 1, 1, 0);
                        Position = newUDim2(i / HUE_N, 0, 0, 0);
                        Color = fromhsv(1 - (i / (HUE_N - 1)), 1, 1);
                        ZIndex = z+3;
                        Parent = objs.hue;
                    })
                end
                objs.transCells = {}
                for i = 0, SAT_N - 1 do
                    objs.transCells[i] = utility:Draw('Square', {
                        Size = newUDim2(1, 0, 1 / SAT_N, 1);
                        Position = newUDim2(0, 0, i / SAT_N, 0);
                        Color = c3new(0, 0, 0);
                        Transparency = i / (SAT_N - 1);
                        ZIndex = z+4;
                        Parent = objs.transColor;
                    })
                end

                local draggingHue, draggingSat, draggingTrans = false, false, false;

                local function updateSatVal(pos)
                    if window.colorpicker.selected ~= nil then
                        local hue, sat, val = window.colorpicker.selected.color:ToHSV()
                        X = (objs.mainColor.Object.Position.X + objs.mainColor.Object.Size.X) - objs.mainColor.Object.Position.X
                        Y = (objs.mainColor.Object.Position.Y + objs.mainColor.Object.Size.Y) - objs.mainColor.Object.Position.Y
                        X = math.clamp((pos.X - objs.mainColor.Object.Position.X) / X, 0, 0.995)
                        Y = math.clamp((pos.Y - objs.mainColor.Object.Position.Y) / Y, 0, 0.995)
                        sat, val = 1 - X, 1 - Y;
                        window.colorpicker.selected:SetColor(fromhsv(hue,sat,val));
                        window.colorpicker:Visualize(fromhsv(hue, sat, val), window.colorpicker.selected.trans);
                    end
                end

                local function updateHue(pos)
                    if window.colorpicker.selected ~= nil then
                        local hue, sat, val = window.colorpicker.selected.color:ToHSV()
                        X = (objs.hue.Object.Position.X + objs.hue.Object.Size.X) - objs.hue.Object.Position.X
                        X = math.clamp((pos.X - objs.hue.Object.Position.X) / X, 0, 0.995)
                        hue = 1 - X
                        window.colorpicker.selected:SetColor(fromhsv(hue,sat,val));
                        window.colorpicker:Visualize(fromhsv(hue, sat, val), window.colorpicker.selected.trans);
                    end
                end

                local function updateTrans(pos)
                    if window.colorpicker.selected ~= nil then
                        Y = (objs.trans.Object.Position.Y + objs.trans.Object.Size.Y) - objs.trans.Object.Position.Y
                        Y = math.clamp((pos.Y - objs.transColor.Object.Position.Y) / Y, 0, 0.995)
                        window.colorpicker.selected:SetTrans(Y);
                        window.colorpicker:Visualize(window.colorpicker.selected.color, Y);
                    end
                end

                objs.mainDetector._touchDrag = true
                objs.hueDetector._touchDrag = true
                objs.transDetector._touchDrag = true
                utility:Connection(objs.mainDetector.MouseButton1Down, function(pos)
                    draggingSat = true;
                    updateSatVal(pos)
                end)

                utility:Connection(objs.hueDetector.MouseButton1Down, function(pos)
                    draggingHue = true;
                    updateHue(pos)
                end)

                utility:Connection(objs.transDetector.MouseButton1Down, function(pos)
                    draggingTrans = true;
                    updateTrans(pos)
                end)

                utility:Connection(mousemove, function(pos)
                    if library.open then
                        if draggingSat then
                            updateSatVal(pos)
                        elseif draggingHue then
                            updateHue(pos)
                        elseif draggingTrans then
                            updateTrans(pos)
                        end
                    end
                end)

                utility:Connection(button1up, function()
                    draggingSat = false;
                    draggingHue = false;
                    draggingTrans = false;
                end)

            end

            function window.colorpicker:Visualize(c3, a)
                if typeof(c3) ~= 'Color3' then return end
                if typeof(a) ~= 'number' then return end
                local h,s,v = c3:ToHSV();
                h = h == 0 and 1 or h;
                self.color = c3;
                self.trans = a;
                self.objects.mainColor.Color = fromhsv(h,1,1);
                self.objects.transColor.Color = fromhsv(h,s,v);
                if self.objects.transCells then
                    local tn = 15
                    for i = 0, tn do
                        local cell = self.objects.transCells[i]
                        if cell then
                            cell.Color = fromhsv(h, s, v)
                            cell.Transparency = i / tn
                        end
                    end
                end
                if self.objects.satCells then
                    local n = 15
                    for y = 0, n do
                        local row = self.objects.satCells[y]
                        if row then
                            for x = 0, n do
                                local cell = row[x]
                                if cell then
                                    local sat = 1 - (x / n)
                                    local val = 1 - (y / n)
                                    cell.Color = fromhsv(h, sat, val)
                                end
                            end
                        end
                    end
                end
                self.objects.hueSlider.Position = newUDim2(1 - h, 0,0,0);
                self.objects.transSlider.Position = newUDim2(0,0,a,0);
                self.objects.pointer.Position = newUDim2(1 - s, 0, 1 - v, 0);
                self.objects.statusText.Text = 'Editing : Unknown';
                if self.selected ~= nil then
                    local txt = 'Editing : Unknown';
                    if self.selected.text ~= nil and self.selected.text ~= '' then
                        txt = tostring(self.selected.text)
                    elseif self.selected.flag ~= nil and self.selected.flag ~= '' then
                        txt = tostring(self.selected.flag)
                    end
                    self.objects.statusText.Text = tostring(txt);
                end
            end

            window.colorpicker:Visualize(window.colorpicker.color, window.colorpicker.trans)

        end

        do
            do
                local objs = window.dropdown.objects;
                local z = library.zindexOrder.dropdown;

                objs.background = utility:Draw('Square', {
                    Visible = false;
                    Size = newUDim2(1,-3,0,50);
                    Position = newUDim2(0,3,1,0);
                    ThemeColor = 'Background';
                    ZIndex = z;
                    Parent = window.objects.background;
                    Rounded = true;
                })

                objs.border1 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-1;
                    Parent = objs.background;
                    Rounded = true;
                })

                objs.border2 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 1';
                    ZIndex = z-2;
                    Parent = objs.border1;
                    Rounded = true;
                })

                objs.border3 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-3;
                    Parent = objs.border2;
                })

            end

            function window.dropdown:Refresh()
                if self.selected == nil then
                    return
                end
                local list = self.selected
                local values = list.values
                local rowH, padding = 18, 2
                local maxVisible = self.max or 10
                local maxScroll = math.max(0, #values - maxVisible)
                self.scroll = math.clamp(self.scroll or 0, 0, maxScroll)

                for slot = 1, maxVisible do
                    local valueObject = self.objects.values[slot]
                    if valueObject == nil then
                        valueObject = {};
                        valueObject.slot = slot
                        valueObject.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,rowH);
                            Color = Color3.new(.25,.25,.25);
                            Transparency = 0;
                            ZIndex = library.zindexOrder.dropdown+1;
                            Parent = self.objects.background;
                        })
                        valueObject.text = utility:Draw('Text', {
                            Position = newUDim2(0,3,0,1);
                            ThemeColor = 'Option Text 2';
                            Text = '';
                            Size = 13;
                            Font = 2;
                            ZIndex = library.zindexOrder.dropdown+2;
                            Parent = valueObject.background;
                        })
                        valueObject.connection = utility:Connection(valueObject.background.MouseButton1Down, function()
                            local currentList = self.selected
                            if not currentList then
                                return
                            end
                            local realIdx = (self.scroll or 0) + valueObject.slot
                            local val = currentList.values[realIdx]
                            if val == nil then
                                return
                            end
                            local currentSelected = currentList.selected;
                            local newSelected = currentList.multi and {} or val;

                            if currentList.multi then
                                for i,v in next, currentSelected do
                                    if v == "none" then continue end
                                    newSelected[i] = v;
                                end
                                if table.find(newSelected, val) then
                                    table.remove(newSelected, table.find(newSelected, val));
                                else
                                    table.insert(newSelected, val)
                                end
                            end

                            currentList:Select(newSelected);
                            if not currentList.multi then
                                currentList.open = false;
                                currentList.objects.openText.Text = '+';
                                window.dropdown.selected = nil;
                                window.dropdown.objects.background.Visible = false;
                            else
                                window.dropdown:Refresh()
                            end
                        end)
                        self.objects.values[slot] = valueObject
                    end
                end

                for slot, obj in next, self.objects.values do
                    if typeof(slot) == 'number' and slot > maxVisible then
                        obj.background.Visible = false
                    end
                end

                local shown = 0
                for slot = 1, maxVisible do
                    local realIdx = self.scroll + slot
                    local valueStr = values[realIdx]
                    local obj = self.objects.values[slot]
                    if valueStr ~= nil then
                        shown += 1
                        obj.background.Visible = true
                        obj.background.Position = newUDim2(0,2,0,2 + (slot-1)*(rowH+padding));
                        obj.text.Text = tostring(valueStr);
                        local selected = (typeof(list.selected) == 'table' and table.find(list.selected, valueStr) or list.selected == valueStr)
                        obj.background.Transparency = selected and 1 or 0
                    else
                        obj.background.Visible = false
                    end
                end

                self.objects.background.Size = newUDim2(1,-6,0, math.max(22, 2 + shown*(rowH+padding) + 2));
            end

            utility:Connection(inputservice.InputChanged, function(input)
                if not library.open or window.dropdown.selected == nil then
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    local list = window.dropdown.selected
                    local maxVisible = window.dropdown.max or 10
                    local maxScroll = math.max(0, #list.values - maxVisible)
                    local delta = input.Position.Z
                    if delta > 0 then
                        window.dropdown.scroll = math.clamp((window.dropdown.scroll or 0) - 1, 0, maxScroll)
                    elseif delta < 0 then
                        window.dropdown.scroll = math.clamp((window.dropdown.scroll or 0) + 1, 0, maxScroll)
                    end
                    window.dropdown:Refresh()
                end
            end)

            window.dropdown:Refresh();
        end

        local function tooltip(option)
            utility:Connection(option.objects.holder.MouseEnter, function()
                tooltipObjects.background.Visible = (not (option.tooltip == '' or option.tooltip == nil)) and true or false;
                tooltipObjects.riskytext.Visible = option.risky;
                tooltipObjects.text.Position = option.risky and newUDim2(0,60,0,0) or newUDim2(0,3,0,0)
                tooltipObjects.text.Text = tostring(option.tooltip);
                library.CurrentTooltip = option;
            end)
            utility:Connection(option.objects.holder.MouseLeave, function()
                if library.CurrentTooltip == option then
                    library.CurrentTooltip = nil;
                    tooltipObjects.background.Visible = false
                end
            end)
        end

        local visValues = {};

        function window:SetOpen(bool)
            if typeof(bool) ~= 'boolean' then
                return
            end
            self.open = bool
            self._openGen = (self._openGen or 0) + 1
            local openGen = self._openGen
            if not bool then
                if self.colorpicker and self.colorpicker.selected then
                    self.colorpicker.selected:SetOpen(false)
                end
                if self.dropdown and self.dropdown.selected then
                    self.dropdown:SetOpen(false)
                end
            end
            local root = self.objects.background
            root.Visible = bool
            if root.Object then
                root.Object.Visible = bool
            end
            root:Update()
            if bool and self.selectedTab and self.selectedTab.UpdateSections then
                self.selectedTab:UpdateSections()
            end
        end

        function window:AddTab(text, order)
            local tab = {
                text = text;
                order = order or #self.tabs+1;
                callback = function() end;
                objects = {};
                sections = {};
            }

            table.insert(self.tabs, tab);

            do
                local objs = tab.objects;
                local z = library.zindexOrder.window + 56;

                objs.background = utility:Draw('Square', {
                    Size = newUDim2(0,50,1,0);
                    Parent = self.objects.tabHolder;
                    ThemeColor = 'Unselected Tab Background';
                    ZIndex = z;
                })

                objs.innerBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 1';
                    ZIndex = z-1;
                    Parent = objs.background;
                })

                objs.outerBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 3';
                    ZIndex = z-2;
                    Parent = objs.innerBorder;
                })

                objs.topBorder = utility:Draw('Square', {
                    Size = newUDim2(1,0,0,1);
                    ThemeColor = 'Unselected Tab Background';
                    ZIndex = z+1;
                    Parent = objs.background;
                })

                objs.text = utility:Draw('Text', {
                    ThemeColor = 'Unselected Tab Text';
                    Text = text;
                    Size = 12;
                    Font = 0;
                    ZIndex = z+1;
                    Outline = true;
                    Center = true;
                    Parent = objs.background;
                })

                utility:Connection(objs.background.MouseButton1Down, function()
                    tab:Select();
                end)

            end

            function tab:AddSection(text, side, order)
                local section = {
                    text = tostring(text);
                    side = side == nil and 1 or clamp(side,1,2);
                    span = 1;
                    order = order or #self.sections+1;
                    enabled = true;
                    tab = self;
                    objects = {};
                    options = {};
                };

                table.insert(self.sections, section);

                do
                    local objs = section.objects;
                    local z = library.zindexOrder.window+15;

                    objs.background = utility:Draw('Square', {
                        ThemeColor = 'Section Background';
                        ZIndex = z;
                        Parent = window.objects['columnholder'..(section.side)];
                        Rounded = true;
                    })

                    objs.innerBorder = utility:Draw('Square', {
                        Size = newUDim2(1,2,1,1);
                        Position = newUDim2(0,-1,0,0);
                        ThemeColor = 'Border 3';
                        ZIndex = z-1;
                        Parent = objs.background;
                        Rounded = true;
                    })

                    objs.outerBorder = utility:Draw('Square', {
                        Size = newUDim2(1,2,1,1);
                        Position = newUDim2(0,-1,0,0);
                        ThemeColor = 'Border 1';
                        ZIndex = z-2;
                        Parent = objs.innerBorder;
                        Rounded = true;
                    })

                    objs.topBorder1 = utility:Draw('Square', {
                        Size = newUDim2(.025,1,0,1);
                        Position = newUDim2(0,-1,0,0);
                        ThemeColor = 'Accent';
                        ZIndex = library.zindexOrder.window+81;
                        Parent = objs.background;
                    })

                    objs.topBorder2 = utility:Draw('Square', {
                        ThemeColor = 'Accent';
                        ZIndex = library.zindexOrder.window+81;
                        Parent = objs.background;
                    })

                    objs.textlabel = utility:Draw('Text', {
                        Position = newUDim2(.0425,0,0,-7);
                        ThemeColor = 'Primary Text';
                        Size = 13;
                        Font = 2;
                        Outline = true;
                        ZIndex = library.zindexOrder.window+82;
                        Parent = objs.background;
                    })

                    objs.optionholder = utility:Draw('Square',{
                        Size = newUDim2(1-.03,0,1,-15);
                        Position = newUDim2(.015,0,0,13);
                        Transparency = 0;
                        ZIndex = z+1;
                        Parent = objs.background;
                    })

                end

                function section:SetText(text)
                    self.text = tostring(text);
                    self.objects.textlabel.Text = self.text;
                    local x = self.objects.background.Object.Size.X - self.objects.textlabel.TextBounds.X - 13
                    self.objects.topBorder2.Size = newUDim2(0, x, 0, 1)
                    self.objects.topBorder2.Position = newUDim2(1, 1 + -x, 0, 0)
                end

                function section:UpdateOptions()
                    table.sort(self.options, function(a,b)
                        return a.order < b.order
                    end)

                    local function getOptH(option)
                        if not option then return 18 end
                        if option.class == 'curve' then
                            return 96
                        elseif option.class == 'scrolllist' then
                            local maxV = option.max or 6
                            local hasLabel = option.text ~= nil and option.text ~= ''
                            return 4 + maxV * 20 + (hasLabel and 18 or 4)
                        elseif option.class == 'list' then
                            return 40
                        elseif option.class == 'slider' then
                            return 34
                        elseif option.class == 'textbox' or option.class == 'box' then
                            return 38
                        elseif option.class == 'button' then
                            return 24
                        elseif option.class == 'toggle' then
                            return 20
                        elseif option.class == 'label' then
                            return 16
                        end
                        local h = option.objects and option.objects.holder
                        if h then
                            if h.Size and h.Size.Y and typeof(h.Size.Y.Offset) == 'number' and h.Size.Y.Offset > 0 then
                                return h.Size.Y.Offset
                            end
                            if h.Object and typeof(h.Object.Size.Y) == 'number' and h.Object.Size.Y > 0 then
                                return h.Object.Size.Y
                            end
                        end
                        return 18
                    end

                    local yOffset = 0
                    local padding = 4

                    for i, option in next, self.options do
                        if option.enabled ~= false then
                            local optH = getOptH(option)
                            option._layoutHeight = optH
                            local targetPos = newUDim2(0, 0, 0, yOffset)
                            if option.objects and option.objects.holder then
                                option.objects.holder.Position = targetPos
                                option.objects.holder.Size = newUDim2(1, 0, 0, optH)
                                option.objects.holder.Visible = true
                                if option.objects.holder.Update then
                                    option.objects.holder:Update()
                                end
                            end
                            yOffset += optH + padding
                        else
                            if option.objects and option.objects.holder then
                                if option.objects.holder.Visible ~= false then
                                    option.objects.holder.Visible = false
                                end
                                if option.objects.holder.Update then
                                    option.objects.holder:Update()
                                end
                            end
                        end
                    end

                    local finalContentH = math.max(15, yOffset + 12)
                    self._contentHeight = finalContentH
                    self._layoutHeight = finalContentH
                    if not (library.tweens[self.objects.background] and library.tweens[self.objects.background].Size) then
                        self.objects.background.Size = newUDim2(1, 0, 0, finalContentH)
                    end
                    if self.objects.background.Update then
                        self.objects.background:Update()
                    end

                    self._hasLaidOut = true
                    local curTab = self.tab or tab
                    if curTab and curTab.UpdateSections and not curTab._updatingSections then
                        curTab:UpdateSections()
                    end
                end

                function section:SetEnabled(bool)
                    if typeof(bool) == 'boolean' then
                        section.enabled = bool;
                        tab:UpdateSections();
                    end
                end

                function section:AddToggle(data)
                    local toggle = {
                        class = 'toggle';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        order = #self.options+1;
                        state = false;
                        risky = false;
                        callback = function() end;
                        enabled = true;
                        options = {};
                        objects = {};
                        colorScroll = 0;
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) ~= toggle[i] ~= nil then
                            toggle[i] = v
                        end
                    end

                    table.insert(self.options, toggle)

                    if toggle.flag then
                        library.flags[toggle.flag] = toggle.state;
                        library.options[toggle.flag] = toggle;
                    end

                    do
                        local objs = toggle.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,18);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(0,10,0,10);
                            Position = newUDim2(0,2,0,4);
                            ThemeColor = 'Option Background';
                            ZIndex = z+3;
                            Parent = objs.holder;
                        })

                        objs.glow = utility:Draw('Square', {
                            Size = newUDim2(1, 4, 1, 4);
                            Position = newUDim2(0, -2, 0, -2);
                            ThemeColor = 'Accent';
                            Transparency = 0;
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp45;
                            Transparency = .35;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+2;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z+1;
                            Parent = objs.border1;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,20,0,2);
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.mark = utility:Draw('Text', {
                            Text = '+';
                            Size = 14;
                            Font = 2;
                            Position = newUDim2(0, 1, 0, -3);
                            Color = fromrgb(255, 255, 255);
                            ZIndex = z+8;
                            Visible = false;
                            Parent = objs.background;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = toggle.state and 'Accent' or 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            toggle:SetState(not toggle.state);
                        end)

                    end

                    function toggle:SetState(bool, nocallback)
                        if typeof(bool) == 'boolean' then
                            self.state = bool;
                            if self.flag then
                                library.flags[self.flag] = bool;
                            end

                            self.objects.border1.ThemeColor = bool and 'Accent' or 'Option Border 1';
                            self.objects.text.ThemeColor = bool and (self.risky and 'Risky Text Enabled' or 'Option Text 1') or (self.risky and 'Risky Text' or 'Option Text 3');
                            self.objects.background.ThemeColor = bool and 'Accent' or 'Option Background';
                            self.objects.background.ThemeColorOffset = 0
                            if self.objects.glow then
                                self.objects.glow.Transparency = bool and 0 or 1
                            end
                            local onCol = (library.theme and library.theme['Accent']) or Color3.fromRGB(196, 148, 255)
                            local offCol = (library.theme and library.theme['Option Background']) or Color3.fromRGB(28, 28, 34)
                            local textOn = (library.theme and library.theme['Option Text 1']) or Color3.fromRGB(245, 245, 250)
                            local textOff = (library.theme and library.theme['Option Text 3']) or Color3.fromRGB(140, 140, 150)
                            if self.objects.gradient then
                                self.objects.gradient.Transparency = bool and 1 or 0.35
                            end
                            if self.objects.background and self.objects.background.Object then
                                self.objects.background.Object.Color = bool and onCol or offCol
                                self.objects.background.Object.Transparency = 0
                            end
                            if self.objects.border1 and self.objects.border1.Object then
                                self.objects.border1.Object.Color = bool and onCol or offCol
                                self.objects.border1.ZIndex = (self.objects.background.ZIndex or 1) + 2
                            end
                            if self.objects.text and self.objects.text.Object then
                                self.objects.text.Object.Color = bool and textOn or textOff
                            end
                            if self.objects.mark then
                                self.objects.mark.Visible = bool
                                if self.objects.mark.Object then
                                    self.objects.mark.Object.Visible = bool
                                    self.objects.mark.Object.Color = fromrgb(255, 255, 255)
                                end
                            end

                            if not nocallback then
                                self.callback(bool);
                            end

                        end
                    end

                    local function fitToggleText(tgl)
                        if not tgl or not tgl.objects or not tgl.objects.text or not tgl.objects.holder or not tgl.objects.holder.Object then return end
                        local rowW = tgl.objects.holder.Object.Size.X
                        if not rowW or rowW <= 0 then return end
                        local chipW = 0
                        if tgl.options then
                            for _, opt in next, tgl.options do
                                if opt.enabled and (opt.class == 'color' or opt.class == 'bind') and opt.objects and opt.objects.holder and opt.objects.holder.Object then
                                    chipW = chipW + opt.objects.holder.Object.Size.X + 2
                                end
                            end
                        end
                        local avail = rowW - 24 - chipW
                        if avail > 20 then
                            local raw = tostring(tgl.text or '')
                            tgl.objects.text.Text = raw
                            if tgl.objects.text.TextBounds.X > avail then
                                local s = raw
                                while #s > 3 and tgl.objects.text.TextBounds.X > avail do
                                    s = s:sub(1, -2)
                                    tgl.objects.text.Text = s .. ".."
                                end
                            end
                        end
                    end

                    function toggle:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            task.defer(function()
                                fitToggleText(self)
                            end)
                        end
                    end

                    function toggle:UpdateOptions()
                        table.sort(self.options, function(a,b)
                            return a.order < b.order
                        end)

                        local x, y = 0, 0
                        local chipW = 0
                        for i,option in next, self.options do
                            if option.enabled and (option.class == 'color' or option.class == 'bind') then
                                chipW = chipW + option.objects.holder.Object.Size.X
                            end
                        end
                        local rowW = self.objects.holder.Object.Size.X
                        local textW = (self.objects.text and self.objects.text.TextBounds and self.objects.text.TextBounds.X) or 80
                        local room = math.max(40, rowW - textW - 28)
                        local maxScroll = math.max(0, chipW - room)
                        self.colorScroll = math.clamp(self.colorScroll or 0, 0, maxScroll)
                        local scroll = self.colorScroll
                        for i,option in next, self.options do
                            local h = option.objects and option.objects.holder
                            if h then
                                if h.Visible ~= (option.enabled == true) then
                                    h.Visible = (option.enabled == true)
                                end
                                if h.Update then
                                    h:Update()
                                end
                            end
                            if option.enabled then
                                if option.class == 'color' or option.class == 'bind' then
                                    option.objects.holder.Position = newUDim2(1,-option.objects.holder.Object.Size.X-x + scroll,0,0);
                                    x = x + option.objects.holder.Object.Size.X;
                                elseif option.class == 'slider' or option.class == 'list' then
                                    option.objects.holder.Position = newUDim2(0,0,1,-option.objects.holder.Object.Size.Y-y);
                                    y = y + option.objects.holder.Object.Size.Y;
                                end
                            end
                        end

                        self.objects.holder.Size = newUDim2(1,0,0,18 + y);
                        fitToggleText(self);
                        section:UpdateOptions()

                    end

                    function toggle:AddColor(data)
                        local color = {
                            class = 'color';
                            flag = data.flag;
                            text = '';
                            tooltip = '';
                            order = #self.options+1;
                            callback = function() end;
                            color = Color3.new(1,1,1);
                            trans = 0;
                            open = false;
                            enabled = true;
                            objects = {};
                        };

                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and color[i] ~= nil then
                                color[i] = v
                            end
                        end

                        table.insert(self.options, color)

                        if color.flag then
                            library.flags[color.flag] = color.color;
                            library.options[color.flag] = color;
                        end

                        do
                            local objs = color.objects;
                            local z = library.zindexOrder.window+25;

                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(0,21,0,17);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = self.objects.holder;
                            })

                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(0,15,0,13);
                                Position = newUDim2(0,4,0,2);
                                ZIndex = z+3;
                                Parent = objs.holder;
                            })

                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp45;
                                Transparency = .25;
                                ZIndex = z+4;
                                Parent = objs.background;
                            })

                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+2;
                                Parent = objs.background;
                            })

                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z+1;
                                Parent = objs.border1;
                            })

                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                            end)

                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = color.state and 'Accent' or 'Option Border 1';
                            end)

                            utility:Connection(objs.holder.MouseButton1Down, function()
                                color:SetOpen(not color.open);
                            end)

                        end

                        function color:SetColor(c3, nocallback)
                            if typeof(c3) == 'Color3' then
                                local h,s,v = c3:ToHSV(); c3 = fromhsv(h, clamp(s,.005,.995), clamp(v,.005,.995))
                                self.color = c3;
                                self.objects.background.Color = c3;
                                if not nocallback then
                                    self.callback(c3, self.trans);
                                end
                                if self.open then
                                    window.colorpicker:Visualize(self.color, self.trans);
                                end
                                if self.flag then
                                    library.flags[self.flag] = c3;
                                end
                            end
                        end

                        function color:SetTrans(trans, nocallback)
                            if typeof(trans) == 'number' then
                                self.trans = trans;
                                if not nocallback then
                                    self.callback(self.color, trans);
                                end
                                if self.open then
                                    window.colorpicker:Visualize(self.color, self.trans);
                                end
                            end
                        end

                        function color:SetOpen(bool)
                            if typeof(bool) == 'boolean' then
                                self.open = bool
                                local cp = window.colorpicker
                                if bool then
                                    if cp.selected and cp.selected ~= color then
                                        cp.selected.open = false
                                    end
                                    cp.selected = color
                                    local cpBg = cp.objects.background
                                    cpBg.Parent = self.objects.background
                                    cpBg.Visible = true
                                    cpBg._roundBaseTransparency = 1
                                    if cpBg.Update then
                                        cpBg:Update()
                                    end
                                    utility:SyncRoundGeometry(cpBg)
                                    for _, part in next, cp.objects do
                                        if part.Object then
                                            part.Object.Visible = true
                                            part.Object.Transparency = 1
                                        end
                                    end
                                    cp:Visualize(color.color, color.trans)
                                elseif cp.selected == color then
                                    cp.selected = nil
                                    local cpBg = cp.objects.background
                                    cpBg.Visible = false
                                    cpBg.Parent = window.objects.background
                                    if cpBg.Update then
                                        cpBg:Update()
                                    end
                                    utility:SyncRoundGeometry(cpBg)
                                    for _, part in next, cp.objects do
                                        if part.Object then
                                            part.Object.Visible = false
                                        end
                                        if part._roundGeom then
                                            for _, p in next, part._roundGeom do
                                                pcall(function() p.Visible = false end)
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        tooltip(color);
                        color:SetColor(color.color, true);
                        color:SetTrans(color.trans, true);
                        self:UpdateOptions();
                        return color
                    end

                    function toggle:AddBind(data)
                        local bind = {
                            class = 'bind';
                            flag = data.flag;
                            text = '';
                            tooltip = '';
                            bind = 'none';
                            mode = 'toggle';
                            order = #self.options+1;
                            callback = function() end;
                            keycallback = function() end;
                            indicatorValue = library.keyIndicator:AddValue({value = 'value', key = 'key', enabled = false});
                            noindicator = false;
                            invertindicator = false;
                            state = false;
                            nomouse = false;
                            enabled = true;
                            binding = false;
                            objects = {};
                        };

                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and bind[i] ~= nil then
                                bind[i] = v
                            end
                        end

                        table.insert(self.options, bind)

                        if bind.flag then
                            library.options[bind.flag] = bind;
                        end

                        if bind.bind == 'none' then
                            bind.state = true
                            if bind.flag then
                                library.flags[bind.flag] = bind.state;
                            end
                            bind.callback(true)
                            local display = bind.state; if bind.invertindicator then display = not bind.state; end
                            bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                            bind.indicatorValue:SetKey((bind.text == nil or bind.text == '') and (bind.flag == nil and 'unknown' or bind.flag) or bind.text);
                            bind.indicatorValue:SetValue('[Always]');
                        end

                        do
                            local objs = bind.objects;
                            local z = library.zindexOrder.window+25;

                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(0,0,0,17);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = self.objects.holder;
                            })

                            objs.keyText = utility:Draw('Text', {
                                ThemeColor = 'Option Text 3';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+1;
                                Parent = objs.holder;
                            })

                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.keyText.ThemeColor = 'Accent';
                            end)

                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.keyText.ThemeColor = bind.binding and 'Accent' or 'Option Text 3';
                            end)

                            utility:Connection(objs.holder.MouseButton1Down, function()
                                if not bind.binding then
                                    bind:SetKeyText('...');
                                    bind.binding = true;
                                end
                            end)

                        end

                        local c
                        function bind:SetBind(keybind)
                            if c then
                                c:Disconnect();
                                if bind.flag then
                                    library.flags[bind.flag] = false;
                                end
                                bind.callback(false);
                            end
                            local keyName = 'NONE'
                            self.bind = (keybind and keybind) or keybind or self.bind
                            if self.bind == Enum.KeyCode.Backspace then
                                self.bind = 'none';
                                bind.state = true
                                if bind.flag then
                                    library.flags[bind.flag] = bind.state;
                                end
                                self.callback(true)
                                local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                            else
                                keyName = keyNames[keybind] or keybind.Name or keybind
                            end
                            if self.bind ~= 'none' then
                                bind.state = false
                                if bind.flag then
                                    library.flags[bind.flag] = bind.state;
                                end
                                self.callback(false)
                                local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                            end
                            self.keycallback(self.bind);
                            self:SetKeyText(keyName:upper());
                            self.indicatorValue:SetKey((self.text == nil or self.text == '') and (self.flag == nil and 'unknown' or self.flag) or self.text);
                            self.indicatorValue:SetValue('['..keyName:upper()..']');
                            if self.bind == 'none' then
                                self.indicatorValue:SetValue('[Always]');
                            end
                            self.objects.keyText.ThemeColor = self.objects.holder.Hover and 'Accent' or 'Option Text 3';
                        end

                        function bind:SetKeyText(str)
                            str = tostring(str);
                            self.objects.keyText.Text = '['..str..']';
                            self.objects.keyText.Position = newUDim2(0, 2, 0, 2);
                            self.objects.holder.Size = newUDim2(0,self.objects.keyText.TextBounds.X+2,0,17)
                            toggle:UpdateOptions();
                        end

                        utility:Connection(inputservice.InputBegan, function(inp)
                            if inputservice:GetFocusedTextBox() then
                                return
                            elseif bind.binding then
                                local key = (table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}, inp.UserInputType) and not bind.nomouse) and inp.UserInputType
                                bind:SetBind(key or (not table.find(blacklistedKeys, inp.KeyCode)) and inp.KeyCode)
                                bind.binding = false
                            elseif not bind.binding and self.bind == 'none' then
                                bind.state = true
                                library.flags[bind.flag] = bind.state
                                local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                bind.indicatorValue:SetEnabled(display and not bind.noindicator)
                            elseif (inp.KeyCode == bind.bind or inp.UserInputType == bind.bind) and not bind.binding then
                                if bind.mode == 'toggle' then
                                    bind.state = not bind.state
                                    if bind.flag then
                                        library.flags[bind.flag] = bind.state;
                                    end
                                    bind.callback(bind.state)
                                    local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                    bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                                elseif bind.mode == 'hold' then
                                    if bind.flag then
                                        library.flags[bind.flag] = true;
                                    end
                                    bind.indicatorValue:SetEnabled((not bind.invertindicator and true or false) and not bind.noindicator);
                                    c = utility:Connection(runservice.RenderStepped, function()
                                        if bind.callback then
                                            bind.callback(true);
                                        end
                                    end)
                                end
                            end
                        end)

                        utility:Connection(inputservice.InputEnded, function(inp)
                            if bind.bind ~= 'none' then
                                if inp.KeyCode == bind.bind or inp.UserInputType == bind.bind then
                                    if c then
                                        c:Disconnect();
                                        if bind.flag then
                                            library.flags[bind.flag] = false;
                                        end
                                        if bind.callback then
                                            bind.callback(false);
                                        end
                                        bind.indicatorValue:SetEnabled(bind.invertindicator and true or false);
                                    end
                                end
                            end
                        end)

                        tooltip(bind);
                        bind:SetBind(bind.bind);
                        self:UpdateOptions();
                        return bind
                    end

                    function toggle:AddSlider(data)
                        local slider = {
                            class = 'slider';
                            flag = data.flag;
                            suffix = '';
                            tooltip = '';
                            order = #self.options+1;
                            value = 0;
                            min = 0;
                            max = 100;
                            increment = 1;
                            callback = function() end;
                            enabled = true;
                            dragging = false;
                            focused = false;
                            objects = {};
                        };

                        local blacklist = {'objects', 'dragging'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and (slider[i] ~= nil and typeof(slider[i]) == typeof(v)) then
                                slider[i] = v;
                            end
                        end

                        table.insert(self.options, slider)

                        if slider.flag then
                            library.flags[slider.flag] = slider.value;
                            library.options[slider.flag] = slider;
                        end

                        do
                            local objs = slider.objects;
                            local z = library.zindexOrder.window+25;

                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(1,0,0,20);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = toggle.objects.holder;
                            })

                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,1,-8);
                                Position = newUDim2(0,2,0,4);
                                ThemeColor = 'Option Background';
                                ZIndex = z+2;
                                Parent = objs.holder;
                            })

                            objs.slider = utility:Draw('Square', {
                                Size = newUDim2(0,0,1,0);
                                ThemeColor = 'Accent';
                                ZIndex = z+3;
                                Parent = objs.background;
                            })

                            objs.sliderGlow = utility:Draw('Square', {
                                Size = newUDim2(1, 4, 1, 4);
                                Position = newUDim2(0, -2, 0, -2);
                                ThemeColor = 'Accent';
                                Transparency = 0.32;
                                ZIndex = z+2;
                                Parent = objs.slider;
                            })

                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+1;
                                Parent = objs.background;
                            })

                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z;
                                Parent = objs.border1;
                            })

                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp90;
                                Transparency = .78;
                                ZIndex = z+4;
                                Parent = objs.background;
                            })

                            objs.text = utility:Draw('Text', {
                                Position = newUDim2(.5,0,0,-1);
                                ThemeColor = 'Option Text 3';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+5;
                                Outline = true;
                                Center = true;
                                Parent = objs.background;
                            })

                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                            end)

                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = slider.dragging and 'Accent' or 'Option Border 1';
                            end)

                            local c;
                            local inputNumber = '';
                            utility:Connection(slider.objects.holder.MouseButton1Down, function()
                                if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) then
                                    if slider.focused then
                                        slider.focused = false;
                                        c:Disconnect();
                                    else
                                        objs.text.Text = tostring(slider.value)..tostring(slider.suffix)..'/'..tostring(slider.max)..tostring(slider.suffix)..' []';
                                        slider.focused = true;
                                        inputNumber = '';
                                        c = utility:Connection(inputservice.InputBegan, function(inp)
                                            if library.numberStrings[inp.KeyCode.Name] then
                                                local number = library.numberStrings[inp.KeyCode.Name];
                                                inputNumber = inputNumber..tostring(number);
                                                objs.text.Text = string.format("%.14g", slider.value) .. tostring(slider.suffix) .. "/" .. slider.max .. tostring(slider.suffix) .. " [" .. inputNumber .. "]";
                                            elseif inp.KeyCode == Enum.KeyCode.Backspace then
                                                inputNumber = inputNumber:sub(1,-2);
                                                objs.text.Text = string.format("%.14g", slider.value)..tostring(slider.suffix)..'/'..slider.max..tostring(slider.suffix)..' ['..inputNumber..']';
                                            elseif inp.KeyCode == Enum.KeyCode.Return then
                                                slider:SetValue(tonumber(inputNumber))
                                                slider.focused = false;
                                                c:Disconnect();
                                            elseif inp.KeyCode == Enum.KeyCode.Escape then
                                                slider:SetValue(slider.value, true)
                                                slider.focused = false;
                                                c:Disconnect();
                                            end
                                        end)
                                    end
                                else
                                    slider.dragging = true;
                                    library.draggingSlider = slider;
                                end
                            end)

                            utility:Connection(button1up, function()
                                objs.border1.ThemeColor = objs.holder.Hover and 'Accent' or 'Option Border 1';
                                slider.dragging = false;
                                library.draggingSlider = nil;
                            end)

                        end

                        function slider:SetValue(value, nocallback)
                            if typeof(value) == 'number' then
                                local newValue = clamp(self.increment * floor(value/self.increment), self.min, self.max);
                                local range = self.max - self.min
                                if range == 0 then
                                    range = 1
                                end
                                local valueT = math.clamp((newValue - self.min) / range, 0, 1)
                                local size, pos
                                if self.min < 0 and self.max > 0 then
                                    local zeroT = -self.min / range
                                    local leftT = math.min(valueT, zeroT)
                                    size = newUDim2(math.abs(valueT - zeroT), 0, 1, 0)
                                    pos = newUDim2(leftT, 0, 0, 0)
                                else
                                    size = newUDim2(valueT, 0, 1, 0)
                                    pos = newUDim2(0, 0, 0, 0)
                                end

                                if library.tweens[self.objects.slider] then
                                    if library.tweens[self.objects.slider]['Size'] then library.tweens[self.objects.slider]['Size']:Cancel() end
                                    if library.tweens[self.objects.slider]['Position'] then library.tweens[self.objects.slider]['Position']:Cancel() end
                                end
                                self.objects.slider.Size = size;
                                self.objects.slider.Position = pos;

                                local changed = (self.value ~= newValue) or (not self._hasValue) or nocallback
                                self._hasValue = true
                                self.value = newValue;
                                library.flags[self.flag] = newValue;
                                if changed then
                                    self.objects.text.Text = string.format("%.14g",newValue)..tostring(self.suffix)..'/'..self.max..tostring(self.suffix);
                                    self.objects.text.ThemeColor = (self.min < 0 and newValue == 0 or newValue == self.min)  and (self.risky and 'Risky Text' or 'Option Text 3') or (self.risky and 'Risky Text Enabled' or 'Option Text 1');

                                    if not nocallback then
                                        self.callback(newValue);
                                    end
                                end

                            end
                        end

                        tooltip(slider);
                        slider:SetValue(slider.value, true);
                        self:UpdateOptions();
                        return slider
                    end

                    function toggle:AddList(data)
                        local list = {
                            class = 'list';
                            flag = data.flag;
                            text = '';
                            selected = '';
                            tooltip = '';
                            order = #self.options+1;
                            callback = function() end;
                            enabled = true;
                            multi = false;
                            open = false;
                            values = {};
                            objects = {};
                        }

                        table.insert(self.options, list);

                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) ~= list[i] ~= nil then
                                list[i] = v
                            end
                        end

                        if list.flag then
                            library.flags[list.flag] = list.selected;
                            library.options[list.flag] = list;
                        end

                        do
                            local objs = list.objects;
                            local z = library.zindexOrder.window+25;

                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(1,0,0,22);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = toggle.objects.holder;
                            })

                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,1,-8);
                                Position = newUDim2(0,2,0,4);
                                ThemeColor = 'Option Background';
                                ZIndex = z+2;
                                Parent = objs.holder;
                            })

                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+1;
                                Parent = objs.background;
                            })

                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z;
                                Parent = objs.border1;
                            })

                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp90;
                                Transparency = .78;
                                ZIndex = z+4;
                                Parent = objs.background;
                            })

                            objs.inputText = utility:Draw('Text', {
                                Position = newUDim2(0,4,0,0);
                                ThemeColor = 'Option Text 2';
                                Text = 'none',
                                Size = 13;
                                Font = 2;
                                ZIndex = z+5;
                                Outline = true;
                                Parent = objs.background;
                            })

                            objs.openText = utility:Draw('Text', {
                                Position = newUDim2(1,-10,0,0);
                                ThemeColor = 'Option Text 3';
                                Text = '+';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+5;
                                Outline = true;
                                Parent = objs.background;
                            })

                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                            end)

                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = 'Option Border 1';
                            end)

                            utility:Connection(objs.holder.MouseButton1Down, function()
                                if list.open then
                                    list.open = false;
                                    objs.openText.Text = '+';
                                    if window.dropdown.selected == list then
                                        window.dropdown.selected = nil;
                                        window.dropdown.objects.background.Visible = false;
                                    end
                                else
                                    if window.dropdown.selected ~= nil then
                                        window.dropdown.selected.open = false
                                    end
                                    list.open = true;
                                    objs.openText.Text = '-';
                                    window.dropdown.selected = list;
                                    window.dropdown.objects.background.Visible = true;
                                    window.dropdown.objects.background.Parent = objs.holder;
                                    do
                                        local scrollTo = 0
                                        local sel = list.selected
                                        if typeof(sel) == 'string' then
                                            local found = table.find(list.values, sel)
                                            if found then scrollTo = math.max(0, found - 1) end
                                        end
                                        window.dropdown.scroll = scrollTo
                                    end
                                    window.dropdown:Refresh();
                                end
                            end)

                        end

                        function list:Select(option, nocallback)
                            option = typeof(option) == 'table' and (self.multi == true and option or (#option == 0 and nil or option[1])) or self.multi == true and {option} or option;
                            if option ~= nil then
                                self.selected = option;
                                local text = typeof(option) == 'table' and (#option == 0 and "none" or table.concat(option, ', ')) or tostring(option);
                                local label = self.objects.inputText
                                label.Text = text;
                                if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                    local split = text:split('');
                                    for i = 1,#split do
                                        label.Text = table.concat(split, '', 1, i)
                                        if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                            label.Text = label.Text:sub(1,-6)..'...';
                                            break
                                        end
                                    end
                                end
                                if self.flag then
                                    library.flags[self.flag] = self.selected
                                end
                                if not nocallback then
                                    self.callback(self.selected);
                                end
                            end
                        end

                        function list:AddValue(value)
                            table.insert(list.values, tostring(value));
                            if window.dropdown.selected == list then
                                window.dropdown:Refresh()
                            end
                        end

                        function list:RemoveValue(value)
                            if table.find(list.values, value) then
                                table.remove(list.values, table.find(list.values, value));
                                if window.dropdown.selected == list then
                                    window.dropdown:Refresh()
                                end
                            end
                        end

                        function list:ClearValues()
                            table.clear(list.values);
                            if window.dropdown.selected == list then
                                window.dropdown:Refresh()
                            end
                        end

                        tooltip(list);
                        list:Select((data.value or data.selected) or (list.multi and 'none' or list.values[1]), true);
                        self:UpdateOptions();
                        return list
                    end

                    tooltip(toggle);
                    toggle:SetText(toggle.text);
                    toggle:SetState(toggle.state, true);
                    self:UpdateOptions();
                    return toggle
                end

                function section:AddSlider(data)
                    local slider = {
                        class = 'slider';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        suffix = '';
                        order = #self.options+1;
                        value = 0;
                        default = data.default or data.value or data.min or 0;
                        min = 0;
                        max = 100;
                        increment = 1;
                        callback = function() end;
                        enabled = true;
                        dragging = false;
                        focused = false;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects', 'dragging'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and (slider[i] ~= nil and typeof(slider[i]) == typeof(v)) then
                            slider[i] = v;
                        end
                    end

                    table.insert(self.options, slider)

                    if slider.flag then
                        library.flags[slider.flag] = slider.value;
                        library.options[slider.flag] = slider;
                    end

                    do
                        local objs = slider.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,32);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,10);
                            Position = newUDim2(0,2,0,18);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.slider = utility:Draw('Square', {
                            Size = newUDim2(0,0,1,0);
                            ThemeColor = 'Accent';
                            ZIndex = z+3;
                            Parent = objs.background;
                        })

                        objs.sliderGlow = utility:Draw('Square', {
                            Size = newUDim2(1, 4, 1, 4);
                            Position = newUDim2(0, -2, 0, -2);
                            ThemeColor = 'Accent';
                            Transparency = 0.32;
                            ZIndex = z+2;
                            Parent = objs.slider;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .78;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,1);
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = slider.dragging and 'Accent' or 'Option Border 1';
                        end)

                        local c;
                        local inputNumber = '';
                        utility:Connection(slider.objects.holder.MouseButton1Down, function()
                            if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) then
                                if slider.focused then
                                    slider.focused = false;
                                    c:Disconnect();
                                else
                                    objs.text.Text = slider.text..': '..tostring(slider.value)..tostring(slider.suffix)..' []';
                                    slider.focused = true;
                                    inputNumber = '';
                                    c = utility:Connection(inputservice.InputBegan, function(inp)
                                        if library.numberStrings[inp.KeyCode.Name] then
                                            local number = library.numberStrings[inp.KeyCode.Name];
                                            inputNumber = inputNumber..tostring(number);
                                            objs.text.Text = slider.text..': '..string.format("%.14g",slider.value)..tostring(slider.suffix)..' ['..inputNumber..']';
                                        elseif inp.KeyCode == Enum.KeyCode.Backspace then
                                            inputNumber = inputNumber:sub(1,-2);
                                            objs.text.Text = slider.text..': '..string.format("%.14g",slider.value)..tostring(slider.suffix)..' ['..inputNumber..']';
                                        elseif inp.KeyCode == Enum.KeyCode.Return then
                                            slider:SetValue(tonumber(inputNumber))
                                            slider.focused = false;
                                            c:Disconnect();
                                        elseif inp.KeyCode == Enum.KeyCode.Escape then
                                            slider:SetValue(slider.value, true)
                                            slider.focused = false;
                                            c:Disconnect();
                                        end
                                    end)

                                end

                            else
                                slider.dragging = true;
                                library.draggingSlider = slider;
                            end
                        end)

                        utility:Connection(button1up, function()
                            objs.border1.ThemeColor = objs.holder.Hover and 'Accent' or 'Option Border 1';
                            slider.dragging = false;
                            library.draggingSlider = nil;
                        end)

                    end

                    function slider:SetValue(value, nocallback)
                        if typeof(value) == 'number' then
                            local newValue = clamp(self.increment * floor(value/self.increment), self.min, self.max);
                            local range = self.max - self.min
                            if range == 0 then
                                range = 1
                            end
                            local valueT = math.clamp((newValue - self.min) / range, 0, 1)
                            local size, pos
                            if self.min < 0 and self.max > 0 then
                                local zeroT = -self.min / range
                                local leftT = math.min(valueT, zeroT)
                                size = newUDim2(math.abs(valueT - zeroT), 0, 1, 0)
                                pos = newUDim2(leftT, 0, 0, 0)
                            else
                                size = newUDim2(valueT, 0, 1, 0)
                                pos = newUDim2(0, 0, 0, 0)
                            end

                            if library.tweens[self.objects.slider] then
                                if library.tweens[self.objects.slider]['Size'] then library.tweens[self.objects.slider]['Size']:Cancel() end
                                if library.tweens[self.objects.slider]['Position'] then library.tweens[self.objects.slider]['Position']:Cancel() end
                            end
                            self.objects.slider.Size = size;
                            self.objects.slider.Position = pos;

                            local changed = (self.value ~= newValue) or (not self._hasValue) or nocallback
                            self._hasValue = true
                            self.value = newValue;
                            library.flags[self.flag] = newValue;
                            if changed then
                                self.objects.text.Text = slider.text..': '..string.format("%.14g",newValue)..tostring(self.suffix);
                                self.objects.text.ThemeColor = (self.min < 0 and newValue == 0 or newValue == self.min)  and (self.risky and 'Risky Text' or 'Option Text 3') or (self.risky and 'Risky Text Enabled' or 'Option Text 1');

                                if not nocallback then
                                    self.callback(newValue);
                                end
                            end

                        end
                    end

                    function slider:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str..': '..tostring(self.value)..tostring(self.suffix);
                        end
                    end

                    tooltip(slider);
                    slider:SetText(slider.text);
                    slider:SetValue(slider.value, true);
                    self:UpdateOptions();
                    return slider
                end

                function section:AddButton(data)
                    local button = {
                        class = 'button';
                        flag = data.flag;
                        text = '';
                        suffix = '';
                        tooltip = '';
                        order = #self.options+1;
                        callback = function() end;
                        confirm = false;
                        enabled = true;
                        risky = false;
                        objects = {};
                        subbuttons = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and button[i] ~= nil then
                            button[i] = v;
                        end
                    end

                    table.insert(self.options, button)

                    if button.flag then
                        library.options[button.flag] = button;
                    end

                    do
                        local objs = button.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,22);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,14);
                            Position = newUDim2(0,2,0,4);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.glow = utility:Draw('Square', {
                            Size = newUDim2(1, 4, 1, 4);
                            Position = newUDim2(0, -2, 0, -2);
                            ThemeColor = 'Accent';
                            Transparency = 0;
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .78;
                            ZIndex = z+3;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(.5,0,0,0);
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+4;
                            Outline = true;
                            Center = true;
                            Parent = objs.background;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                            if objs.glow then objs.glow.Transparency = 0.28 end
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = 'Option Border 1';
                            objs.text.ThemeColor = self.risky and 'Risky Text' or 'Option Text 3';
                            objs.background.ThemeColor = 'Option Background';
                            objs.background.ThemeColorOffset = 0;
                            if objs.glow then objs.glow.Transparency = 0 end
                        end)

                        utility:Connection(objs.holder.MouseButton1Up, function()
                            objs.text.ThemeColor = self.risky and 'Risky Text' or  'Option Text 3';
                            objs.background.ThemeColor = 'Option Background';
                            objs.background.ThemeColorOffset = 0;
                            if objs.glow then objs.glow.Transparency = objs.holder.Hover and 0.28 or 0 end
                        end)

                        local clicked, counting = false, false
                        utility:Connection(objs.holder.MouseButton1Down, function()
                            objs.text.ThemeColor = self.risky and 'Risky Text Enabled' or 'Option Text 2';
                            objs.background.ThemeColor = 'Accent';
                            objs.background.ThemeColorOffset = -95;
                            if objs.glow then objs.glow.Transparency = 0.48 end

                            task.spawn(function()
                                if button.confirm then
                                    if clicked then
                                        clicked = false
                                        counting = false
                                        objs.text.Text = button.text
                                        button.callback()
                                    else
                                        clicked = true
                                        counting = true
                                        for i = 3,1,-1 do
                                            if not counting then
                                                break
                                            end
                                            objs.text.Text = 'Confirm '..button.text..'? '..tostring(i)
                                            wait(1)
                                        end
                                        clicked = false
                                        counting = false
                                        objs.text.Text = button.text
                                    end
                                else
                                    button.callback()
                                end
                            end)

                        end)

                    end
                    function button:AddButton(data)
                        local button = {
                            class = 'button';
                            flag = data.flag;
                            text = '';
                            suffix = '';
                            tooltip = '';
                            order = #self.subbuttons+1;
                            callback = function() end;
                            confirm = false;
                            enabled = true;
                            objects = {};
                        };

                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and button[i] ~= nil then
                                button[i] = v;
                            end
                        end

                        table.insert(self.subbuttons, button)

                        if button.flag then
                            library.options[button.flag] = button;
                        end

                        do
                            local objs = button.objects;
                            local z = library.zindexOrder.window+25;

                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(1,0,1,0);
                                Transparency = 0;
                                ZIndex = z+5;
                                Parent = self.objects.holder;
                            })

                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,1,-8);
                                Position = newUDim2(0,2,0,4);
                                ThemeColor = 'Option Background';
                                ZIndex = z+2;
                                Parent = objs.holder;
                            })

                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+1;
                                Parent = objs.background;
                            })

                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z;
                                Parent = objs.border1;
                            })

                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp90;
                                Transparency = .78;
                                ZIndex = z+3;
                                Parent = objs.background;
                            })

                            objs.text = utility:Draw('Text', {
                                Position = newUDim2(.5,0,0,0);
                                ThemeColor = 'Option Text 3';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+4;
                                Outline = true;
                                Center = true;
                                Parent = objs.background;
                            })

                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                                if objs.glow then objs.glow.Transparency = 0.28 end
                            end)

                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = 'Option Border 1';
                                objs.text.ThemeColor = self.risky and 'Risky Text' or 'Option Text 3';
                                objs.background.ThemeColor = 'Option Background';
                                objs.background.ThemeColorOffset = 0;
                                if objs.glow then objs.glow.Transparency = 0 end
                            end)

                            utility:Connection(objs.holder.MouseButton1Up, function()
                                objs.text.ThemeColor = self.risky and 'Risky Text' or 'Option Text 3';
                                objs.background.ThemeColor = 'Option Background';
                                objs.background.ThemeColorOffset = 0;
                                if objs.glow then objs.glow.Transparency = objs.holder.Hover and 0.28 or 0 end
                            end)

                            local clicked, counting = false, false
                            utility:Connection(objs.holder.MouseButton1Down, function()
                                objs.text.ThemeColor = self.risky and 'Risky Text Enabled' or 'Option Text 2';
                                objs.background.ThemeColor = 'Accent';
                                objs.background.ThemeColorOffset = -95;
                                if objs.glow then objs.glow.Transparency = 0.48 end

                                task.spawn(function()
                                    if button.confirm then
                                        if clicked then
                                            clicked = false
                                            counting = false
                                            objs.text.Text = button.text
                                            button.callback()
                                        else
                                            clicked = true
                                            counting = true
                                            for i = 3,1,-1 do
                                                if not counting then
                                                    break
                                                end
                                                objs.text.Text = 'Confirm '..button.text..'? '..tostring(i)
                                                wait(1)
                                            end
                                            clicked = false
                                            counting = false
                                            objs.text.Text = button.text
                                        end
                                    else
                                        button.callback()
                                    end
                                end)

                            end)

                        end

                        function button:SetText(str)
                            if typeof(str) == 'string' then
                                self.text = str;
                                self.objects.text.Text = str;
                            end
                        end

                        tooltip(button);
                        button:SetText(button.text);
                        self:UpdateOptions();
                        return button
                    end

                    function button:UpdateOptions()
                        local buttons = 1 + #self.subbuttons;
                        local buttonSize = (1 / buttons) - .005;
                        self.objects.background.Size = newUDim2(buttonSize,-4,0,14);
                        for i,v in next, self.subbuttons do
                            v.objects.holder.Size = newUDim2(buttonSize,0,1,0);
                            v.objects.holder.Position = newUDim2(i * buttonSize + .01, 0, 0, 0)
                        end
                    end

                    function button:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    tooltip(button);
                    button:SetText(button.text);
                    self:UpdateOptions();
                    return button
                end


                function section:AddCurve(data)
                    local curve = {
                        class = 'curve';
                        flag = data.flag;
                        text = data.text or 'Curve';
                        tooltip = data.tooltip or '';
                        order = #self.options+1;
                        enabled = true;
                        preset = data.preset or 'Linear';
                        points = data.points or {0, 0.143, 0.286, 0.429, 0.571, 0.714, 0.857, 1.0};
                        callback = data.callback or function() end;
                        objects = {};
                        _draggingIdx = nil;
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and curve[i] ~= nil and typeof(curve[i]) == typeof(v) then
                            curve[i] = v;
                        end
                    end

                    table.insert(self.options, curve)

                    if curve.flag then
                        library.flags[curve.flag] = curve.points;
                        library.options[curve.flag] = curve;
                    end

                    do
                        local objs = curve.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,96);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.title = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,1);
                            Text = curve.text;
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.resetHolder = utility:Draw('Square', {
                            Size = newUDim2(0,42,0,14);
                            Position = newUDim2(1,-46,0,1);
                            Transparency = 0;
                            ZIndex = z+6;
                            Parent = objs.holder;
                        })

                        objs.resetText = utility:Draw('Text', {
                            Position = newUDim2(0.5,0,0,0);
                            Center = true;
                            Text = 'reset';
                            ThemeColor = 'Option Text 3';
                            Size = 12;
                            Font = 2;
                            ZIndex = z+7;
                            Outline = true;
                            Parent = objs.resetHolder;
                        })

                        objs.graph = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,74);
                            Position = newUDim2(0,2,0,18);
                            ThemeColor = 'Option Background';
                            ThemeColorOffset = -22;
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.graph;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gridLines = {}
                        for gy = 1, 3 do
                            local yRatio = gy / 4
                            local line = utility:Draw('Square', {
                                Size = newUDim2(1,0,0,1);
                                Position = newUDim2(0,0,yRatio,0);
                                ThemeColor = 'Option Border 2';
                                Transparency = 0.28;
                                ZIndex = z+3;
                                Parent = objs.graph;
                            })
                            table.insert(objs.gridLines, line)
                        end
                        for gx = 1, 7 do
                            local xRatio = gx / 8
                            local line = utility:Draw('Square', {
                                Size = newUDim2(0,1,1,0);
                                Position = newUDim2(xRatio,0,0,0);
                                ThemeColor = 'Option Border 2';
                                Transparency = 0.28;
                                ZIndex = z+3;
                                Parent = objs.graph;
                            })
                            table.insert(objs.gridLines, line)
                        end

                        local NUM_CURVE_SEGS = 28
                        objs.glowLines = {}
                        for i = 1, NUM_CURVE_SEGS do
                            local gLine = utility:Draw('Line', {
                                Thickness = 4;
                                ThemeColor = 'Accent';
                                Transparency = 0.35;
                                ZIndex = z+4;
                                Parent = objs.graph;
                            })
                            table.insert(objs.glowLines, gLine)
                        end

                        local NUM_CURVE_SEGS = 28
                        objs.curveLines = {}
                        for i = 1, NUM_CURVE_SEGS do
                            local cLine = utility:Draw('Line', {
                                Thickness = 2;
                                ThemeColor = 'Accent';
                                Transparency = 0.95;
                                ZIndex = z+5;
                                Parent = objs.graph;
                            })
                            table.insert(objs.curveLines, cLine)
                        end

                        objs.pointBoxes = {}
                        objs.pointGlows = {}
                        for i = 1, #curve.points do
                            local ptBox = utility:Draw('Square', {
                                Size = newUDim2(0,6,0,6);
                                Position = newUDim2(0,0,0,0);
                                ThemeColor = 'Option Text 1';
                                ZIndex = z+8;
                                Parent = objs.graph;
                            })
                            local ptGlow = utility:Draw('Square', {
                                Size = newUDim2(1,4,1,4);
                                Position = newUDim2(0,-2,0,-2);
                                ThemeColor = 'Accent';
                                Transparency = 0.38;
                                ZIndex = z+7;
                                Parent = ptBox;
                            })
                            table.insert(objs.pointBoxes, ptBox)
                            table.insert(objs.pointGlows, ptGlow)
                        end

                    function curve:Evaluate(t)
                        t = math.clamp(t or 0, 0, 1)
                        local n = #self.points
                        if n <= 1 then return math.clamp(self.points[1] or 0, 0, 1) end
                        local scaled = t * (n - 1)
                        local i = math.clamp(math.floor(scaled) + 1, 1, n - 1)
                        local s = scaled - (i - 1)
                        local p0 = math.clamp(self.points[math.max(1, i - 1)] or 0, 0, 1)
                        local p1 = math.clamp(self.points[i] or 0, 0, 1)
                        local p2 = math.clamp(self.points[math.min(n, i + 1)] or 0, 0, 1)
                        local p3 = math.clamp(self.points[math.min(n, i + 2)] or 0, 0, 1)
                        local val = 0.5 * ((2 * p1) + (-p0 + p2) * s + (2 * p0 - 5 * p1 + 4 * p2 - p3) * s * s + (-p0 + 3 * p1 - 3 * p2 + p3) * s * s * s)
                        return math.clamp(val, 0, 1)
                    end

                        function curve:RenderPoints()
                            local n = #self.points
                            for i = 1, n do
                                local xRatio = (i - 1) / (n - 1)
                                local yVal = math.clamp(self.points[i] or 0, 0, 1)
                                local yRatio = 1 - yVal
                                if objs.pointBoxes[i] then
                                    objs.pointBoxes[i].Position = newUDim2(xRatio, -3, yRatio, -3)
                                end
                            end
                            local NUM_SEGS = #objs.curveLines
                            local prevX = 0
                            local prevY = 1 - self:Evaluate(0)
                            for s = 1, NUM_SEGS do
                                local t = s / NUM_SEGS
                                local nextX = t
                                local nextY = 1 - self:Evaluate(t)
                                if objs.curveLines[s] then
                                    objs.curveLines[s].From = newUDim2(prevX, 0, prevY, 0)
                                    objs.curveLines[s].To = newUDim2(nextX, 0, nextY, 0)
                                    objs.curveLines[s]:Update()
                                end
                                if objs.glowLines[s] then
                                    objs.glowLines[s].From = newUDim2(prevX, 0, prevY, 0)
                                    objs.glowLines[s].To = newUDim2(nextX, 0, nextY, 0)
                                    objs.glowLines[s]:Update()
                                end
                                prevX = nextX
                                prevY = nextY
                            end
                        end

                        curve:RenderPoints()

                        utility:Connection(objs.resetHolder.MouseEnter, function()
                            objs.resetText.ThemeColor = 'Accent'
                        end)
                        utility:Connection(objs.resetHolder.MouseLeave, function()
                            objs.resetText.ThemeColor = 'Option Text 3'
                        end)
                        utility:Connection(objs.resetHolder.MouseButton1Down, function()
                            curve:SetPreset('Linear')
                        end)

                        utility:Connection(objs.graph.MouseButton1Down, function()
                            curve._dragging = true
                            library.draggingCurve = curve
                            local mPos = utility:MouseLocation()
                            local gPos = objs.graph.Object.Position
                            local gSize = objs.graph.Object.Size
                            if gSize.X > 0 and gSize.Y > 0 then
                                local relX = math.clamp((mPos.X - gPos.X) / gSize.X, 0, 1)
                                local n = #curve.points
                                local bestIdx = math.clamp(math.round(relX * (n - 1)) + 1, 1, n)
                                curve._draggingIdx = bestIdx
                                local relY = 1 - math.clamp((mPos.Y - gPos.Y) / gSize.Y, 0, 1)
                                curve.points[bestIdx] = math.clamp(math.round(relY * 100) / 100, 0, 1)
                                curve.preset = 'Custom'
                                if curve.onPresetChanged then
                                    curve.onPresetChanged('Custom')
                                end
                                curve:RenderPoints()
                                if curve.flag then
                                    library.flags[curve.flag] = curve.points
                                end
                                curve.callback(curve.points, curve)
                            end
                        end)

                        utility:Connection(button1up, function()
                            if curve._dragging then
                                curve._dragging = false
                                curve._draggingIdx = nil
                                library.draggingCurve = nil
                            end
                        end)
                    end

                    function curve:SetPreset(name)
                        self.preset = name
                        local n = #self.points
                        if name == 'Linear' then
                            for i = 1, n do
                                self.points[i] = (i - 1) / (n - 1)
                            end
                        elseif name == 'Smooth' or name == 'S-Curve' then
                            for i = 1, n do
                                local t = (i - 1) / (n - 1)
                                self.points[i] = t * t * (3 - 2 * t)
                            end
                        elseif name == 'Ease In' then
                            for i = 1, n do
                                local t = (i - 1) / (n - 1)
                                self.points[i] = t * t
                            end
                        elseif name == 'Ease Out' then
                            for i = 1, n do
                                local t = (i - 1) / (n - 1)
                                self.points[i] = math.sqrt(t)
                            end
                        elseif name == 'Aggressive' then
                            for i = 1, n do
                                local t = (i - 1) / (n - 1)
                                self.points[i] = t ^ 0.5 * 0.5 + (t > 0.5 and 0.5 or 0)
                            end
                        elseif name == 'Custom' then
                        end
                        self:RenderPoints()
                        if self.flag then
                            library.flags[self.flag] = self.points
                        end
                        self.callback(self.points, self)
                        if self.onPresetChanged then
                            self.onPresetChanged(name)
                        end
                    end

                    function curve:SetVisible(bool)
                        if self.objects and self.objects.holder then
                            self.objects.holder.Visible = bool
                        end
                    end

                    self:UpdateOptions();
                    return curve
                end

                function section:AddSeparator(data)
                    local separator = {
                        class = 'separator';
                        flag = data.flag;
                        text = '';
                        order = #self.options+1;
                        enabled = true;
                        objects = {};
                    };

                    local blacklist = {'objects', 'dragging'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and (separator[i] ~= nil and typeof(separator[i]) == typeof(v)) then
                            separator[i] = v;
                        end
                    end

                    table.insert(self.options, separator)

                    do
                        local objs = separator.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,18);
                            Transparency = 0;
                            ZIndex = z;
                            Parent = section.objects.optionholder;
                        })

                        objs.line1 = utility:Draw('Square', {
                            Position = newUDim2(0,0,0,1);
                            ThemeColor = 'Option Background';
                            ZIndex = z+1;
                            Parent = objs.holder;
                        })

                        objs.line2 = utility:Draw('Square', {
                            Position = newUDim2(0,0,0,1);
                            ThemeColor = 'Option Background';
                            ZIndex = z+1;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.line1;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.line2;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(.5,0,0,1);
                            ThemeColor = 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z;
                            Outline = true;
                            Center = true;
                            Parent = objs.holder;
                        })

                    end

                    function separator:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            local xScale = ( 1- utility:ConvertNumberRange(self.objects.text.TextBounds.X, 0, self.objects.holder.Object.Size.X, 0, 1)) / 2 - (str == '' and 0 or .04)
                            self.objects.line1.Size = newUDim2(xScale, 0, 0, 1)
                            self.objects.line2.Size = newUDim2(xScale, 0, 0, 1)
                            self.objects.line1.Position = newUDim2(0,1,.5,-1)
                            self.objects.line2.Position = newUDim2(1 - self.objects.line2.Size.X.Scale,-1,.5,-1)
                        end
                    end

                    separator:SetText(separator.text);
                    self:UpdateOptions();
                    return separator
                end

                function section:AddColor(data)
                    local color = {
                        class = 'color';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        order = #self.options+1;
                        callback = function() end;
                        color = Color3.new(1,1,1);
                        trans = 0;
                        open = false;
                        enabled = true;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and color[i] ~= nil then
                            color[i] = v
                        end
                    end

                    table.insert(self.options, color)

                    if color.flag then
                        library.flags[color.flag] = color.color;
                        library.options[color.flag] = color;
                    end

                    do
                        local objs = color.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,19);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(0,15,0,13);
                            Position = newUDim2(1,-16,0,3);
                            ZIndex = z+3;
                            Parent = objs.holder;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp45;
                            Transparency = .25;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+2;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z+1;
                            Parent = objs.border1;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = color.risky and 'Risky Text Enabled' or 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = color.state and 'Accent' or 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            color:SetOpen(not color.open);
                        end)

                    end

                    function color:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    function color:SetColor(c3, nocallback)
                        if typeof(c3) == 'Color3' then
                            local h,s,v = c3:ToHSV(); c3 = fromhsv(h, clamp(s,.005,.995), clamp(v,.005,.995));
                            self.color = c3;
                            self.objects.background.Color = c3;
                            if not nocallback then
                                self.callback(c3, self.trans);
                            end
                            if self.open then
                                window.colorpicker:Visualize(self.color, self.trans);
                            end
                            if self.flag then
                                library.flags[self.flag] = c3;
                            end
                        end
                    end

                    function color:SetTrans(trans, nocallback)
                        if typeof(trans) == 'number' then
                            self.trans = trans;
                            if not nocallback then
                                self.callback(self.color, trans);
                            end
                            if self.open then
                                window.colorpicker:Visualize(self.color, self.trans);
                            end
                        end
                    end

                    function color:SetOpen(bool)
                        if typeof(bool) == 'boolean' then
                            self.open = bool
                            local cp = window.colorpicker
                            if bool then
                                if cp.selected and cp.selected ~= color then
                                    cp.selected.open = false
                                end
                                cp.selected = color
                                local cpBg = cp.objects.background
                                cpBg.Parent = self.objects.background
                                cpBg.Visible = true
                                cpBg._roundBaseTransparency = 1
                                if cpBg.Update then
                                    cpBg:Update()
                                end
                                utility:SyncRoundGeometry(cpBg)
                                for _, part in next, cp.objects do
                                    if part.Object then
                                        part.Object.Visible = true
                                        part.Object.Transparency = 1
                                    end
                                end
                                cp:Visualize(color.color, color.trans)
                            elseif cp.selected == color then
                                cp.selected = nil
                                local cpBg = cp.objects.background
                                cpBg.Visible = false
                                cpBg.Parent = window.objects.background
                                if cpBg.Update then
                                    cpBg:Update()
                                end
                                utility:SyncRoundGeometry(cpBg)
                                for _, part in next, cp.objects do
                                    if part.Object then
                                        part.Object.Visible = false
                                    end
                                    if part._roundGeom then
                                        for _, p in next, part._roundGeom do
                                            pcall(function() p.Visible = false end)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    tooltip(color);
                    color:SetText(color.text);
                    color:SetColor(color.color, true);
                    color:SetTrans(color.trans, true);
                    self:UpdateOptions();
                    return color
                end

                function section:AddBox(data)
                    local box = {
                        class = 'box';
                        flag = data.flag;
                        text = '';
                        input = '';
                        order = #self.options+1;
                        callback = function() end;
                        enabled = true;
                        focused = false;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects', 'dragging'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and box[i] ~= nil then
                            box[i] = v;
                        end
                    end

                    table.insert(self.options, box)

                    if box.flag then
                        library.flags[box.flag] = box.input;
                        library.options[box.flag] = box;
                    end

                    do
                        local objs = box.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,37);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,15);
                            Position = newUDim2(0,2,1,-17);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .78;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = box.risky and 'Risky Text Enabled' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.inputText = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,0);
                            ThemeColor = 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.background;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            if box.focused then
                                box:ReleaseFocus();
                            else
                                box:CaptureFocus(inputservice:IsKeyDown(Enum.KeyCode.LeftControl));
                                if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) then
                                    objs.inputText.Text = '';
                                end
                            end
                        end)

                    end

                    function box:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    function box:SetInput(str, nocallback)
                        if typeof(str) == 'string' then
                            self.input = str;
                            self.objects.inputText.Text = str;
                            if not nocallback then
                                self.callback(str);
                            end
                            if self.flag then
                                library.flags[self.flag] = str;
                            end
                        end
                    end

                    local c
                    local input = box.input;
                    function box:CaptureFocus(clear)
                        box.focused = true

                        if clear then
                            input = '';
                        end

                        pcall(function()
                            actionservice:BindAction(
                                'FreezeMovement',
                                function()
                                    return Enum.ContextActionResult.Sink
                                end,
                                false,
                                unpack(Enum.PlayerActions:GetEnumItems())
                            )
                            actionservice:BindAction(
                                'SonataBoxKeys',
                                function()
                                    return Enum.ContextActionResult.Sink
                                end,
                                false,
                                Enum.KeyCode.Slash,
                                Enum.KeyCode.Period,
                                Enum.KeyCode.Escape
                            )
                        end)

                        self.objects.inputText.ThemeColor = 'Option Text 1';
                        self.objects.inputText.Text = input;
                        local tb = library._osBox
                        if tb and inputservice.TouchEnabled then
                            tb.Text = input
                            if box._osConn then
                                box._osConn:Disconnect()
                            end
                            box._osConn = tb:GetPropertyChangedSignal('Text'):Connect(function()
                                if box.focused then
                                    input = tb.Text
                                    self.objects.inputText.Text = input
                                end
                            end)
                            pcall(function()
                                tb:CaptureFocus()
                            end)
                        end
                        c = utility:Connection(inputservice.InputBegan, function(inp)
                            if inputservice.TouchEnabled and library._osBox and library._osBox:IsFocused() and inp.UserInputType == Enum.UserInputType.Keyboard then
                                return
                            end
                            if inp.UserInputType ~= Enum.UserInputType.Keyboard and inp.UserInputType ~= Enum.UserInputType.MouseButton1 then
                                return
                            end
                            if inp.KeyCode == Enum.KeyCode.Return or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                                box:ReleaseFocus(true);
                            elseif inp.KeyCode == Enum.KeyCode.Escape then
                                input = self.input
                                self.objects.inputText.Text = input;
                                box:ReleaseFocus();
                            elseif inp.KeyCode == Enum.KeyCode.Backspace then
                                if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) or inputservice:IsKeyDown(Enum.KeyCode.RightControl) then
                                    input = '';
                                else
                                    input = string.sub(input, 1, -2);
                                end
                                self.objects.inputText.Text = input;
                            else
                                if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) or inputservice:IsKeyDown(Enum.KeyCode.RightControl) then
                                    if inp.KeyCode == Enum.KeyCode.V then
                                        local clip = '';
                                        pcall(function()
                                            local env = getfenv()
                                            local fn = env.getclipboard or env.get_clipboard
                                            if typeof(fn) ~= 'function' and type(env.syn) == 'table' then
                                                fn = env.syn.getclipboard or env.syn.get_clipboard
                                            end
                                            if typeof(fn) == 'function' then
                                                clip = tostring(fn() or '')
                                            end
                                        end)
                                        if clip ~= '' then
                                            clip = string.gsub(clip, '[\r\n\t]', ' ')
                                            clip = string.gsub(clip, '%s+', ' ')
                                            input = input .. clip
                                            self.objects.inputText.Text = input
                                        end
                                    end
                                    return
                                end
                                local keyString = boxKeyToChar(inp.KeyCode)
                                if type(keyString) == 'string' and keyString ~= '' then
                                    input = input .. keyString;
                                    self.objects.inputText.Text = input;
                                end
                            end
                        end)

                    end

                    function box:ReleaseFocus(apply)
                        box.focused = false;
                        if box._osConn then
                            box._osConn:Disconnect()
                            box._osConn = nil
                        end
                        if library._osBox and library._osBox:IsFocused() then
                            pcall(function()
                                library._osBox:ReleaseFocus()
                            end)
                        end
                        self.objects.inputText.ThemeColor = 'Option Text 2';
                        pcall(function()
                            actionservice:UnbindAction('FreezeMovement');
                            actionservice:UnbindAction('SonataBoxKeys');
                        end)
                        if apply then
                            local cleaned = string.gsub(input or '', '[\r\n\t]', ' ')
                            cleaned = string.gsub(cleaned, '%s+', ' ')
                            cleaned = string.gsub(cleaned, '^%s+', '')
                            cleaned = string.gsub(cleaned, '%s+$', '')
                            input = cleaned
                            box:SetInput(cleaned);
                        end
                        if c then
                            c:Disconnect();
                        end
                    end

                    tooltip(box);
                    box:SetText(box.text);
                    box:SetInput(box.input, true);
                    self:UpdateOptions();
                    return box
                end

                function section:AddBind(data)
                    local bind = {
                        class = 'bind';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        bind = 'none';
                        mode = 'toggle';
                        order = #self.options+1;
                        callback = function() end;
                        keycallback = function() end;
                        indicatorValue = library.keyIndicator:AddValue({value = 'value', key = 'key', enabled = false});
                        noindicator = false;
                        state = false;
                        nomouse = false;
                        enabled = true;
                        binding = false;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and bind[i] ~= nil then
                            bind[i] = v
                        end
                    end

                    table.insert(self.options, bind)

                    if bind.flag then
                        library.options[bind.flag] = bind;
                    end

                    do
                        local objs = bind.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,19);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = bind.risky and 'Risky Text' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.keyText = utility:Draw('Text', {
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Parent = objs.holder;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.keyText.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.keyText.ThemeColor = bind.binding and 'Accent' or 'Option Text 3';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            if not bind.binding then
                                bind:SetKeyText('...');
                                bind.binding = true;
                            end
                        end)

                    end

                    local c

                    function bind:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            self.indicatorValue:SetKey(str);
                        end
                    end

                    function bind:SetBind(keybind)
                        if c then
                            c:Disconnect();
                            if bind.flag then
                                library.flags[bind.flag] = false;
                            end
                            bind.callback(false);
                        end
                        local keyName = 'NONE'
                        self.bind = (keybind and keybind) or keybind or self.bind
                        if self.bind == Enum.KeyCode.Backspace then
                            self.bind = 'none';
                        else
                            keyName = keyNames[keybind] or keybind.Name or keybind
                        end
                        self.keycallback(self.bind);
                        self:SetKeyText(keyName:upper());
                        self.indicatorValue:SetKey((self.text == nil or self.text == '') and (self.flag == nil and 'unknown' or self.flag) or self.text);
                        self.indicatorValue:SetValue('['..keyName:upper()..']');
                        self.objects.keyText.ThemeColor = self.objects.holder.Hover and 'Accent' or 'Option Text 3';
                    end

                    function bind:SetKeyText(str)
                        str = tostring(str);
                        self.objects.keyText.Text = '['..str..']';
                        self.objects.keyText.Position = newUDim2(1,-self.objects.keyText.TextBounds.X, 0, 2);
                    end

                    utility:Connection(inputservice.InputBegan, function(inp)
                        if inputservice:GetFocusedTextBox() then
                            return
                        elseif bind.binding then
                            local key = (table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}, inp.UserInputType) and not bind.nomouse) and inp.UserInputType
                            bind:SetBind(key or (not table.find(blacklistedKeys, inp.KeyCode)) and inp.KeyCode)
                            bind.binding = false
                        elseif not bind.binding and self.bind == 'none' then
                            bind.state = true
                            library.flags[bind.flag] = bind.state
                        elseif (inp.KeyCode == bind.bind or inp.UserInputType == bind.bind) and not bind.binding then
                            if bind.mode == 'toggle' then
                                bind.state = not bind.state
                                if bind.flag then
                                    library.flags[bind.flag] = bind.state;
                                end
                                bind.callback(bind.state)
                                bind.indicatorValue:SetEnabled(bind.state and not bind.noindicator);
                            elseif bind.mode == 'hold' then
                                if bind.flag then
                                    library.flags[bind.flag] = true;
                                end
                                bind.indicatorValue:SetEnabled(true and not bind.noindicator);
                                c = utility:Connection(runservice.RenderStepped, function()
                                    bind.callback(true);
                                end)
                            end
                        end
                    end)

                    utility:Connection(inputservice.InputEnded, function(inp)
                        if bind.bind ~= 'none' then
                            if inp.KeyCode == bind.bind or inp.UserInputType == bind.key then
                                if c then
                                    c:Disconnect();
                                    if bind.flag then
                                        library.flags[bind.flag] = false;
                                    end
                                    bind.callback(false);
                                    bind.indicatorValue:SetEnabled(false);
                                end
                            end
                        end
                    end)

                    tooltip(bind);
                    bind:SetBind(bind.bind);
                    bind:SetText(bind.text);
                    self:UpdateOptions();
                    return bind
                end

                function section:AddList(data)
                    local list = {
                        class = 'list';
                        flag = data.flag;
                        text = '';
                        selected = '';
                        tooltip = '';
                        order = #self.options+1;
                        callback = function() end;
                        enabled = true;
                        multi = false;
                        open = false;
                        risky = false;
                        values = {};
                        objects = {};
                    }

                    table.insert(self.options, list);

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) ~= list[i] ~= nil then
                            list[i] = v
                        end
                    end

                    if list.flag then
                        library.flags[list.flag] = list.selected;
                        library.options[list.flag] = list;
                    end

                    do
                        local objs = list.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,40);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,15);
                            Position = newUDim2(0,2,1,-19);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .78;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = list.risky and 'Risky Text Enabled' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.inputText = utility:Draw('Text', {
                            Position = newUDim2(0,4,0,0);
                            ThemeColor = 'Option Text 2';
                            Text = 'none',
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.background;
                        })

                        objs.openText = utility:Draw('Text', {
                            Position = newUDim2(1,-10,0,0);
                            ThemeColor = 'Option Text 3';
                            Text = '+';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.background;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            if list.open then
                                list.open = false;
                                objs.openText.Text = '+';
                                if window.dropdown.selected == list then
                                    window.dropdown.selected = nil;
                                    window.dropdown.objects.background.Visible = false;
                                end
                            else
                                if window.dropdown.selected ~= nil then
                                    window.dropdown.selected.open = false
                                end
                                list.open = true;
                                objs.openText.Text = '-';
                                window.dropdown.selected = list;
                                window.dropdown.objects.background.Visible = true;
                                window.dropdown.objects.background.Parent = objs.holder;
                                do
                                    local scrollTo = 0
                                    local sel = list.selected
                                    if typeof(sel) == 'string' then
                                        local found = table.find(list.values, sel)
                                        if found then scrollTo = math.max(0, found - 1) end
                                    end
                                    window.dropdown.scroll = scrollTo
                                end
                                window.dropdown:Refresh();
                            end
                        end)

                    end

                    function list:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    function list:Select(option, nocallback)
                        option = typeof(option) == 'table' and (self.multi == true and option or (#option == 0 and nil or option[1])) or self.multi == true and {option} or option;
                        if option ~= nil then
                            self.selected = option;
                            local text = typeof(option) == 'table' and (#option == 0 and "none" or table.concat(option, ', ')) or tostring(option);
                            local label = self.objects.inputText
                            label.Text = text;
                            if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                local split = text:split('');
                                for i = 1,#split do
                                    label.Text = table.concat(split, '', 1, i)
                                    if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                        label.Text = label.Text:sub(1,-6)..'...';
                                        break
                                    end
                                end
                            end
                            if self.flag then
                                library.flags[self.flag] = self.selected
                            end
                            if not nocallback then
                                self.callback(self.selected);
                            end
                        end
                    end

                    function list:AddValue(value)
                        table.insert(list.values, tostring(value));
                        if window.dropdown.selected == list then
                            window.dropdown:Refresh()
                        end
                    end

                    function list:RemoveValue(value)
                        if table.find(list.values, value) then
                            table.remove(list.values, table.find(list.values, value));
                            if window.dropdown.selected == list then
                                window.dropdown:Refresh()
                            end
                        end
                    end

                    function list:ClearValues()
                        table.clear(list.values);
                        if window.dropdown.selected == list then
                            window.dropdown:Refresh()
                        end
                    end

                    tooltip(list);
                    list:Select((data.value or data.selected) or (list.multi and 'none' or list.values[1]), true);
                    list:SetText(list.text);
                    self:UpdateOptions();
                    return list
                end

                function section:AddScrollList(data)
                    local scrolllist = {
                        class = 'scrolllist';
                        flag = data.flag;
                        text = '';
                        selected = '';
                        tooltip = '';
                        order = #self.options+1;
                        callback = function() end;
                        enabled = true;
                        risky = false;
                        values = {};
                        scroll = 0;
                        max = 12;
                        hovered = false;
                        objects = {};
                        rows = {};
                    };

                    table.insert(self.options, scrolllist);

                    local blacklist = {'objects', 'rows', 'values'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and scrolllist[i] ~= nil then
                            scrolllist[i] = v
                        end
                    end
                    if typeof(data.max) == 'number' then
                        scrolllist.max = math.max(3, math.floor(data.max))
                    end
                    if typeof(data.values) == 'table' then
                        table.clear(scrolllist.values)
                        for _, value in next, data.values do
                            table.insert(scrolllist.values, tostring(value))
                        end
                    end

                    if scrolllist.flag then
                        library.flags[scrolllist.flag] = scrolllist.selected;
                        library.options[scrolllist.flag] = scrolllist;
                    end

                    local rowH, rowPad = 18, 2
                    local listH = 4 + scrolllist.max * (rowH + rowPad)
                    local lastHolderH = -1
                    scrolllist.fill = data.fill == true
                    scrolllist.reserveExtra = typeof(data.reserve) == 'number' and data.reserve or 0

                    do
                        local objs = scrolllist.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0, listH + 18);
                            Transparency = 0;
                            ZIndex = z;
                            Parent = section.objects.optionholder;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = scrolllist.risky and 'Risky Text Enabled' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,listH);
                            Position = newUDim2(0,2,0,16);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        local function setHoverAccent(on)
                            objs.border1.ThemeColor = on and 'Accent' or 'Option Border 1'
                        end

                        local function mouseOverList(pos)
                            local bg = objs.background.Object
                            return bg ~= nil and bg.Visible == true and utility:MouseOver(bg, pos)
                        end
                        scrolllist.mouseOverList = mouseOverList

                        local function pickFromMouse(pos)
                            local bg = objs.background.Object
                            if not bg then
                                return
                            end
                            local relY = pos.Y - bg.Position.Y
                            local slot = math.floor((relY - 2) / (rowH + rowPad)) + 1
                            if slot < 1 or slot > scrolllist.max then
                                return
                            end
                            local idx = (scrolllist.scroll or 0) + slot
                            local val = scrolllist.values[idx]
                            if val ~= nil then
                                scrolllist:Select(val)
                            end
                        end

                        utility:Connection(objs.background.MouseButton1Down, function(pos)
                            pickFromMouse(pos or utility:MouseLocation())
                        end)

                        local function createRow(slot)
                            local row = {};
                            row.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,0,rowH);
                                Position = newUDim2(0,2,0,2 + (slot-1)*(rowH+rowPad));
                                Color = Color3.new(.25,.25,.25);
                                Transparency = 0;
                                Visible = false;
                                ZIndex = z+5;
                                Parent = objs.background;
                            })
                            row.text = utility:Draw('Text', {
                                Position = newUDim2(0,4,0,1);
                                ThemeColor = 'Option Text 2';
                                Text = '';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+6;
                                Outline = true;
                                Parent = row.background;
                            })
                            row.slot = slot
                            utility:Connection(row.background.MouseButton1Down, function()
                                local idx = (scrolllist.scroll or 0) + row.slot
                                local val = scrolllist.values[idx]
                                if val ~= nil then
                                    scrolllist:Select(val)
                                end
                            end)
                            scrolllist.rows[slot] = row
                            return row
                        end

                        for slot = 1, scrolllist.max do
                            createRow(slot)
                        end
                        scrolllist._createRow = createRow

                        utility:Connection(mousemove, function()
                            if not library.open or not scrolllist.enabled then
                                scrolllist.hovered = false
                                return
                            end
                            local over = mouseOverList()
                            if over ~= scrolllist.hovered then
                                scrolllist.hovered = over
                                setHoverAccent(over)
                            end
                        end)
                    end

                    function scrolllist:SetVisibleCount(count)
                        count = math.clamp(math.floor(tonumber(count) or self.max), 4, 32)
                        if count == self.max and self.rows[count] then
                            return false
                        end
                        if count > self.max then
                            for slot = self.max + 1, count do
                                if not self.rows[slot] and self._createRow then
                                    self._createRow(slot)
                                end
                            end
                        else
                            for slot = count + 1, self.max do
                                local row = self.rows[slot]
                                if row then
                                    row.background.Visible = false
                                end
                            end
                        end
                        self.max = count
                        listH = 4 + self.max * (rowH + rowPad)
                        self.objects.background.Size = newUDim2(1,-4,0,listH)
                        self:Refresh(true)
                        return true
                    end

                    function scrolllist:AutoFill()
                        if not self.fill then
                            return false
                        end
                        local col = window.objects['columnholder' .. tostring(section.side)]
                        local colObj = col and col.Object
                        if not colObj then
                            return false
                        end
                        local used = 0
                        for _, opt in next, section.options do
                            if opt ~= self and opt.enabled ~= false then
                                local h = 0
                                if opt.class == 'box' or opt.class == 'textbox' then
                                    h = 38
                                elseif opt.class == 'button' then
                                    h = 24
                                elseif opt.class == 'toggle' then
                                    h = 20
                                elseif opt.class == 'slider' then
                                    h = 28
                                elseif opt.class == 'list' then
                                    h = 40
                                elseif opt.objects and opt.objects.holder and opt.objects.holder.Object then
                                    h = opt.objects.holder.Object.Size.Y
                                else
                                    h = 24
                                end
                                used += h + 4
                            end
                        end
                        local chrome = 22 + (self.reserveExtra or 0)
                        local available = colObj.Size.Y - used - chrome
                        local rows = math.floor((available - 4) / (rowH + rowPad))
                        rows = math.clamp(rows, 3, 10)
                        if available < 4 + 3 * (rowH + rowPad) then
                            rows = 3
                        end
                        return self:SetVisibleCount(rows)
                    end

                    function scrolllist:Refresh(relayout)
                        local maxScroll = math.max(0, #self.values - self.max)
                        self.scroll = math.clamp(self.scroll or 0, 0, maxScroll)
                        local hasLabel = self.text ~= nil and self.text ~= ''
                        local holderH = listH + (hasLabel and 18 or 4)
                        self.objects.text.Visible = hasLabel
                        self.objects.background.Position = newUDim2(0,2,0, hasLabel and 16 or 2)
                        self.objects.background.Size = newUDim2(1,-4,0,listH)
                        local sizeChanged = lastHolderH ~= holderH
                        lastHolderH = holderH
                        self.objects.holder.Size = newUDim2(1,0,0, holderH)
                        for slot = 1, self.max do
                            local row = self.rows[slot]
                            if not row then
                                continue
                            end
                            local valueStr = self.values[self.scroll + slot]
                            if valueStr ~= nil then
                                row.background.Visible = true
                                local label = tostring(valueStr)
                                row.text.Text = label
                                local maxW = self.objects.background.Object and (self.objects.background.Object.Size.X - 12) or 120
                                if row.text.TextBounds.X > maxW and maxW > 20 then
                                    local split = label:split('')
                                    for i = 1, #split do
                                        row.text.Text = table.concat(split, '', 1, i)
                                        if row.text.TextBounds.X > maxW then
                                            row.text.Text = row.text.Text:sub(1, -6) .. '...'
                                            break
                                        end
                                    end
                                end
                                local selected = self.selected == valueStr
                                row.background.Transparency = selected and 1 or 0.35
                                row.text.ThemeColor = selected and 'Accent' or 'Option Text 2'
                            else
                                row.background.Visible = false
                            end
                        end
                        if relayout or sizeChanged then
                            section:UpdateOptions();
                        end
                    end

                    function scrolllist:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            self:Refresh(true);
                        end
                    end

                    function scrolllist:Select(option, nocallback)
                        if option == nil then
                            return
                        end
                        local picked = typeof(option) == 'table' and option[1] or option;
                        if picked == nil then
                            return
                        end
                        self.selected = tostring(picked);
                        if self.flag then
                            library.flags[self.flag] = self.selected
                        end
                        local found = table.find(self.values, self.selected)
                        if found then
                            if found <= self.scroll then
                                self.scroll = math.max(0, found - 1)
                            elseif found > self.scroll + self.max then
                                self.scroll = found - self.max
                            end
                        end
                        self:Refresh();
                        if not nocallback then
                            self.callback(self.selected);
                        end
                    end

                    function scrolllist:AddValue(value)
                        table.insert(self.values, tostring(value));
                        self:Refresh();
                    end

                    function scrolllist:RemoveValue(value)
                        local idx = table.find(self.values, value)
                        if idx then
                            table.remove(self.values, idx);
                            self:Refresh();
                        end
                    end

                    function scrolllist:ClearValues()
                        table.clear(self.values);
                        self:Refresh();
                    end

                    function scrolllist:SetValues(values)
                        table.clear(self.values);
                        if type(values) == 'table' then
                            for _, value in values do
                                table.insert(self.values, tostring(value));
                            end
                        end
                        self:Refresh();
                    end

                    tooltip(scrolllist);
                    scrolllist:SetText(scrolllist.text);
                    if data.selected ~= nil or data.value ~= nil then
                        scrolllist:Select(data.selected or data.value, true);
                    elseif scrolllist.values[1] then
                        scrolllist:Select(scrolllist.values[1], true);
                    else
                        scrolllist:Refresh();
                    end
                    self:UpdateOptions();
                    return scrolllist
                end

                function section:AddText(data)
                    local text = {
                        class = 'text';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        order = #self.options+1;
                        enabled = true;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and text[i] ~= nil then
                            text[i] = v
                        end
                    end

                    if data.flag then
                        library.options[data.flag] = text;
                    end

                    table.insert(self.options, text)

                    do
                        local objs = text.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = text.risky and 'Risky Text Enabled' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })
                    end

                    function text:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            self.objects.holder.Size = newUDim2(1,0,0,self.objects.text.TextBounds.Y + 6);
                            section:UpdateOptions();
                        end
                    end

                    text:SetText(text.text);
                    self:UpdateOptions();
                    return text
                end

                section:UpdateOptions();
                section:SetText(section.text);
                self:UpdateSections();
                return section;
            end

            function tab:AddSubTabs(labels, onChanged)
                if typeof(labels) ~= 'table' or #labels == 0 then
                    return
                end
                self.subTabLabels = labels
                self.selectedSub = labels[1]
                self.subTabCallback = onChanged
                self.subTabItems = {}

                local z = library.zindexOrder.window + 75
                local holder = utility:Draw('Square', {
                    Size = newUDim2(1, -8, 0, 22);
                    Position = newUDim2(0, 4, 0, 3);
                    Parent = window.objects.groupBackground;
                    Transparency = 0;
                    Visible = false;
                    ZIndex = z;
                })
                self.subTabHolder = holder

                for _, label in labels do
                    local bg = utility:Draw('Square', {
                        Size = newUDim2(0, 50, 1, 0);
                        ThemeColor = 'Unselected Tab Background';
                        ZIndex = z + 1;
                        Parent = holder;
                    })
                    local border1 = utility:Draw('Square', {
                        Size = newUDim2(1, 2, 1, 2);
                        Position = newUDim2(0, -1, 0, -1);
                        ThemeColor = 'Border 1';
                        ZIndex = z;
                        Parent = bg;
                    })
                    utility:Draw('Square', {
                        Size = newUDim2(1, 2, 1, 2);
                        Position = newUDim2(0, -1, 0, -1);
                        ThemeColor = 'Border 3';
                        ZIndex = z - 1;
                        Parent = border1;
                    })
                    local top = utility:Draw('Square', {
                        Size = newUDim2(1, 0, 0, 1);
                        ThemeColor = 'Unselected Tab Background';
                        ZIndex = z + 2;
                        Parent = bg;
                    })
                    local text = utility:Draw('Text', {
                        ThemeColor = 'Unselected Tab Text';
                        Text = tostring(label);
                        Size = 13;
                        Font = 2;
                        ZIndex = z + 3;
                        Outline = true;
                        Center = true;
                        Parent = bg;
                    })
                    local item = { label = tostring(label), background = bg, text = text, top = top }
                    table.insert(self.subTabItems, item)
                    utility:Connection(bg.MouseButton1Down, function()
                        self.selectedSub = item.label
                        window.columnScroll[1] = 0
                        window.columnScroll[2] = 0
                        window.columnScrollTarget[1] = 0
                        window.columnScrollTarget[2] = 0
                        self:UpdateSubTabs()
                        self:UpdateSections()
                        if self.subTabCallback then
                            self.subTabCallback(item.label)
                        end
                    end)
                end

                function self:UpdateSubTabs()
                    if not self.subTabHolder then
                        return
                    end
                    local show = self.selected == true
                    self.subTabHolder.Visible = show
                    for _, item in self.subTabItems do
                        item.background.Visible = show
                        item.text.Visible = show
                        item.top.Visible = show
                    end
                    if not show then
                        return
                    end
                    local count = #self.subTabItems
                    if count <= 0 then
                        return
                    end
                    pcall(function()
                        self.subTabHolder:Update()
                    end)
                    local holderObj = self.subTabHolder.Object
                    local totalW = (holderObj and holderObj.Size and holderObj.Size.X) or 0
                    if totalW < 1 then
                        local gb = window.objects.groupBackground and window.objects.groupBackground.Object
                        totalW = gb and math.max(0, gb.Size.X - 8) or 200
                    end
                    local gap = 2
                    local usable = math.max(count, totalW - gap * (count - 1))
                    local base = math.floor(usable / count)
                    local extra = usable - base * count
                    local pos = 0
                    for i, item in self.subTabItems do
                        local selected = item.label == self.selectedSub
                        local w = math.max(1, base + (i <= extra and 1 or 0))
                        item.background.ThemeColor = selected and 'Selected Tab Background' or 'Unselected Tab Background'
                        item.text.ThemeColor = selected and 'Selected Tab Text' or 'Unselected Tab Text'
                        item.top.ThemeColor = selected and 'Accent' or 'Unselected Tab Background'
                        item.background.Size = newUDim2(0, w, 1, selected and 1 or 0)
                        item.background.Position = newUDim2(0, pos, 0, 0)
                        item.text.Position = newUDim2(.5, 0, 0, 3)
                        pos += w + gap
                    end
                end

                self:UpdateSubTabs()
                return self
            end

			function tab:UpdateSections()
                if window._uiDragging or self._updatingSections then
                    return
                end
                self._updatingSections = true
                local ok, err = pcall(function()
                table.sort(self.sections, function(a,b)
                    return a.order < b.order
                end)

                local padding = 12;
                local col1 = window.objects.columnholder1.Object
                local col2 = window.objects.columnholder2.Object
                local fullH1 = col1 and col1.Size.Y or 0
                local fullH2 = col2 and col2.Size.Y or 0
                local viewH1 = fullH1
                local viewH2 = fullH2
                local footerH = 0
                for _, section in next, self.sections do
                    local matchesSub = (section.subTab == nil) or (self.selectedSub == nil) or (section.subTab == self.selectedSub)
                    if section.enabled and tab.selected and matchesSub and section.span == 2 then
                        if section.objects.optionholder then
                            section.objects.optionholder.Position = newUDim2(.015, 0, 0, 13)
                        end
                        section:UpdateOptions()
                        footerH += (section.objects.background.Object.Size.Y or 0) + padding
                    end
                end
                if footerH > 0 then
                    footerH = footerH - padding
                    viewH1 = math.max(0, viewH1 - footerH - padding)
                    viewH2 = math.max(0, viewH2 - footerH - padding)
                    window._footerTop = viewH1
                else
                    window._footerTop = nil
                end
                window.columnView = { viewH1, viewH2 }
                local scroll1 = window.columnScroll[1] or 0
                local scroll2 = window.columnScroll[2] or 0
                local stack1, stack2 = 0, 0

                for _,section in next, self.sections do
                    local matchesSub = (section.subTab == nil) or (self.selectedSub == nil) or (section.subTab == self.selectedSub)
                    local shouldShow = section.enabled and tab.selected and matchesSub

                    if shouldShow and section.span == 2 then
                    elseif shouldShow then
                        if section.objects.optionholder then
                            section.objects.optionholder.Position = newUDim2(.015, 0, 0, 13)
                        end
                        section:UpdateOptions();
                        local h = section._contentHeight or section._layoutHeight or (section.objects.background.Object and section.objects.background.Object.Size.Y) or 0
                        section._layoutHeight = h
                        if section.side == 1 then
                            section._stackY = stack1
                            local y = stack1 - scroll1
                            section._layoutY = y
                            section.objects.background.Position = newUDim2(0,0,0,y)
                            local maxH = math.max(0, viewH1 - y)
                            local clampedH = math.min(h, maxH)
                            if not (library.tweens[section.objects.background] and library.tweens[section.objects.background].Size) then
                                section.objects.background.Size = newUDim2(1,0,0,clampedH)
                            end
                            section.objects.background.Visible = (y + h > 0) and (y < viewH1)
                            stack1 += h + padding
                        elseif section.side == 2 then
                            section._stackY = stack2
                            local y = stack2 - scroll2
                            section._layoutY = y
                            section.objects.background.Position = newUDim2(0,0,0,y)
                            local maxH = math.max(0, viewH2 - y)
                            local clampedH = math.min(h, maxH)
                            if not (library.tweens[section.objects.background] and library.tweens[section.objects.background].Size) then
                                section.objects.background.Size = newUDim2(1,0,0,clampedH)
                            end
                            section.objects.background.Visible = (y + h > 0) and (y < viewH2)
                            stack2 += h + padding
                        else
                            section.objects.background.Visible = false
                        end
                    else
                        section._layoutY = nil
                        section._stackY = nil
                        section.objects.background.Visible = false
                        if section.objects.textlabel then section.objects.textlabel.Visible = false end
                        if section.objects.topBorder1 then section.objects.topBorder1.Visible = false end
                        if section.objects.topBorder2 then section.objects.topBorder2.Visible = false end
                        for _, opt in next, section.options do
                            local h = opt.objects and opt.objects.holder
                            if h then
                                if h.Visible ~= false then
                                    h.Visible = false
                                end
                                if h.Update then
                                    h:Update()
                                end
                            end
                        end
                    end

                    if section.objects.background.Visible then
                        section:SetText(section.text)
                    end
                end

                local spanW = 1
                if col1 and col2 and col1.Size.X > 1 then
                    spanW = (col2.Position.X + col2.Size.X - col1.Position.X) / col1.Size.X
                end
                local footerY = math.max(0, fullH1 - footerH)
                for _, section in next, self.sections do
                    local matchesSub = (section.subTab == nil) or (self.selectedSub == nil) or (section.subTab == self.selectedSub)
                    if section.enabled and tab.selected and matchesSub and section.span == 2 then
                        local h = section._contentHeight or section._layoutHeight or (section.objects.background.Object and section.objects.background.Object.Size.Y) or 0
                        section._layoutHeight = h
                        section._layoutY = footerY
                        if section.objects.background.Parent ~= window.objects.columnholder1 then
                            section.objects.background.Parent = window.objects.columnholder1
                        end
                        section.objects.background.Position = newUDim2(0, 0, 0, footerY)
                        section.objects.background.Size = newUDim2(spanW, 0, 0, h)
                        section.objects.background.Visible = h > 0
                        footerY += h + padding
                        section:SetText(section.text)
                    end
                end

                window.columnContent[1] = math.max(0, stack1 > 0 and (stack1 - padding) or 0)
                window.columnContent[2] = math.max(0, stack2 > 0 and (stack2 - padding) or 0)
                local maxScroll1 = math.max(0, (window.columnContent[1] or 0) - viewH1)
                local maxScroll2 = math.max(0, (window.columnContent[2] or 0) - viewH2)
                window.columnScroll[1] = math.clamp(window.columnScroll[1] or 0, 0, maxScroll1)
                window.columnScroll[2] = math.clamp(window.columnScroll[2] or 0, 0, maxScroll2)
                window.columnScrollTarget[1] = math.clamp(window.columnScrollTarget[1] or window.columnScroll[1], 0, maxScroll1)
                window.columnScrollTarget[2] = math.clamp(window.columnScrollTarget[2] or window.columnScroll[2], 0, maxScroll2)
                for _, section in next, self.sections do
                    if section.span ~= 2 and section._stackY ~= nil then
                        local colObj = if section.side == 1 then col1 else col2
                        local viewH = if section.side == 1 then viewH1 else viewH2
                        window:ClipSectionToColumn(section, colObj, viewH)
                    end
                end

                if not self._fillingLists then
                    local changed = false
                    for _, section in next, self.sections do
                        if section.objects.background.Visible then
                            for _, opt in next, section.options do
                                if opt.class == 'scrolllist' and opt.fill and opt.AutoFill then
                                    if opt:AutoFill() then
                                        changed = true
                                    end
                                end
                            end
                        end
                    end
                    if changed then
                        self._fillingLists = true
                        self._updatingSections = false
                        self:UpdateSections()
                        self._fillingLists = false
                        return
                    end
                end

                for _, section in next, self.sections do
                    if section.objects.background.Visible then
                        if section.span == 2 and col1 then
                            window:ClipSectionToColumn(section, col1, fullH1)
                        elseif section.side == 1 and col1 then
                            window:ClipSectionToColumn(section, col1, viewH1)
                        elseif section.side == 2 and col2 then
                            window:ClipSectionToColumn(section, col2, viewH2)
                        end
                    end
                end
                end)
                self._updatingSections = false
                if not ok then
                    warn('[Octohook] UpdateSections error: ' .. tostring(err))
                end
            end

            function tab:SetText(str)
                if typeof(str) == 'string' then
                    self.text = str;
                    self.objects.text.Text = str;
                    window:UpdateTabs();
                end
            end

            function tab:Select()
                if window.selectedTab == tab and tab._initialized then
                    return
                end
                tab._initialized = true
                window.selectedTab = tab;
                window.columnScroll[1] = 0
                window.columnScroll[2] = 0
                window.columnScrollTarget[1] = 0
                window.columnScrollTarget[2] = 0
                window:UpdateTabs();
                for i,v in next, window.tabs do
                    if v.callback then
                        v.callback(v == tab)
                    end
                end
            end

            if window.selectedTab == nil then
                tab:Select();
            end

            tab:SetText(tab.text);
            window:UpdateTabs();
            return tab;
        end

        function window:SetSize(w, h)
            local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or newVector2(1280, 720)
            local capW = math.max(280, vs.X - 12)
            local capH = math.max(240, vs.Y - 28)
            local minW = math.min(420, capW)
            local minH = math.min(340, capH)
            w = math.floor(math.clamp(tonumber(w) or 600, minW, math.min(1000, capW)) + 0.5)
            h = math.floor(math.clamp(tonumber(h) or 499, minH, math.min(900, capH)) + 0.5)
            local cur = self.objects.background.Size
            if cur and cur.X.Offset == w and cur.Y.Offset == h then
                return
            end
            self.objects.background.Size = newUDim2(0, w, 0, h)
            self:UpdateTabs()
        end

        function window:LayoutTitleBar()
            local o = self.objects
            if not o or not o.titleGet then
                return
            end
            local x = 7
            o.titleGet.Position = newUDim2(0, x, 0, 2)
            x += (o.titleGet.TextBounds and o.titleGet.TextBounds.X) or 18
            o.titleName.Position = newUDim2(0, x, 0, 2)
            x += (o.titleName.TextBounds and o.titleName.TextBounds.X) or 42
            o.titleSuffix.Position = newUDim2(0, x, 0, 2)
            local roleW = (o.titleRole and o.titleRole.TextBounds and o.titleRole.TextBounds.X) or 62
            if o.titleRole then
                o.titleRole.Position = newUDim2(1, -(roleW + 8), 0, 3)
            end
        end

        function window:UpdateTabs()
            table.sort(self.tabs, function(a,b)
                return a.order < b.order
            end)
            local selected = self.selectedTab
            local n = #self.tabs
            local bgSize = self.objects.background.Size
            local barW = math.max(n, ((bgSize and bgSize.X.Offset) or 600) - 16)
            for i,v in ipairs(self.tabs) do
                local objs = v.objects;
                local isSel = (v == selected)
                v.selected = isSel;
                objs.background.ThemeColor = isSel and 'Group Background' or 'Unselected Tab Background';
                local x0 = math.floor(barW * (i - 1) / n + 0.5)
                local x1 = math.floor(barW * i / n + 0.5)
                local gap = if i == n then 0 else 1
                objs.background.Size = newUDim2(0, x1 - x0 - gap, 0, isSel and 21 or 20);
                objs.background.Position = newUDim2(0, x0, 0, 0)
                objs.innerBorder.Size = newUDim2(1, 2, 1, isSel and 0 or 2)
                objs.outerBorder.Size = newUDim2(1, 2, 1, 1)

                objs.text.ThemeColor = isSel and 'Selected Tab Text' or 'Unselected Tab Text';
                objs.text.Position = newUDim2(.5, 0, 0, 3);
                objs.text.Font = 0;
                objs.text.Size = 12;
                objs.topBorder.ThemeColor = isSel and 'Accent' or 'Unselected Tab Background';

                if v.UpdateSubTabs then
                    v:UpdateSubTabs()
                end
            end
            self._tabsInitialized = true

            local topPad = 10
            if selected and selected.subTabHolder and selected.selected then
                topPad = 32
            end
            window:ApplyColumnLayout(topPad)

            local prevTab = self._currentActiveTab
            self._currentActiveTab = selected

            if prevTab and prevTab ~= selected then
                for _, section in next, prevTab.sections do
                    section.objects.background.Visible = false
                    if section.objects.textlabel then section.objects.textlabel.Visible = false end
                    if section.objects.topBorder1 then section.objects.topBorder1.Visible = false end
                    if section.objects.topBorder2 then section.objects.topBorder2.Visible = false end
                    for _, opt in next, section.options do
                        local h = opt.objects and opt.objects.holder
                        if h then
                            if h.Visible ~= false then
                                h.Visible = false
                            end
                            if h.Update then
                                h:Update()
                            end
                        end
                    end
                end
            end

            if selected then
                if selected.UpdateSubTabs then
                    if not selected.selectedSub and selected.subTabLabels then
                        selected.selectedSub = selected.subTabLabels[1]
                    end
                    selected:UpdateSubTabs()
                end
                selected:UpdateSections();
            end
        end

        utility:Connection(inputservice.InputChanged, function(input)
            if not library.open or not window.open then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseWheel then
                return
            end
            local tab = window.selectedTab
            if not tab then
                return
            end
            local delta = 0
            pcall(function()
                delta = input.Position.Z
            end)
            if delta == 0 then
                return
            end
            local step = delta > 0 and -1 or 1

            for _, section in next, tab.sections do
                if section.objects.background.Visible then
                    for _, opt in next, section.options do
                        if opt.class == 'scrolllist' and opt.enabled and opt.mouseOverList and opt.mouseOverList() then
                            local maxScroll = math.max(0, #opt.values - opt.max)
                            if maxScroll > 0 then
                                opt.scroll = math.clamp((opt.scroll or 0) + step, 0, maxScroll)
                                opt:Refresh()
                            end
                            return
                        end
                    end
                end
            end

            local amount = step * ((library.anim and library.anim.scrollStep) or 22)
            local col1 = window.objects.columnholder1.Object
            local col2 = window.objects.columnholder2.Object
            local view = window.columnView
            local winBg = window.objects.background.Object
            local mPos = utility:MouseLocation()

            local isOverCol1 = col1 and utility:MouseOver(col1, mPos)
            local isOverCol2 = col2 and utility:MouseOver(col2, mPos)
            if not isOverCol1 and not isOverCol2 and winBg and utility:MouseOver(winBg, mPos) then
                local midX = winBg.Position.X + winBg.Size.X * 0.5
                if mPos.X < midX then
                    isOverCol1 = true
                else
                    isOverCol2 = true
                end
            end

            if isOverCol1 then
                local viewH = (view and view[1]) or (col1 and col1.Size.Y) or 0
                local maxScroll = math.max(0, (window.columnContent[1] or 0) - viewH)
                local cur = window.columnScrollTarget[1] or window.columnScroll[1] or 0
                window.columnScrollTarget[1] = math.clamp(cur + amount, 0, maxScroll)
            elseif isOverCol2 then
                local viewH = (view and view[2]) or (col2 and col2.Size.Y) or 0
                local maxScroll = math.max(0, (window.columnContent[2] or 0) - viewH)
                local cur = window.columnScrollTarget[2] or window.columnScroll[2] or 0
                window.columnScrollTarget[2] = math.clamp(cur + amount, 0, maxScroll)
            end
        end)

        local function applySmoothColumnScroll(tab)
            local col1 = window.objects.columnholder1.Object
            local col2 = window.objects.columnholder2.Object
            local view = window.columnView
            local viewH1 = (view and view[1]) or (col1 and col1.Size.Y) or 0
            local viewH2 = (view and view[2]) or (col2 and col2.Size.Y) or 0
            local scroll1 = window.columnScroll[1] or 0
            local scroll2 = window.columnScroll[2] or 0
            for _, section in next, tab.sections do
                if section.span == 2 or section._stackY == nil then
                    continue
                end
                local h = section._contentHeight or section._layoutHeight or (section.objects.background.Object and section.objects.background.Object.Size.Y) or 0
                local scroll = if section.side == 1 then scroll1 else scroll2
                local viewH = if section.side == 1 then viewH1 else viewH2
                local colObj = if section.side == 1 then col1 else col2
                local y = section._stackY - scroll
                section._layoutY = y
                local shown = section.enabled and tab.selected and (y + h > 0) and (y < viewH)
                section.objects.background.Position = newUDim2(0, 0, 0, y)
                section.objects.background.Visible = shown
                if colObj then
                    window:ClipSectionToColumn(section, colObj, viewH)
                end
            end
        end

        if not window._smoothScrollConn then
            window._smoothScrollConn = utility:Connection(runservice.RenderStepped, function(dt)
                if not library.open or not window.open then
                    return
                end
                local tab = window.selectedTab
                if not tab or window._uiDragging then
                    return
                end
                local speed = (library.anim and library.anim.scrollLerp) or 14
                local alpha = 1 - math.exp(-dt * speed)
                local changed = false
                for i = 1, 2 do
                    local cur = window.columnScroll[i] or 0
                    local tgt = window.columnScrollTarget[i] or cur
                    if cur ~= tgt then
                        local diff = tgt - cur
                        if math.abs(diff) < 0.5 then
                            window.columnScroll[i] = tgt
                            changed = true
                        else
                            local nextVal = cur + diff * alpha
                            if math.abs(nextVal - tgt) < 0.5 then
                                nextVal = tgt
                            end
                            window.columnScroll[i] = nextVal
                            changed = true
                        end
                    end
                end
                if changed then
                    applySmoothColumnScroll(tab)
                end
            end)
        end

        window:LayoutTitleBar();
        window:SetOpen(true);
        task.defer(function()
            if library.fitOpenWindow then
                library.fitOpenWindow()
            end
        end)
        return window;
    end

    do
        local z = library.zindexOrder.window + 2000;
        tooltipObjects.background = utility:Draw('Square', {
            ThemeColor = 'Group Background';
            ZIndex = z;
            Visible = false;
        })

        tooltipObjects.border1 = utility:Draw('Square', {
            Size = UDim2.new(1,2,1,2);
            Position = UDim2.new(0,-1,0,-1);
            ThemeColor = 'Border 1';
            ZIndex = z-1;
            Parent = tooltipObjects.background;
        })

        tooltipObjects.border2 = utility:Draw('Square', {
            Size = UDim2.new(1,4,1,4);
            Position = UDim2.new(0,-2,0,-2);
            ThemeColor = 'Border 3';
            ZIndex = z-2;
            Parent = tooltipObjects.background;
        })

        tooltipObjects.text = utility:Draw('Text', {
            Position = UDim2.new(0,3,0,0);
            ThemeColor = 'Primary Text';
            Size = 13;
            Font = 2;
            ZIndex = z+1;
            Outline = true;
            Parent = tooltipObjects.background;
        })

        tooltipObjects.riskytext = utility:Draw('Text', {
            Position = UDim2.new(0,3,0,0);
            ThemeColor = 'Risky Text Enabled';
            Text = '[RISKY]';
            Size = 13;
            Font = 2;
            ZIndex = z+1;
            Outline = true;
            Parent = tooltipObjects.background;
        })

    end

    do
        if not IonHub_User then
            getgenv().IonHub_User = {
                UID = 0,
                User = "admin"
            }
        end
        self.watermark = {
            objects = {};
            lock = 'Top';
            position = newUDim2(0,0,0,0);
            refreshrate = 25;
            _mapCache = 'lobby';
            _mapCacheAt = 0;
        }

        local function resolveDuelMapName()
            local cached = library.watermark._mapCache
            local cachedAt = library.watermark._mapCacheAt
            if type(cachedAt) == 'number' and (tick() - cachedAt) < 0.35 and type(cached) == 'string' then
                return cached
            end
            local mapName = 'lobby'
            pcall(function()
                local lp = players.LocalPlayer
                if not lp then
                    return
                end
                local scripts = lp:FindFirstChild('PlayerScripts')
                local controllers = scripts and scripts:FindFirstChild('Controllers')
                local duelMod = controllers and (controllers:FindFirstChild('DuelController') or controllers:FindFirstChild('DuelsController'))
                if not duelMod then
                    return
                end
                local ok, dc = pcall(require, duelMod)
                if not ok or type(dc) ~= 'table' then
                    return
                end
                local duel = dc:GetDuel(lp)
                local map = duel and duel.Map
                if type(map) == 'table' and type(map.Name) == 'string' and map.Name ~= '' then
                    mapName = map.Name
                    return
                end
                if type(map) == 'table' and type(map.Get) == 'function' then
                    local okName, name = pcall(map.Get, map, 'Name')
                    if okName and type(name) == 'string' and name ~= '' then
                        mapName = name
                    end
                end
            end)
            library.watermark._mapCache = mapName
            library.watermark._mapCacheAt = tick()
            return mapName
        end

        function self.watermark:Update()
            self.objects.background.Visible = library.flags.watermark_enabled
            if library.flags.watermark_enabled then
                local adminName = (IonHub_User and IonHub_User.User) or 'admin'
                if type(adminName) ~= 'string' or adminName == '' then
                    adminName = 'admin'
                end
                local mapName = resolveDuelMapName()

                local brand = self.objects.brand
                local suffix = self.objects.suffix
                local rest = self.objects.text
                brand.Text = 'sonata'
                suffix.Text = '.ru'
                suffix.Color = fromrgb(255, 255, 255)
                rest.Text = ' | ' .. adminName .. ' | ' .. mapName

                local brandWidth = (brand.TextBounds and brand.TextBounds.X) or brand.Object.TextBounds.X
                local suffixWidth = (suffix.TextBounds and suffix.TextBounds.X) or suffix.Object.TextBounds.X
                local restWidth = (rest.TextBounds and rest.TextBounds.X) or rest.Object.TextBounds.X
                suffix.Position = newUDim2(0, 5 + brandWidth, 0, 2)
                rest.Position = newUDim2(0, 5 + brandWidth + suffixWidth, 0, 2)
                local totalWidth = 10 + brandWidth + suffixWidth + restWidth
                self.objects.background.Size = newUDim2(0, math.max(totalWidth, 40), 0, 17)

                local size = self.objects.background.Object.Size;
                local screensize = utility:Viewport();
                local lock = self.lock or 'Top'

                self.position = (
                    lock == 'Top Right' and newUDim2(0, screensize.X - size.X - 15, 0, 15) or
                    lock == 'Top Left' and newUDim2(0, 15, 0, 15) or
                    lock == 'Bottom Right' and newUDim2(0, screensize.X - size.X - 15, 0, screensize.Y - size.Y - 15) or
                    lock == 'Bottom Left' and newUDim2(0, 15, 0, screensize.Y - size.Y - 15) or
                    lock == 'Top' and newUDim2(0, screensize.X / 2 - size.X / 2, 0, 15) or
                    newUDim2(library.flags.watermark_x / 100, 0, library.flags.watermark_y / 100, 0)
                )

                self.objects.background.Position = self.position
            end
        end

        do
            local objs = self.watermark.objects;
            local z = self.zindexOrder.watermark;

            objs.background = utility:Draw('Square', {
                Visible = false;
                Size = newUDim2(0, 200, 0, 17);
                Position = newUDim2(0.5, -100, 0, 15);
                ThemeColor = 'Background';
                ZIndex = z;
            })

            objs.border1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 2';
                Parent = objs.background;
                ZIndex = z-1;
            })

            objs.border2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                Parent = objs.border1;
                ZIndex = z-2;
            })

            objs.topbar = utility:Draw('Square', {
                Size = newUDim2(1,0,0,1);
                ThemeColor = 'Accent';
                ZIndex = z+1;
                Parent = objs.background;
            })

            objs.brand = utility:Draw('Text', {
                Position = newUDim2(0, 5, 0, 2);
                ThemeColor = 'Accent';
                Text = 'sonata';
                Size = 13;
                Font = 2;
                ZIndex = z+1;
                Outline = true;
                Center = false;
                Parent = objs.background;
            })

            objs.suffix = utility:Draw('Text', {
                Position = newUDim2(0, 5, 0, 2);
                Text = '.ru';
                Color = fromrgb(255, 255, 255);
                Size = 13;
                Font = 2;
                ZIndex = z+1;
                Outline = true;
                Center = false;
                Parent = objs.background;
            })

            objs.text = utility:Draw('Text', {
                Position = newUDim2(0, 5, 0, 2);
                ThemeColor = 'Primary Text';
                Text = ' | admin | lobby';
                Size = 13;
                Font = 2;
                ZIndex = z+1;
                Outline = true;
                Center = false;
                Parent = objs.background;
            })

        end
    end

    local lasttick = tick();
    utility:Connection(runservice.RenderStepped, function(step)
        library.stats.fps = floor(1/step)
        if (tick()-lasttick)*1000 > library.watermark.refreshrate then
            lasttick = tick()
            pcall(function()
                library.stats.ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                library.stats.sendkbps = stats.DataSendKbps
                library.stats.receivekbps = stats.DataReceiveKbps
            end)
            library.watermark:Update()
        end
    end)

    self.keyIndicator = self.NewIndicator({title = 'Keybinds', pos = newUDim2(0,15,0,325), enabled = false});

    self.targetIndicator = self.NewIndicator({title = 'Target Info', pos = newUDim2(0,15,0,350), enabled = false});
    self.targetName = self.targetIndicator:AddValue({key = 'Name     :', value = 'nil'})
    self.targetDisplay = self.targetIndicator:AddValue({key = 'DName    :', value = 'nil'})
    self.targetHealth = self.targetIndicator:AddValue({key = 'Health   :', value = '0'})
    self.targetDistance = self.targetIndicator:AddValue({key = 'Distance :', value = '0m'})
    self.targetTool = self.targetIndicator:AddValue({key = 'Weapon   :', value = 'nil'})

    if library.themes[1] and library.themes[1].theme then
        self:SetTheme(library.themes[1].theme);
    else
        self:SetTheme(library.theme);
    end
    self:SetOpen(true);
    self.hasInit = true

end

function library:ResetAll()
    for _, opt in pairs(library.options or {}) do
        pcall(function()
            if opt.class == 'toggle' and opt.SetState then
                opt:SetState(false)
            elseif opt.class == 'slider' and opt.SetValue then
                local def = opt.default or opt.value or opt.min or 0
                opt:SetValue(def)
            elseif opt.class == 'curve' and opt.SetPreset then
                opt:SetPreset('Linear')
            elseif opt.class == 'list' and opt.Select then
                local def = opt.default or (opt.values and opt.values[1])
                if def then opt:Select(def, true) end
            end
        end)
    end
    pcall(function()
        local bridge = _G.DrawingBridge or (getgenv and getgenv().DrawingBridge)
        if bridge and bridge.syncAll then
            bridge.syncAll()
        end
    end)
    for _, win in pairs(library.windows or {}) do
        for _, tab in pairs(win.tabs or {}) do
            pcall(function()
                for _, sec in pairs(tab.sections or {}) do
                    sec:UpdateOptions()
                end
                tab:UpdateSections()
            end)
        end
    end
    library:SendNotification('reset all · turned all features off', 3)
end

function library:CreateSettingsTab(menu)
    local settingsTab = menu:AddTab('configs', 999);
    local menuSection = settingsTab:AddSection('menu', 1);
    local keybindsSection = settingsTab:AddSection('keybinds', 1);
    local watermarkSection = settingsTab:AddSection('watermark', 2);

    menuSection:AddBind({text = 'menu key', flag = 'togglebind', nomouse = true, noindicator = true, bind = Enum.KeyCode.End, callback = function()
        library:SetOpen(not library.open)
    end});

    menuSection:AddToggle({text = 'freeze movement', flag = 'disablemenumovement', callback = function(bool)
        if bool and library.open then
            actionservice:BindAction(
                'FreezeMovement',
                function()
                    return Enum.ContextActionResult.Sink
                end,
                false,
                unpack(Enum.PlayerActions:GetEnumItems())
            )
        else
            actionservice:UnbindAction('FreezeMovement');
        end
    end})

    menuSection:AddToggle({text = 'mod detector', flag = 'mod_detector', state = false})

    do
        local sizeQueued = false
        local function queueSize()
            sizeQueued = true
        end
        local baseSize = menu.objects.background.Size
        menuSection:AddList({
            text = 'dpi',
            flag = 'menu_dpi',
            values = {'75%', '90%', '100%', '110%', '125%', '150%', '175%', '200%'},
            selected = '100%',
            callback = function(value)
                if type(value) == 'table' then
                    value = value[1]
                end
                local pct = tonumber(string.match(tostring(value), '%d+'))
                if pct then
                    task.defer(function()
                        library:SetDPI(pct / 100)
                    end)
                end
            end,
        })
        menuSection:AddSlider({text = 'menu width', flag = 'menu_width', min = 280, max = 1000, increment = 1, value = baseSize.X.Offset, suffix = 'px', callback = queueSize})
        menuSection:AddSlider({text = 'menu height', flag = 'menu_height', min = 240, max = 900, increment = 1, value = baseSize.Y.Offset, suffix = 'px', callback = queueSize})
        menuSection:AddSlider({text = 'mobile button size', flag = 'mobile_size', min = 44, max = 96, increment = 1, value = 58, suffix = 'px', callback = function()
            if library.applyMenuButtonStyle then
                library.applyMenuButtonStyle()
            end
        end})
        menuSection:AddSlider({text = 'mobile button opacity', flag = 'mobile_opacity', min = 35, max = 100, increment = 1, value = 92, suffix = '%', callback = function()
            if library.applyMenuButtonStyle then
                library.applyMenuButtonStyle()
            end
        end})
        utility:Connection(runservice.RenderStepped, function()
            if sizeQueued and library.draggingSlider == nil then
                sizeQueued = false
                menu:SetSize(library.flags.menu_width, library.flags.menu_height)
            end
        end)
    end

    menuSection:AddButton({text = 'unload', confirm = true, callback = function()
        library:Unload();
    end})

    menuSection:AddButton({text = 'reset all', confirm = true, callback = function()
        library:ResetAll();
    end})

    menuSection:AddColor({
        text = 'UI accent',
        flag = 'ui_accent',
        color = library.theme.Accent or fromrgb(235, 163, 255),
        callback = function(c3)
            if typeof(c3) == 'Color3' then
                library.theme.Accent = c3
                library:UpdateThemeColors()
            end
        end,
    })

    do
        local themeNames = {}
        for _, entry in library.themes do
            table.insert(themeNames, entry.name)
        end
        menuSection:AddList({
            text = 'theme',
            flag = 'ui_theme',
            selected = library.currentTheme or 'Sonata',
            values = themeNames,
            callback = function(name)
                library:SelectTheme(name)
            end,
        })
    end

    local keyX, keyY
    local keyToggle = keybindsSection:AddToggle({text = 'indicator', flag = 'keybind_indicator', state = false, callback = function(bool)
        library.keyIndicator:SetEnabled(bool);
        if keyX then keyX.enabled = bool end
        if keyY then keyY.enabled = bool end
        keybindsSection:UpdateOptions();
        settingsTab:UpdateSections();
    end})
    keyX = keybindsSection:AddSlider({text = 'x', flag = 'keybind_indicator_x', min = 0, max = 100, increment = .1, value = .5, callback = function()
        library.keyIndicator:SetPosition(newUDim2(library.flags.keybind_indicator_x / 100, 0, library.flags.keybind_indicator_y / 100, 0));
    end});
    keyY = keybindsSection:AddSlider({text = 'y', flag = 'keybind_indicator_y', min = 0, max = 100, increment = .1, value = 35, callback = function()
        library.keyIndicator:SetPosition(newUDim2(library.flags.keybind_indicator_x / 100, 0, library.flags.keybind_indicator_y / 100, 0));
    end});
    keyX.enabled = false;
    keyY.enabled = false;
    keybindsSection:UpdateOptions();

    local wmPos, wmX, wmY
    watermarkSection:AddToggle({text = 'enabled', flag = 'watermark_enabled', state = false, callback = function(bool)
        if wmPos then wmPos.enabled = bool end
        if wmX then wmX.enabled = bool end
        if wmY then wmY.enabled = bool end
        watermarkSection:UpdateOptions();
        settingsTab:UpdateSections();
    end});
    wmPos = watermarkSection:AddList({text = 'position', flag = 'watermark_pos', selected = 'Top', values = {'Top', 'Top Left', 'Top Right', 'Bottom Left', 'Bottom Right', 'Custom'}, callback = function(val)
        library.watermark.lock = val;
    end})
    wmX = watermarkSection:AddSlider({text = 'x', flag = 'watermark_x', suffix = '%', min = 0, max = 100, increment = .1, value = 50});
    wmY = watermarkSection:AddSlider({text = 'y', flag = 'watermark_y', suffix = '%', min = 0, max = 100, increment = .1, value = 2});
    library.watermark.lock = 'Top'
    if library.flags then
        library.flags.watermark_pos = 'Top'
    end
    wmPos.enabled = false;
    wmX.enabled = false;
    wmY.enabled = false;
    watermarkSection:UpdateOptions();

    return settingsTab;
end

envTable().library = library
return library

