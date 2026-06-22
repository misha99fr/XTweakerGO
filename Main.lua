function endswith(str, suffix)
    return str:sub(-#suffix) == suffix
end

local GUI        = require("GUI")
local system     = require("System")
local filesystem = require("Filesystem")
local computer   = require("Computer")
local component  = require("component")

---------------------------------------------------------------------------------

local localization = system.getCurrentScriptLocalization()

GUI.alert(localization.betaWarning)

local workspace, window, menu = system.addWindow(GUI.tabbedWindow(1, 1, 88, 26))
local tabBarHeight = (window.tabBar and window.tabBar.height) or 3
local layout = window:addChild(GUI.layout(1, tabBarHeight + 1, window.width, window.height - tabBarHeight, 1, 1))

local userSettings = system.getUserSettings()
local transparencyOn = (userSettings.interfaceTransparencyEnabled ~= false)
local blurOn         = (userSettings.interfaceBlurEnabled ~= false)

local function applyTransparency(value)
  local us = system.getUserSettings()
  us.interfaceTransparencyEnabled = value
  system.saveUserSettings()
end

local function applyBlur(value)
  local us = system.getUserSettings()
  us.interfaceBlurEnabled = value
  system.saveUserSettings()
end

local elem1 = {}
local elem3 = {}
local elem4 = {}
local elem5 = {}

local function clearAll()
  for _, el in ipairs(elem1) do el:remove() end; elem1 = {}
  for _, el in ipairs(elem3) do el:remove() end; elem3 = {}
  for _, el in ipairs(elem4) do el:remove() end; elem4 = {}
  for _, el in ipairs(elem5) do el:remove() end; elem5 = {}
end

-- О системе
local function showSysInfo()
  clearAll()
  local totalMem  = math.floor(computer.totalMemory() / 1024)
  local freeMem   = math.floor(computer.freeMemory()  / 1024)
  local usedMem   = totalMem - freeMem
  local uptime    = math.floor(computer.uptime())
  local uptimeStr = string.format("%02d:%02d:%02d",
    math.floor(uptime/3600), math.floor((uptime%3600)/60), uptime%60)
  local energy    = math.floor(computer.energy())
  local maxEnergy = math.floor(computer.maxEnergy())
  local arch      = (computer.getArchitecture and computer.getArchitecture()) or "Lua 5.2"
  local address   = computer.address():sub(1,13) .. "..."
  local lines = {
    localization.sysArch    .. arch,
    localization.sysAddr    .. address,
    localization.sysMemUsed .. usedMem .. " KB / " .. totalMem .. " KB",
    localization.sysMemFree .. freeMem .. " KB",
    localization.sysUptime  .. uptimeStr,
    localization.sysEnergy  .. energy .. " / " .. maxEnergy .. " EU",
  }
  for _, line in ipairs(lines) do
    local tx = layout:addChild(GUI.text(1, 1, 0x2D2D2D, line))
    table.insert(elem1, tx)
  end
  local components = {}
  if component then
    for addr, ctype in component.list() do
      table.insert(components, ctype)
    end
  end
  if #components > 0 then
    local sep = layout:addChild(GUI.text(1, 1, 0x888888, localization.sysComponents))
    table.insert(elem1, sep)
    local shown = {}
    for i = 1, math.min(#components, 8) do table.insert(shown, components[i]) end
    local cl = layout:addChild(GUI.text(1, 1, 0x555555, table.concat(shown, ", ")))
    table.insert(elem1, cl)
  end
  workspace:draw()
end

-- Производительность
local function showPerf()
  clearAll()
  local titleUI = layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.uiTweaks))
  table.insert(elem3, titleUI)
  local trLabel = layout:addChild(GUI.text(1, 1, 0x4B4B4B, localization.transparency))
  table.insert(elem3, trLabel)
  local trSwitch = layout:addChild(GUI.switch(1, 1, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, transparencyOn))
  table.insert(elem3, trSwitch)
  trSwitch.onStateChanged = function()
    transparencyOn = not transparencyOn
    applyTransparency(transparencyOn)
    workspace:draw()
  end
  local blLabel = layout:addChild(GUI.text(1, 1, 0x4B4B4B, localization.blur))
  table.insert(elem3, blLabel)
  local blSwitch = layout:addChild(GUI.switch(1, 1, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, blurOn))
  table.insert(elem3, blSwitch)
  blSwitch.onStateChanged = function()
    blurOn = not blurOn
    applyBlur(blurOn)
    workspace:draw()
  end
  local hint = layout:addChild(GUI.text(1, 1, 0x888888, localization.uiHint))
  table.insert(elem3, hint)
  workspace:draw()
end

-- Система (имя пользователя, CPU, EEPROM)
local function showSystem()
  clearAll()

  -- == Имя пользователя ==
  table.insert(elem5, layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.usernameSection)))

  local currentUsername = (system.getUser and system.getUser()) or "user"

  local unLabel = layout:addChild(GUI.text(1, 1, 0x4B4B4B, localization.currentUsername .. currentUsername))
  table.insert(elem5, unLabel)

  local unBtn = layout:addChild(GUI.roundedButton(2,2,28,3,0xFFFFFF,0x3C3C3C,0x0055FF,0xFFFFFF, localization.changeUsername))
  table.insert(elem5, unBtn)
  unBtn.onTouch = function()
    local winW, winH = 46, 10
    local winX = math.floor((workspace.width  - winW) / 2)
    local winY = math.floor((workspace.height - winH) / 2)
    local _, inputW = system.addWindow(GUI.titledWindow(winX, winY, winW, winH, localization.changeUsername))
    local inputL = inputW:addChild(GUI.layout(1,1,inputW.width,inputW.height,1,1))
    inputL:addChild(GUI.text(1,1,0x4B4B4B, localization.enterUsername))
    local inp = inputL:addChild(GUI.input(2,2,30,3,0xEEEEEE,0x888888,0x888888,0xFFFFFF,0x0055FF, currentUsername, localization.enterUsername))
    local confirmBtn = inputL:addChild(GUI.roundedButton(2,2,16,3,0xFFFFFF,0x0055FF,0x003399,0xFFFFFF, localization.confirm))
    confirmBtn.onTouch = function()
      local newName = inp.text
      if newName and #newName > 0 and newName ~= currentUsername then
        local usersDir = "/MineOS/Users/"
        local oldFolder = nil
        for _, f in ipairs(filesystem.list(usersDir) or {}) do
          local name = f:gsub("/$", "")
          if name == currentUsername then oldFolder = f; break end
        end
        if not oldFolder then
          GUI.alert(localization.usernameChangeFail .. "БЛЯТЬ! СОРЯН БРО, НО ЭТА ФУНКЦИЯ ПОКА-ЧТО СЛОМАНА!")
          return
        end
        local oldPath = usersDir .. oldFolder
        local newPath = usersDir .. newName .. "/"
        if filesystem.exists(newPath) then
          GUI.alert(localization.usernameTaken)
          return
        end
        local ok, reason = filesystem.rename(oldPath, newPath)
        if ok then
          currentUsername = newName
          unLabel.text = localization.currentUsername .. currentUsername
          inputW:remove()
          GUI.alert(localization.usernameChanged)
        else
          GUI.alert(localization.usernameChangeFail .. tostring(reason))
        end
        workspace:draw()
      end
    end
    workspace:draw()
  end

  table.insert(elem5, layout:addChild(GUI.text(1,1,0x888888, localization.separator)))

  -- == CPU ==
  table.insert(elem5, layout:addChild(GUI.text(1,1,0x2D2D2D, localization.cpuSection)))
  if computer.getArchitecture then
    local function nextArch(cur)
      if cur == "Lua 5.2" then return "Lua 5.3"
      elseif cur == "Lua 5.3" then return "Lua 5.4"
      else return "Lua 5.3" end
    end

    local currentArch = computer.getArchitecture() or "?"
    local archLabel = layout:addChild(GUI.text(1,1,0x4B4B4B, localization.currentArch .. currentArch))
    table.insert(elem5, archLabel)
    local archBtn = layout:addChild(GUI.roundedButton(2,2,36,3,0xFFFFFF,0x3C3C3C,0x7700AA,0xFFFFFF, localization.switchArch .. nextArch(currentArch)))
    table.insert(elem5, archBtn)
    archBtn.onTouch = function()
      if computer.setArchitecture then
        local cur = computer.getArchitecture()
        local nxt = nextArch(cur)
        local ok, err = pcall(function() computer.setArchitecture(nxt) end)
        if ok then
          archLabel.text = localization.currentArch .. nxt
          archBtn.text = localization.switchArch .. nextArch(nxt)
          workspace:draw()
          GUI.alert(localization.archChanged .. nxt .. localization.archReboot)
        else
          GUI.alert(localization.archFail .. tostring(err))
        end
      else
        GUI.alert(localization.archNotSupported)
      end
    end
  else
    table.insert(elem5, layout:addChild(GUI.text(1,1,0x888888, localization.noCpuFound)))
  end

  table.insert(elem5, layout:addChild(GUI.text(1,1,0x888888, localization.separator)))

  -- == EEPROM ==
  table.insert(elem5, layout:addChild(GUI.text(1,1,0x2D2D2D, localization.eepromSection)))
  local eepromAddr = component and component.list("eeprom")()
  if eepromAddr then
    local eeprom = component.proxy(eepromAddr)

    -- Readonly
    local roLabel = layout:addChild(GUI.text(1,1,0x4B4B4B, localization.eepromReadonly))
    table.insert(elem5, roLabel)
    local isRO = eeprom.isReadonly and eeprom.isReadonly() or false
    local roSwitch = layout:addChild(GUI.switch(1,1,8,0xFF4444,0x1D1D1D,0xEEEEEE, isRO))
    table.insert(elem5, roSwitch)
    roSwitch.onStateChanged = function()
      if isRO then
        GUI.alert(localization.eepromAlreadyRO)
        roSwitch.state = true; workspace:draw(); return
      end
      if eeprom.makeReadonly and eeprom.getChecksum then
        local ok, err = pcall(function()
          eeprom.makeReadonly(eeprom.getChecksum())
        end)
        if ok then
          isRO = true
          roLabel.text = localization.eepromReadonly .. " [!]"
          roSwitch.state = true; workspace:draw()
          GUI.alert(localization.eepromNowReadonly)
        else
          roSwitch.state = false; workspace:draw()
          GUI.alert(localization.eepromROFail .. tostring(err))
        end
      else
        roSwitch.state = false; workspace:draw()
        GUI.alert(localization.eepromRONotSupported)
      end
    end

    -- Кнопка прошивки Panic Screen
    local flashBtn = layout:addChild(GUI.roundedButton(2,2,40,3,0xFFFFFF,0x880000,0xFF2222,0xFFFFFF, localization.flashEEPROM))
    table.insert(elem5, flashBtn)
    table.insert(elem5, layout:addChild(GUI.text(1,1,0x888888, localization.flashEEPROMHint)))

    flashBtn.onTouch = function()
      if isRO then
        GUI.alert(localization.eepromFlashROBlocked)
        return
      end
      GUI.alert(localization.flashWarning)

      -- MineOS Kernel Panic Firmware
      -- Прошивка рендерит экран паники как macOS kernel panic, но под OpenComputers/MineOS
      local panicFW = 'local c=component or require("component")\n'
        .. 'local g=c.proxy(c.list("gpu")())\n'
        .. 'local s=c.list("screen")()\n'
        .. 'if not g or not s then while true do computer.pullSignal(1) end end\n'
        .. 'g.bind(s)\n'
        .. 'local W,H=g.maxResolution()\n'
        .. 'g.setResolution(W,H)\n'
        .. 'g.setBackground(0x1D1D1D)\n'
        .. 'g.fill(1,1,W,H," ")\n'
        .. 'local iW=9\n'
        .. 'local ix=math.floor((W-iW)/2)+1\n'
        .. 'local iy=math.floor(H/2)-9\n'
        .. 'local icon={"   ~~~   ","  ~   ~  "," ~ (O) ~ "," ~     ~ ","  ~   ~  ","   ~~~   "}\n'
        .. 'g.setForeground(0x444444)\n'
        .. 'for i,r in ipairs(icon) do g.set(ix,iy+i-1,r) end\n'
        .. 'g.setForeground(0xFFFFFF)\n'
        .. 'local t1="You need to restart your computer."\n'
        .. 'g.set(math.floor((W-#t1)/2)+1,iy+7,t1)\n'
        .. 'g.setForeground(0x555555)\n'
        .. 'local sep=("--"):rep(math.floor(math.min(56,W-4)/2))\n'
        .. 'g.set(math.floor((W-#sep)/2)+1,iy+8,sep)\n'
        .. 'local lines={"Hold down the Power button for several seconds","or press the Restart button.","","If the problem persists, consult your server","administrator or check MineOS logs:","  /MineOS/Logs/","","Kernel panic -- not syncing."}\n'
        .. 'g.setForeground(0x888888)\n'
        .. 'for i,l in ipairs(lines) do g.set(math.floor((W-#l)/2)+1,iy+9+i,l) end\n'
        .. 'g.setForeground(0x333333)\n'
        .. 'g.set(2,H,"XTweaker GO  |  Panic Screen Firmware")\n'
        .. 'while true do\n'
        .. '  local e={computer.pullSignal(0.5)}\n'
        .. '  if e[1]=="key_down" then computer.shutdown(true) end\n'
        .. 'end\n'

      local container = GUI.addBackgroundContainer(workspace,true,true, localization.flashingEEPROM)
      local prg = container.layout:addChild(GUI.progressIndicator(1,1,0x3C3C3C,0x00B640,0x99FF80))
      prg.active=true; workspace:draw()

      if not filesystem.exists("/tweakerplusbackups/") then
        filesystem.makeDirectory("/tweakerplusbackups/")
      end
      local rnd = tostring(computer.freeMemory())..tostring(computer.uptime())
      local backDir = "/tweakerplusbackups/back"..rnd.."/"
      filesystem.makeDirectory(backDir)
      local curFW = eeprom.get()
      if curFW then filesystem.write(backDir.."eeprom_backup.lua", curFW) end
      prg:roll(); workspace:draw()

      local ok, err = pcall(function()
        eeprom.set(panicFW)
        if eeprom.setLabel then eeprom.setLabel("MineOS Panic FW") end
      end)
      prg:roll(); workspace:draw()
      container:remove()

      if ok then GUI.alert(localization.flashDone)
      else GUI.alert(localization.flashFail .. tostring(err)) end
    end
  else
    table.insert(elem5, layout:addChild(GUI.text(1,1,0x888888, localization.noEEPROMFound)))
  end

  workspace:draw()
end

-- О программе
local function showAbout()
  clearAll()
  local tx  = layout:addChild(GUI.text(1, 1, 0x4B4B4B, localization.about))
  local tx2 = layout:addChild(GUI.text(1, 1, 0x4B4B4B, localization.ver))
  table.insert(elem4, tx)
  table.insert(elem4, tx2)
  workspace:draw()
end

-- Вкладки
window.tabBar:addItem(localization.sysInfoTab).onTouch  = function() showSysInfo() end
window.tabBar:addItem(localization.performance).onTouch = function() showPerf() end
window.tabBar:addItem(localization.systemTab).onTouch   = function() showSystem() end
window.tabBar:addItem(localization.name).onTouch        = function() showAbout() end

-- Меню Восстановить
local contextMenu = menu:addContextMenuItem(localization.restore)
contextMenu:addItem(localization.fromback).onTouch = function()
  local dpt = filesystem.exists("/tweakerplusbackups/") and "/tweakerplusbackups/" or "/"
  local dlg = GUI.addFilesystemDialog(workspace, false, 50, math.floor(workspace.height*0.8), "Open","Cancel","Backup", dpt)
  dlg:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_DIRECTORY)
  dlg.onSubmit = function(path)
    local files = filesystem.list(path) or {}
    local isbk = false
    for _, f in ipairs(files) do
      if f=="eeprom_backup.lua" then isbk=true end
    end
    if path=="/Applications/" or not isbk then GUI.alert(localization.notbk); return end

    local container = GUI.addBackgroundContainer(workspace,true,true,localization.restprg)
    local prg = container.layout:addChild(GUI.progressIndicator(1,1,0x3C3C3C,0x00B640,0x99FF80))
    prg.active=true; workspace:draw()

    local eepromBkPath = path.."eeprom_backup.lua"
    if filesystem.exists(eepromBkPath) then
      local ea = component and component.list("eeprom")()
      if ea then
        local ep = component.proxy(ea)
        local fw = filesystem.read(eepromBkPath)
        if fw then
          local ok2, err2 = pcall(function() ep.set(fw) end)
          if ok2 then
            GUI.alert(localization.eepromRestored)
          else
            GUI.alert(localization.eepromROFail .. tostring(err2))
          end
        end
      end
    end
    prg:roll(); workspace:draw()

    container:remove()
  end
  dlg:show()
end

contextMenu:addSeparator()
contextMenu:addItem(localization.deleteback).onTouch = function()
  local container = GUI.addBackgroundContainer(workspace,true,true,localization.delbackprg)
  workspace:draw()
  if filesystem.exists("/tweakerplusbackups/") then
    local ok, reason = filesystem.remove("/tweakerplusbackups/")
    if not ok then
      GUI.alert(localization.couldntDelBK.."\n"..reason)
      container:remove(); return
    end
  end
  container:remove()
  GUI.alert(localization.delBK)
end

-- Ресайз
window.onResize = function(w, h)
  window.backgroundPanel.width  = w
  window.backgroundPanel.height = h
  layout.width  = w
  layout.height = h - tabBarHeight
end

showSysInfo()
workspace:draw()
