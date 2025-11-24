-- EthnoProf — оффлайн просмотр Этнографии (Sirus 3.3.5)
-- Если ты это читаешь, то тебе наверное интересно что здесь происходит, в защиту себя
-- скажу: это мой первый аддон для вов и мне было очень интересно себя в этом попробовать,
-- если есть какие-то пожелания, варианты улучшения аддона или ты можешь мне рассказать как их делать правильно, 
-- напиши мне пожалуйста в игре
-- ник: Минпромторг (Neverest x3) 

EthnoProfDB = EthnoProfDB or {}

local function Ethno_GetCharKey()
  local name = UnitName and UnitName("player") or "Unknown"
  local realm
  if GetRealmName then
    realm = GetRealmName()
  elseif GetCVar then
    realm = GetCVar("realmName")
  end
  if not name or name == "" then name = "Unknown" end
  if not realm or realm == "" then realm = "Unknown" end
  return name .. " - " .. realm
end

local function Ethno_GetCharDB()
  local key = Ethno_GetCharKey()
  if not EthnoProfDB[key] then
    EthnoProfDB[key] = { recipes = {}, order = {}, profLink = nil }
  end
  return EthnoProfDB[key]
end

DEBUG_FILL_LIST = false   -- проверка работоспособности скролла левого окна

LEFT_BG_TEXTURE  = "Interface\\FrameGeneral\\UI-Background-Marble"
LEFT_BG_TILE     = false

RIGHT_BG_TEXTURE = "Interface\\TradeSkillFrame\\Tradeskills"
RIGHT_BG_TILE    = true

LEFT_BG_PAD, RIGHT_BG_PAD = 4, 0

-- Настройки скролл баров

SCROLLBAR_BACKDROP = {
  bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile     = true,
  tileSize = 16,
  edgeSize = 16,
  insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

LEFT_SCROLL_TILE_DEFAULT  = true
RIGHT_SCROLL_TILE_DEFAULT = true

-- ЛЕВЫЙ скроллбар
LEFT_SCROLLBAR_WIDTH             = 24   -- ширина фона скроллбара
LEFT_SCROLLBAR_BAR_HEIGHT_EXTRA  = 0    -- добавка к высоте САМОГО скроллбара
LEFT_SCROLLBAR_BG_HEIGHT_EXTRA   = 40   -- добавка к высоте ФОНА скроллбара
LEFT_SCROLLBAR_OFFSET_X          = 0    -- сдвиг фона по X
LEFT_SCROLLBAR_OFFSET_Y          = 0    -- сдвиг фона по Y

-- ПРАВЫЙ скроллбар
RIGHT_SCROLLBAR_WIDTH             = 24
RIGHT_SCROLLBAR_BAR_HEIGHT_EXTRA  = 40
RIGHT_SCROLLBAR_BG_HEIGHT_EXTRA   = 40
RIGHT_SCROLLBAR_OFFSET_X          = 0
RIGHT_SCROLLBAR_OFFSET_Y          = 0

-- Ширина поля поиска (EditBox вверху)
SEARCH_BOX_WIDTH = 200


-- Разметка и константы

FRAME_W, FRAME_H = 670, 496

-- Ширина полосы между левым и правым окнами
PANE_SEPARATOR_WIDTH = 2

-- Левая колонка
LEFT_W, LEFT_H = 320, 405
ROW_H = 16
LIST_TOP_PAD    = 8
LIST_BOTTOM_PAD = 8
VISIBLE_ROWS = math.floor((LEFT_H - LIST_TOP_PAD - LIST_BOTTOM_PAD) / ROW_H)

-- Серый текст списка
LIST_TEXT_GREY_R = 0.5
LIST_TEXT_GREY_G = 0.5
LIST_TEXT_GREY_B = 0.5

-- Размер иконки плюса и минуса у категорий
HEADER_ICON_SIZE = 14

-- Правая колонка
RECIPE_ICON_SIZE = 47
DESC_SIDE_PAD    = 12
DESC_TOP_GAP     = 8
DESC_PAD         = 1

-- Дополнительные строки после описания и перед реагентами

DESC_EXTRA_BLANK_LINES = 0

-- Сетка реагентов (размер фрейма)
REAG_ROW_H   = 41
REAG_ROW_VSP = 4
REAG_WIDTH   = 150

-- Размер фрейма в котором располагается текст названия реагента
REAG_NAME_FRAME_WIDTH  = 145
REAG_NAME_FRAME_HEIGHT = REAG_ROW_H

-- Расстояние между колонками реагентов
REAG_COL_SPACING = 6
REAG_COL_W       = 146

REAG_TOP_GAP = 6

-- Пустое пространство после сетки
REAG_BOTTOM_PAD_EXTRA = 0

-- Размер фона реагента
REAG_SLOT_WIDTH  = 125
REAG_SLOT_HEIGHT = 66

-- Элементы внутри ячейки реагента
REAG_ICON_SIZE = 40
REAG_COUNT_FONT_DELTA = 2
NAME_MIN_PAD_X = 8
NAME_RIGHT_PAD = 6

-- Фон ячейки реагента
REAG_SLOT_TEXTURE   = "Interface\\QuestFrame\\UI-QuestItemNameFrame"
REAG_SLOT_TEXCOORDS = {0, 1, 0, 1}

REAG_SLOT_TILE_H = false
REAG_SLOT_TILE_V = false

REAG_SLOT_ANCHOR     = "RIGHT"
REAG_SLOT_REL_POINT  = "RIGHT"
REAG_SLOT_OFFSET_X   = 10
REAG_SLOT_OFFSET_Y   = 0

REAG_SLOT_COLOR_R = 1.0
REAG_SLOT_COLOR_G = 1.0
REAG_SLOT_COLOR_B = 1.0
REAG_SLOT_COLOR_A = 1.0

REAG_TEXT_GREY_R = 0.45
REAG_TEXT_GREY_G = 0.45
REAG_TEXT_GREY_B = 0.45

-- Позиция иконки Этнографии в книге заклинаний
SPELLBOOK_BUTTON_OFFSET_X = -46
SPELLBOOK_BUTTON_OFFSET_Y = 0


local wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end end

local function IsEthnoLine(name)
  if not name then return false end
  if name == "Этнография" then return true end
  name = string.lower(name)
  return string.find(name, "этнограф") or string.find(name, "ethnograph")
end

local function SpellFromLink(link)
  if not link then return nil end
  local id = string.match(link, "Hspell:(%d+)") or string.match(link, "Henchant:(%d+)")
  if id then return tonumber(id) end
  return nil
end

local function ItemFromLink(link)
  if not link then return nil end
  local id = string.match(link, "Hitem:(%d+)")
  if id then return tonumber(id) end
  return nil
end

local function ItemIDFromAny(x)
  if type(x) == "number" then return x end
  if type(x) == "string" then
    local id = string.match(x, "item:(%d+)")
    if id then return tonumber(id) end
  end
  return nil
end

local function AddToDB(e)
  if not e or not e.spellID then return end
  local db = Ethno_GetCharDB()
  db.recipes[e.spellID] = e
  for _, id in ipairs(db.order) do
    if id == e.spellID then return end
  end
  table.insert(db.order, e.spellID)
end

local function ResetDB()
  local key = Ethno_GetCharKey()
  EthnoProfDB[key] = { recipes = {}, order = {}, profLink = nil }
end

local function BuildRecipeChatLink(e)
  if not e then return nil end
  if e.spellID and GetSpellLink then
    local l = GetSpellLink(e.spellID)
    if l then return l end
  end
  if e.spellID then
    return string.format("|cffffd000|Henchant:%d|h[%s]|h|r", e.spellID, e.name or "Enchant")
  end
  return e.productLink
end

local function BumpFont(fs, dx)
  if not fs then return end
  local f, sz, fl = fs:GetFont()
  if f and sz then fs:SetFont(f, sz + (dx or 1), fl) end
end

local function TrimDescTrailingNewlines(desc)
  if not desc or desc == "" then return desc end
  return desc:gsub("\n+$", "")
end


-- Ветка талантов + спек

local TalentNameToTree      = {}
local TalentNameToTreeLower = {}

local CurrentSpecName = nil -- активный спек (ветка с наибольшим числом очков)

local function NormalizeTalentName(name)
  if not name or name == "" then return nil end

  name = name:gsub("|c%x%x%x%x%x%x%x%x", "")
  name = name:gsub("|r", "")

  name = name:gsub("|n", " ")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")

  local quoted = name:match("«([^»]+)»") or name:match("\"([^\"]+)\"")
  if quoted and quoted ~= "" then
    name = quoted
  end

  local beforeDot = name:match("([^%.]+)")
  if beforeDot and beforeDot ~= "" then
    name = beforeDot
  end

  name = name:gsub("%s*%([^%)]*%)%s*$", "")

  name = name:gsub('^["«]', ""):gsub('["»]$', "")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")

  if name == "" then return nil end
  return name
end

local function BuildTalentNameToTree()
  wipe(TalentNameToTree)
  wipe(TalentNameToTreeLower)

  if not GetNumTalentTabs or not GetTalentTabInfo or not GetTalentInfo then
    return
  end

  local ok, numTabs = pcall(GetNumTalentTabs, false, false)
  if not ok or not numTabs or numTabs <= 0 then return end

  for tab = 1, numTabs do
    local tabName = GetTalentTabInfo(tab, false, false)
    if tabName and tabName ~= "" then
      local numTalents = GetNumTalents(tab, false, false)
      for i = 1, numTalents do
        local talentName = GetTalentInfo(tab, i, false, false)
        if talentName and talentName ~= "" then
          local norm = NormalizeTalentName(talentName) or talentName
          TalentNameToTree[norm]                     = tabName
          TalentNameToTreeLower[string.lower(norm)]  = tabName
        end
      end
    end
  end
end

local function UpdateCurrentSpecName()
  CurrentSpecName = nil
  if not GetNumTalentTabs or not GetTalentTabInfo then return end

  local ok, numTabs = pcall(GetNumTalentTabs, false, false)
  if not ok or not numTabs or numTabs <= 0 then return end

  local activeGroup = 1
  if GetActiveTalentGroup then
    local ok2, group = pcall(GetActiveTalentGroup)
    if ok2 and type(group) == "number" and group >= 1 then
      activeGroup = group
    end
  end

  local bestPoints, bestName = -1, nil
  for tab = 1, numTabs do
    local tabName, _, pointsSpent = GetTalentTabInfo(tab, false, false, activeGroup)
    if not tabName then
      tabName, _, pointsSpent = GetTalentTabInfo(tab, false, false)
    end
    pointsSpent = pointsSpent or 0
    if pointsSpent > bestPoints then
      bestPoints = pointsSpent
      bestName   = tabName
    end
  end

  if bestName and bestName ~= "" then
    CurrentSpecName = bestName
  end
end

local function GetTalentTreeByTalentName(talentName)
  if not talentName or talentName == "" then return nil end

  local norm  = NormalizeTalentName(talentName) or talentName
  local tree  = TalentNameToTree[norm]
  if tree then return tree end

  local lower = string.lower(norm)
  tree = TalentNameToTreeLower[lower]
  if tree then return tree end

  for k, v in pairs(TalentNameToTreeLower) do
    if k == lower or k:find(lower, 1, true) or lower:find(k, 1, true) then
      return v
    end
  end

  return nil
end


local scheduler = CreateFrame("Frame")
scheduler.queue = {}
scheduler:SetScript("OnUpdate", function(self, elapsed)
  if #self.queue == 0 then return end
  for i = #self.queue, 1, -1 do
    local t = self.queue[i]
    t.d = t.d - elapsed
    if t.d <= 0 then
      local f = t.f
      table.remove(self.queue, i)
      pcall(f)
    end
  end
end)
local function After(delay, func)
  table.insert(scheduler.queue, { d = delay or 0, f = func })
end

-- Формат времени

local function fmtShort(sec)
  if sec <= 0 then return "готово" end
  if sec < 60 then return tostring(math.floor(sec)) .. "с" end
  if sec < 3600 then
    local m = math.floor(sec / 60 + 0.5)
    return tostring(m) .. "м"
  end
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60 + 0.5)
  if m > 0 then return string.format("%dч %dм", h, m) end
  return string.format("%dч", h)
end

local function fmtLong(sec)
  if sec <= 0 then return "Готово" end
  local h = math.floor(sec / 3600)
  sec = sec % 3600
  local m = math.floor(sec / 60)
  sec = sec % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, sec) end
  return string.format("%d:%02d", m, sec)
end

local function BuildCooldownText(e)
  if not e then return nil end
  local base = e.baseCD or 0
  local remaining = 0

  if e.spellID and GetSpellCooldown then
    local start, duration, enabled = GetSpellCooldown(e.spellID)
    if enabled == 1 and duration and duration > 1.5 then
      remaining = (start or 0) + duration - GetTime()
      if remaining < 0 then remaining = 0 end
    end
  end

  if remaining > 0 then
    local text = "|TInterface\\TimeManager\\PauseButton:0|t Перезарядка: " .. fmtLong(remaining)
    if base and base > 0 then
      text = text .. " (" .. fmtShort(base) .. ")"
    end
    return text, 1, 0.5, 0.2
  elseif base and base > 0 then
    local text = "Перезарядка: " .. fmtShort(base)
    return text, 0.8, 0.8, 0.8
  end
  return nil
end


-- Тултип

local scanTip = CreateFrame("GameTooltip", "EthnoScanTooltip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")
local function TL(i) return _G["EthnoScanTooltipTextLeft" .. i] end

local function TooltipLeftLines(link, maxLines)
  scanTip:ClearLines()
  if not link or link == "" then return {} end
  scanTip:SetHyperlink(link)
  local t, n = {}, maxLines or 80
  for i = 1, n do
    local fs = TL(i)
    local s = fs and fs:GetText()
    if s and s ~= "" then t[#t + 1] = s end
  end
  return t
end

local function ExtractCooldownFromString(s)
  if not s or s == "" then return nil end

  local h, m = string.match(s, "Восстановление[:%s]*(%d+)%s*ч%.?%s*(%d*)")
  if h then
    return (tonumber(h) or 0) * 3600 + (tonumber(m) or 0) * 60
  end
  local mm = string.match(s, "Восстановление[:%s]*(%d+)%s*мин")
  if mm then return tonumber(mm) * 60 end
  local ss = string.match(s, "Восстановление[:%s]*(%d+)%s*сек")
  if ss then return tonumber(ss) end

  local h2, m2 = string.match(s, "Перезарядка[:%s]*(%d+)%s*ч%.?%s*(%d*)")
  if h2 then
    return (tonumber(h2) or 0) * 3600 + (tonumber(m2) or 0) * 60
  end
  local mm2 = string.match(s, "Перезарядка[:%s]*(%d+)%s*мин")
  if mm2 then return tonumber(mm2) * 60 end
  local ss2 = string.match(s, "Перезарядка[:%s]*(%d+)%s*сек")
  if ss2 then return tonumber(ss2) end

  local hh, mm3 = string.match(s, "Cooldown[:%s]*(%d+)%s*hr[s]?%s*(%d*)")
  if hh then
    return (tonumber(hh) or 0) * 3600 + (tonumber(mm3) or 0) * 60
  end
  local mm4 = string.match(s, "Cooldown[:%s]*(%d+)%s*min")
  if mm4 then return tonumber(mm4) * 60 end
  local ss3 = string.match(s, "Cooldown[:%s]*(%d+)%s*s")
  if ss3 then return tonumber(ss3) end

  return nil
end

local function ParseBaseCooldownFromTooltip(recipeLink)
  local lines = TooltipLeftLines(recipeLink, 60)
  for _, s in ipairs(lines) do
    local sec = ExtractCooldownFromString(s)
    if sec and sec > 0 then
      return sec
    end
  end
  return nil
end

-- Парсинг таланта из тултипа

local function StripColorCodes(s)
  if not s then return "" end
  s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
  s = s:gsub("|r", "")
  return s
end

local function ExtractTalentNameFromText(raw)
  if not raw or raw == "" then return nil end

  local s = StripColorCodes(raw)
  s = s:gsub("|n", " ")
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")

  local basePhraseRu = "Требуется талант"
  local basePhraseEn = "Requires Talent"

  local pos = s:find(basePhraseRu, 1, true)
  local phrase = basePhraseRu
  if not pos then
    pos = s:find(basePhraseEn, 1, true)
    phrase = basePhraseEn
  end
  if not pos then
    return nil
  end

  local startIdx = pos + #phrase
  local rest = s:sub(startIdx + 1)
  rest = rest:gsub("^[:%s]+", "")
  rest = rest:gsub("%s*%([^%)]*%)%s*$", "")
  rest = rest:gsub("%.$", "")
  rest = rest:gsub("^%s+", ""):gsub("%s+$", "")

  if rest == "" then return nil end
  return rest
end

local function ParseTalentRequirementFromTooltip(link)
  if not link or link == "" then return nil end
  local lines = TooltipLeftLines(link, 80)
  if not lines or #lines == 0 then return nil end

  for i = 1, #lines do
    local line = lines[i]
    if line and line ~= "" then
      local talent = ExtractTalentNameFromText(line)
      if talent then return talent end
    end

    if i < #lines then
      local combined = (lines[i] or "") .. " " .. (lines[i + 1] or "")
      local talent = ExtractTalentNameFromText(combined)
      if talent then return talent end
    end
  end

  return nil
end

local function ParseTalentRequirementFromDesc(desc)
  if not desc or desc == "" then return nil end

  local text = StripColorCodes(desc)
  text = text:gsub("|n", "\n")

  local prev = nil
  for line in text:gmatch("[^\n]+") do
    local talent = ExtractTalentNameFromText(line)
    if talent then return talent end

    if prev then
      local combined = prev .. " " .. line
      talent = ExtractTalentNameFromText(combined)
      if talent then return talent end
    end
    prev = line
  end

  return nil
end

-- Парсинг реагентов из тултипа

local function ParseReagentsFromTooltip(recipeLink)
  local lines = TooltipLeftLines(recipeLink, 80)
  local reag = {}
  local inBlock = false
  for _, s in ipairs(lines) do
    if string.find(s, "^Реагенты:") or string.find(s, "^Reagents:") then
      inBlock = true
    elseif inBlock then
      if string.find(s, ":$") then break end
      local name, cnt = string.match(s, "^(.+)%s+%((%d+)%)$")
      if not name then name, cnt = string.match(s, "^(.+)%s+[x×](%d+)$") end
      if name then
        cnt = tonumber(cnt) or 1
        local itemName, itemLink, _, _, _, _, _, _, _, tex = GetItemInfo(name)
        table.insert(reag, {
          name = itemName or name,
          itemLink = itemLink,
          itemID = itemLink and tonumber(string.match(itemLink, "item:(%d+)")) or nil,
          texture = tex or "Interface\\Icons\\INV_Misc_QuestionMark"
        })
      end
    end
  end
  if #reag > 0 then return reag end
  return nil
end

-- Построение текста описания с пустыми строками перед реагентами

local function BuildDescText(desc)
  local n = DESC_EXTRA_BLANK_LINES or 0
  if n < 0 then n = 0 end

  local s = desc or ""
  s = s:gsub("[\r\n]+$", "") 

  s = s .. "\n"              -- одна обязательная пустая строка

  for _ = 1, n do            
    s = s .. "\n"
  end

  return s
end


-- Скан профессий + сохранение линка профессии

local function ScanTradeSkill()
  local line = GetTradeSkillLine()
  if not IsEthnoLine(line) then return false end

  local db = Ethno_GetCharDB()
  if GetTradeSkillListLink then
    local ok, link = pcall(GetTradeSkillListLink)
    if ok and link and link ~= "" then
      db.profLink = link
    end
  end

  local n = GetNumTradeSkills() or 0
  for i = 1, n do
    local name, typ, _, skill = GetTradeSkillInfo(i)
    if typ ~= "header" then
      local reag = {}
      local rn = GetTradeSkillNumReagents(i) or 0
      for r = 1, rn do
        local rName, rTex, rCnt = GetTradeSkillReagentInfo(i, r)
        local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, r) or nil
        reag[#reag + 1] = {
          name   = rName or ("Компонент " .. r),
          texture = rTex,
          count  = rCnt or 1,
          itemLink = rLink,
          itemID = ItemFromLink(rLink)
        }
      end

      local spellLink   = GetTradeSkillRecipeLink(i)
      local productLink = (GetTradeSkillItemLink and GetTradeSkillItemLink(i)) or nil
      local spellID     = SpellFromLink(spellLink)
      local descLive    = (GetTradeSkillDescription and GetTradeSkillDescription(i)) or ""

      descLive = TrimDescTrailingNewlines(descLive)

      local baseCD    = ParseBaseCooldownFromTooltip(spellLink or productLink)
      local talentReq = ParseTalentRequirementFromDesc(descLive)
                     or ParseTalentRequirementFromTooltip(spellLink)
                     or ParseTalentRequirementFromTooltip(productLink)

      local talentTree = GetTalentTreeByTalentName(talentReq)

      AddToDB({
        spellID = spellID,
        name    = name or ("Запись " .. i),
        type    = typ or "trivial",
        skill   = skill or 0,
        icon    = (GetTradeSkillIcon and GetTradeSkillIcon(i)) or "Interface\\Icons\\INV_Misc_QuestionMark",
        reagents = reag,
        desc    = descLive,
        productLink = productLink,
        baseCD  = baseCD,
        talentReq  = talentReq,
        talentTree = talentTree,
      })
    end
  end
  return true
end

local function ScanCraft()
  local line = (GetCraftDisplaySkillLine and GetCraftDisplaySkillLine()) or (GetCraftName and GetCraftName())
  if not IsEthnoLine(line) then return false end

  local n = GetNumCrafts() or 0
  for i = 1, n do
    local name, typ, skill = GetCraftInfo(i)
    if typ ~= "header" then
      local reag = {}
      local rn = GetCraftNumReagents(i) or 0
      for r = 1, rn do
        local rName, rTex, rCnt = GetCraftReagentInfo(i, r)
        local rLink = GetCraftReagentItemLink and GetCraftReagentItemLink(i, r) or nil
        reag[#reag + 1] = {
          name   = rName or ("Компонент " .. r),
          texture = rTex,
          count  = rCnt or 1,
          itemLink = rLink,
          itemID = ItemFromLink(rLink)
        }
      end

      local spellLink   = GetCraftRecipeLink(i)
      local productLink = (GetCraftItemLink and GetCraftItemLink(i)) or nil
      local spellID     = SpellFromLink(spellLink)
      local descLive    = (GetCraftDescription and GetCraftDescription(i)) or ""

      descLive = TrimDescTrailingNewlines(descLive)

      local baseCD    = ParseBaseCooldownFromTooltip(spellLink or productLink)
      local talentReq = ParseTalentRequirementFromDesc(descLive)
                     or ParseTalentRequirementFromTooltip(spellLink)
                     or ParseTalentRequirementFromTooltip(productLink)

      local talentTree = GetTalentTreeByTalentName(talentReq)

      AddToDB({
        spellID = spellID,
        name    = name or ("Запись " .. i),
        type    = typ or "trivial",
        skill   = skill or 0,
        icon    = (GetCraftIcon and GetCraftIcon(i)) or "Interface\\Icons\\INV_Misc_QuestionMark",
        reagents = reag,
        desc    = descLive,
        productLink = productLink,
        baseCD  = baseCD,
        talentReq  = talentReq,
        talentTree = talentTree,
      })
    end
  end
  return true
end

local function RescanNow()
  local ok1, ok2 = false, false
  pcall(function() ok1 = ScanTradeSkill() end)
  pcall(function() ok2 = ScanCraft() end)
  return ok1 or ok2
end


-- Автосканирование этнографии

local function AutoScanEthno()
  local changed = false

  if GetTradeSkillLine then
    local ok, line = pcall(GetTradeSkillLine)
    if ok and IsEthnoLine(line) then
      local sOK, res = pcall(ScanTradeSkill)
      if sOK and res then
        changed = true
      end
    end
  end

  if not changed then
    local craftLine
    if GetCraftDisplaySkillLine then
      local ok, l = pcall(GetCraftDisplaySkillLine)
      if ok then craftLine = l end
    end
    if not craftLine and GetCraftName then
      local ok, l = pcall(GetCraftName)
      if ok then craftLine = l end
    end

    if craftLine and IsEthnoLine(craftLine) then
      local sOK, res = pcall(ScanCraft)
      if sOK and res then
        changed = true
      end
    end
  end

  if changed and _G.EthnoTradeSkillFrame and _G.EthnoTradeSkillFrame:IsShown() and _G.Ethno_RefreshProfessionLinkUI then
    _G.Ethno_RefreshProfessionLinkUI()
  end
end


-- Список рецептов

local function BuildList()
  local t = {}
  local db = Ethno_GetCharDB()
  for _, id in ipairs(db.order) do
    local e = db.recipes[id]
    if e then
      t[#t + 1] = {
        id = id, name = e.name, type = e.type, skill = e.skill, icon = e.icon,
        reagents = e.reagents, desc = e.desc, productLink = e.productLink, spellID = e.spellID,
        baseCD = e.baseCD, cooldown = e.cooldown,
        talentReq  = e.talentReq,
        talentTree = e.talentTree,
      }
    end
  end
  table.sort(t, function(a, b)
    if (a.skill or 0) ~= (b.skill or 0) then return (a.skill or 0) < (b.skill or 0) end
    return (a.name or "") < (b.name or "")
  end)

  if DEBUG_FILL_LIST and #t > 0 then
    local origCount = #t
    local i = 1
    while #t < 60 do
      t[#t + 1] = t[((i - 1) % origCount) + 1]
      i = i + 1
    end
  end

  return t
end


-- Подсчёт сколько могу скрафтить

local function EnsureReagents(e)
  if not e then return nil end
  if not e.reagents or #e.reagents == 0 then
    local regs = ParseReagentsFromTooltip(BuildRecipeChatLink(e))
    if regs then e.reagents = regs end
  end
  return e.reagents
end

local function CraftableCount(e)
  local regs = EnsureReagents(e)
  if not regs or #regs == 0 then return 0 end
  local maxCan = 1000000000
  local any = false
  for _, rr in ipairs(regs) do
    local need = rr.count or 1
    if need <= 0 then need = 1 end
    local have = 0
    rr.itemID = rr.itemID or ItemIDFromAny(rr.itemLink)
    if rr.itemID then
      have = GetItemCount(rr.itemID) or 0
    elseif rr.itemLink then
      have = GetItemCount(rr.itemLink) or 0
    elseif rr.name then
      have = GetItemCount(rr.name) or 0
    end
    any = true
    local can = math.floor((have or 0) / need)
    if can < maxCan then maxCan = can end
    if maxCan == 0 then return 0 end
  end
  if not any then return 0 end
  if maxCan < 0 then return 0 end
  return maxCan
end


local UI = {
  frame=nil, leftInset=nil, rightInset=nil,
  search=nil,
  scroll=nil, rows={}, reagRows={}, sel=1,
  icon=nil, iconBtn=nil, nameFS=nil, cdFS=nil, descFS=nil, reagLabel=nil,
  _lastRegCount=0, _tick=nil,
  leftScrollBG=nil, rightScrollBG=nil, content=nil, rightScroll=nil,
  recipesFlat={}, filtered={}, groupState={}, filterText="",
  dockedTo=nil, anchorTargets={}, _dockingSetup=false,
  profLinkButton=nil,
}

DIFF_COL = {
  trivial    = {0.6, 0.6, 0.6},
  easy       = {0.35, 1.0, 0.35},
  medium     = {1.0, 1.0, 0.4},
  optimal    = {1.0, 0.6, 0.2},
  impossible = {1.0, 0.2, 0.2}
}

local function CreateBGContainer(parent, pad, path, tile)
  local holder = CreateFrame("Frame", nil, parent)
  holder:EnableMouse(false)
  holder:SetFrameLevel((parent:GetFrameLevel() or 0) + 1)
  holder:SetFrameStrata(parent:GetFrameStrata())
  holder:SetPoint("TOPLEFT",     parent, "TOPLEFT",     pad or 0, -(pad or 0))
  holder:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(pad or 0), pad or 0)

  local tex = holder:CreateTexture(nil, "BACKGROUND")
  tex:SetAllPoints()
  tex:SetTexture(path or "")
  if tex.SetHorizTile then tex:SetHorizTile(tile and true or false) end
  if tex.SetVertTile  then tex:SetVertTile(tile and true or false)  end

  holder:Show(); tex:Show()
  return holder, tex
end

local function HookDragArea(frame, root)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function()
    root:StartMoving()
    UI.dockedTo = nil
  end)
  frame:SetScript("OnDragStop", function() root:StopMovingOrSizing() end)
end


local function SetRowTextPos(btn, isHeader, pressed)
  if not btn or not btn.text then return end
  local base = isHeader and (btn.baseXHeader or 22) or (btn.baseXItem or 26)
  local x, y = base, 0
  if pressed then
    x = base - 1
    y = -1
  end
  btn.text:ClearAllPoints()
  btn.text:SetPoint("LEFT", btn, "LEFT", x, y)
end


-- Скролл

local function ApplyScrollbarBackdrop(scrollBG, baseBackdrop, tileEnabled)
  if not scrollBG or not scrollBG.SetBackdrop or not baseBackdrop then return end

  local bd = {}
  for k, v in pairs(baseBackdrop) do
    if type(v) == "table" then
      bd[k] = {}
      for kk, vv in pairs(v) do
        bd[k][kk] = vv
      end
    else
      bd[k] = v
    end
  end

  bd.tile = tileEnabled and true or false
  scrollBG:SetBackdrop(bd)
  scrollBG:SetBackdropColor(0, 0, 0, 0.7)
  scrollBG:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
end

local function DimRightScrollbar(alpha)
  alpha = alpha or 1
  if UI.rightScroll then
    local sb = UI.rightScroll.ScrollBar or _G["EthnoRightScrollScrollBar"]
    if sb then sb:SetAlpha(alpha) end
  end
  if UI.rightScrollBG then
    UI.rightScrollBG:SetAlpha(alpha)
  end
end

local function AutoSizeContent()
  if not UI.content or not UI.content:IsShown() then return end
  local top = UI.content:GetTop()
  if not top then return end

  local lowest = top

  local function consider(frame)
    if frame and frame:IsShown() then
      local b = frame:GetBottom()
      if b and b < lowest then lowest = b end
    end
  end

  consider(UI.descFS)
  consider(UI.cdFS)
  consider(UI.reagLabel)
  for _, fr in ipairs(UI.reagRows or {}) do
    consider(fr)
  end

  if lowest >= top then
    UI.content:SetHeight(FRAME_H)
    return
  end

  local needed = (top - lowest) + REAG_BOTTOM_PAD_EXTRA
  UI.content:SetHeight(needed)
end


local function ReflowRight()
  if not UI.content or not UI.descFS or not UI.cdFS or not UI.nameFS or not UI.icon then return end
  local w = UI.content:GetWidth()
  if not w or w <= 50 then After(0, ReflowRight); return end

  local contentLeft = UI.content:GetLeft() or 0
  local nameLeft    = UI.nameFS:GetLeft() or contentLeft
  local nameWidth   = w - (nameLeft - contentLeft) - DESC_SIDE_PAD
  if nameWidth < 50 then nameWidth = 50 end

  UI.nameFS:SetWidth(nameWidth)
  UI.nameFS:SetHeight(0)
  UI.nameFS:SetMaxLines(2)
  UI.nameFS:SetNonSpaceWrap(false)
  UI.nameFS:SetWordWrap(true)

  local nameH = UI.nameFS:GetStringHeight() or RECIPE_ICON_SIZE

  UI.descFS:ClearAllPoints()
  if nameH > RECIPE_ICON_SIZE then
    UI.descFS:SetPoint("TOPLEFT", UI.nameFS, "BOTTOMLEFT", 0, -DESC_TOP_GAP)
  else
    UI.descFS:SetPoint("TOPLEFT", UI.icon, "BOTTOMLEFT", 0, -DESC_TOP_GAP)
  end
  UI.descFS:SetPoint("RIGHT", UI.content, "RIGHT", -DESC_SIDE_PAD, 0)

  UI.descFS:SetWidth(w - DESC_SIDE_PAD)
  UI.descFS:SetHeight(0)
  UI.descFS:SetMaxLines(0)
  UI.descFS:SetNonSpaceWrap(true)
  UI.descFS:SetWordWrap(true)

  UI.cdFS:ClearAllPoints()
  UI.cdFS:SetPoint("TOPLEFT", UI.descFS, "BOTTOMLEFT", 0, -6)
  UI.cdFS:SetWidth(w - DESC_SIDE_PAD)
  UI.cdFS:SetHeight(0)

  AutoSizeContent()
end


-- Список
function UI.RebuildFiltered()
  local text = UI.filterText or ""
  local raw  = UI.recipesFlat or {}

  local noFilter = (text == "" or text == SEARCH)
  local needle   = string.lower(text or "")

  local groups = {}

  for _, e in ipairs(raw) do
    local matches = false

    if noFilter then
      matches = true
    else
      local nameLower = string.lower(e.name or "")
      if string.find(nameLower, needle, 1, true) then
        matches = true
      end

      if not matches and e.desc and e.desc ~= "" then
        local descLower = string.lower(e.desc)
        if string.find(descLower, needle, 1, true) then
          matches = true
        end
      end

      if not matches then
        local regs = EnsureReagents(e) or {}
        for _, rr in ipairs(regs) do
          local rn = rr.name and string.lower(rr.name) or ""
          if rn ~= "" and string.find(rn, needle, 1, true) then
            matches = true
            break
          end
        end
      end
    end

    if matches then
      local cat = e.talentTree
      if not cat or cat == "" then
        cat = "Поиск знаний"
      end

      if not groups[cat] then
        groups[cat] = { name = cat, items = {} }
      end
      table.insert(groups[cat].items, e)
    end
  end

  for _, g in pairs(groups) do
    table.sort(g.items, function(a, b)
      if (a.skill or 0) ~= (b.skill or 0) then return (a.skill or 0) < (b.skill or 0) end
      return (a.name or "") < (b.name or "")
    end)
  end

  local headers = {}
  for name in pairs(groups) do table.insert(headers, name) end

  local currentSpec = CurrentSpecName

  table.sort(headers, function(a, b)
    local aIsSearch = (a == "Поиск знаний")
    local bIsSearch = (b == "Поиск знаний")

    if aIsSearch ~= bIsSearch then
      return not aIsSearch -- «Поиск знаний» всегда последняя
    end

    if currentSpec and (a == currentSpec or b == currentSpec) then
      if a == currentSpec and b ~= currentSpec then return true end
      if b == currentSpec and a ~= currentSpec then return false end
    end

    return a < b
  end)

  local view = {}

  for _, cat in ipairs(headers) do
    local g = groups[cat]
    table.insert(view, { isHeader = true, headerName = cat })
    if UI.groupState[cat] ~= false then
      for _, e in ipairs(g.items) do
        table.insert(view, e)
      end
    end
  end

  UI.filtered = view

  if #view == 0 then
    UI.sel = 0
    return
  end

  if not UI.sel or UI.sel < 1 or UI.sel > #view then
    UI.sel = 1
  end

  if view[UI.sel].isHeader then
    local idx = UI.sel + 1
    while idx <= #view and view[idx].isHeader do
      idx = idx + 1
    end
    if idx <= #view then
      UI.sel = idx
    else
      UI.sel = 1
    end
  end
end


-- Выравнивание

function UI.SetDefaultPosition()
  if not UI.frame then return end
  UI.frame:ClearAllPoints()
  UI.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -100)
  UI.dockedTo = nil
end

function UI.DockTo(target)
  if not UI.frame or not target or not target.IsShown or not target:IsShown() then return end
  UI.frame:ClearAllPoints()
  UI.frame:SetPoint("TOPLEFT", target, "TOPRIGHT", 20, 0)
  UI.dockedTo = target
end

local function SetupDockingHooks()
  if UI._dockingSetup then return end
  UI._dockingSetup = true

  local names = {
    "TradeSkillFrame",
    "CraftFrame",
    "CharacterFrame",
    "SpellBookFrame",
    "AuctionFrame",
    "AuctionHouseFrame",
    "ProfessionsFrame",
    "PVEFrame",
    "FriendsFrame",
  }

  local function hookFrameByName(name)
    local frame = _G[name]
    if not frame or not frame.HookScript then return end
    table.insert(UI.anchorTargets, frame)

    frame:HookScript("OnShow", function(self)
      if UI.frame and UI.frame:IsShown() then
        UI.DockTo(self)
      end
    end)

    frame:HookScript("OnHide", function(self)
      if UI.frame and UI.frame:IsShown() and UI.dockedTo == self then
        UI.SetDefaultPosition()
      end
    end)
  end

  for _, n in ipairs(names) do
    hookFrameByName(n)
  end
end



-- Кнопка в книге

local spellbookButton
local spellbookText
local UpdateSpellbookButtonState


-- Линк профессии

local function RefreshProfessionLinkUI()
  local db = Ethno_GetCharDB()
  local link = db and db.profLink or nil
  if UI.profLinkButton then
    if link and link ~= "" then
      UI.profLinkButton:Show()
    else
      UI.profLinkButton:Hide()
    end
  end
end
_G.Ethno_RefreshProfessionLinkUI = RefreshProfessionLinkUI


-- UI

local function EnsureUI()
  if UI.frame then return end

  local f = CreateFrame("Frame", "EthnoTradeSkillFrame", UIParent, "PortraitFrameTemplate")
  f:SetSize(FRAME_W, FRAME_H)
  f:SetPoint("CENTER")
  f:Hide()
  SetPortraitToTexture(f.portrait, "Interface\\Icons\\Spell_Monk_BrewmasterTraining")
  _G[f:GetName() .. "TitleText"]:SetText("Этнография")
  UI.frame = f

  f:SetMovable(true)
  f:SetClampedToScreen(true)
  HookDragArea(f, f)

  f:HookScript("OnShow", function()
    if UpdateSpellbookButtonState then UpdateSpellbookButtonState() end
  end)
  f:HookScript("OnHide", function()
    if UpdateSpellbookButtonState then UpdateSpellbookButtonState() end
  end)

  -- Строка поиска
  local search = CreateFrame("EditBox", nil, f, "SearchBoxTemplate")
  search:SetAutoFocus(false)
  search:SetWidth(SEARCH_BOX_WIDTH or ((FRAME_W - 32) / 2))
  search:SetHeight(20)
  search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -40, -36) -- чуть левее, чтобы справа поместилась кнопка
  UI.search = search
-- Линк
  local profBtn = CreateFrame("Button", nil, f)
  profBtn:SetSize(20, 20)
  profBtn:SetPoint("LEFT", search, "RIGHT", 4, 0)
  profBtn:RegisterForClicks("AnyUp")
  UI.profLinkButton = profBtn

  profBtn.icon = profBtn:CreateTexture(nil, "ARTWORK")
  profBtn.icon:SetAllPoints()
  profBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_03")

  profBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

  if not UI.profLinkDropDown then
    UI.profLinkDropDown = CreateFrame("Frame", "EthnoProfLinkDropDown", UIParent, "UIDropDownMenuTemplate")
  end

  profBtn:SetScript("OnClick", function(self, button)
    local db = Ethno_GetCharDB()
    local link = db and db.profLink
    if not link or link == "" then
      print("|cff33ff99EthnoProf:|r нет сохранённой ссылки профессии. Откройте реальную Этнографию и используйте /ethno reload.")
      return
    end

    local menu = {}

    local function addEntry(text, chatType, arg2)
      table.insert(menu, {
        text = text,
        func = function()
          if chatType == "EDIT" then
            local edit = (ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend()) or (ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow())
            if not edit then return end
            ChatEdit_ActivateChat(edit)
            edit:SetText(link)
            edit:HighlightText()
            return
          end
          SendChatMessage(link, chatType, nil, arg2)
        end,
      })
    end

    addEntry("В текущий чат", "EDIT")

    table.insert(menu, { text = "—— Каналы ——", isTitle = true, notCheckable = true })

    addEntry("Сказать", "SAY")
    addEntry("Крик", "YELL")
    addEntry("Группа", "PARTY")
    addEntry("Рейд", "RAID")
    if IsInGuild and IsInGuild() then
      addEntry("Гильдия", "GUILD")
      addEntry("Офицеры", "OFFICER")
    end

    local chans = { GetChannelList() }
    if #chans > 0 then
      table.insert(menu, { text = "—— Пользовательские каналы ——", isTitle = true, notCheckable = true })
      for i = 1, #chans, 3 do
        local id   = chans[i]
        local name = chans[i + 1]
        local disabled = chans[i + 2]
        if id and name and not disabled then
          addEntry(string.format("%d. %s", id, name), "CHANNEL", id)
        end
      end
    end

    EasyMenu(menu, UI.profLinkDropDown, self, 0, 0, "MENU", 2)
  end)

  profBtn:SetScript("OnEnter", function(self)
    local db = Ethno_GetCharDB()
    local link = db and db.profLink
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    if link and link ~= "" then
      GameTooltip:SetHyperlink(link)
      GameTooltip:AddLine(" ", 1, 1, 1)
      GameTooltip:AddLine("ЛКМ: выбрать чат и отправить ссылку на Этнографию.", 0.9, 0.9, 0.9, true)
    else
      GameTooltip:AddLine("Нет сохранённой ссылки профессии.", 1, 0.2, 0.2)
      GameTooltip:AddLine("Откройте реальную Этнографию и используйте /ethno reload.", 1, 0.82, 0, true)
    end
    GameTooltip:Show()
  end)
  profBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  RefreshProfessionLinkUI()

  local left = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
  left:SetSize(LEFT_W, LEFT_H)
  left:SetPoint("TOPLEFT", 12, -60)
  UI.leftInset = left

  CreateBGContainer(left, LEFT_BG_PAD, LEFT_BG_TEXTURE, LEFT_BG_TILE)
  HookDragArea(left, f)

  local scroll = CreateFrame("ScrollFrame", "EthnoTradeSkillListScrollFrame", left, "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", left, "TOPLEFT", 0, -LIST_TOP_PAD)
  scroll:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -28, LIST_BOTTOM_PAD)
  UI.scroll = scroll

  After(0, function()
    local leftSB = _G["EthnoTradeSkillListScrollFrameScrollBar"] or scroll.ScrollBar
    if leftSB and not UI.leftScrollBG then
      local parent = left

      leftSB:ClearAllPoints()
      leftSB:SetPoint("RIGHT", parent, "RIGHT", -4, 0)

      local parentH = parent:GetHeight() or 0
      local baseH = parentH - 32
      if baseH < 0 then baseH = 0 end
      local barExtra = LEFT_SCROLLBAR_BAR_HEIGHT_EXTRA or 0
      leftSB:SetHeight(baseH + barExtra)

      local bg = CreateFrame("Frame", nil, leftSB)
      bg:SetFrameLevel(leftSB:GetFrameLevel() - 1)
      bg:SetPoint("CENTER", leftSB, "CENTER", LEFT_SCROLLBAR_OFFSET_X, LEFT_SCROLLBAR_OFFSET_Y)

      local sbW = leftSB:GetWidth() or 16
      local width = (LEFT_SCROLLBAR_WIDTH and LEFT_SCROLLBAR_WIDTH > 0) and LEFT_SCROLLBAR_WIDTH or sbW
      bg:SetWidth(width)

      local bgExtra = LEFT_SCROLLBAR_BG_HEIGHT_EXTRA or 0
      local bgH = (leftSB:GetHeight() or baseH) + bgExtra
      if bgH < 0 then bgH = 0 end
      bg:SetHeight(bgH)

      ApplyScrollbarBackdrop(bg, SCROLLBAR_BACKDROP, LEFT_SCROLL_TILE_DEFAULT)
      UI.leftScrollBG = bg
    end
  end)

  for i = 1, VISIBLE_ROWS do
    local btn = CreateFrame("Button", "EthnoTradeSkillRow" .. i, left)
    btn:SetSize(LEFT_W - 40, ROW_H)
    btn:SetPoint("TOPLEFT", left, "TOPLEFT", 14, -LIST_TOP_PAD - (i - 1) * ROW_H)
    btn:SetNormalFontObject("GameFontHighlightSmall")
    btn:SetHighlightTexture(nil)

    btn.selTex = btn:CreateTexture(nil, "ARTWORK")
    btn.selTex:SetAllPoints()
    btn.selTex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
    btn.selTex:SetBlendMode("ADD")
    btn.selTex:SetVertexColor(0.55, 0.55, 0.55, 0.95)
    btn.selTex:Hide()

    btn.baseXItem   = 26
    btn.baseXHeader = 22

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(HEADER_ICON_SIZE, HEADER_ICON_SIZE)
    btn.icon:SetPoint("LEFT", btn, "LEFT", 2, 0)
    btn.icon:Hide()

    btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    btn.text:SetJustifyH("LEFT")
    btn.text:SetWidth(LEFT_W - 40)
    btn.text:SetHeight(ROW_H)
    btn.text:SetMaxLines(1)
    btn.text:SetWordWrap(false)
    btn.text:SetNonSpaceWrap(false)
    BumpFont(btn.text, 2)
    SetRowTextPos(btn, false, false)

    btn:SetScript("OnClick", function(self)
      local e = UI.filtered and UI.filtered[self.index]
      if not e then return end

      if e.isHeader then
        local cat = e.headerName or ""
        local state = UI.groupState[cat]
        UI.groupState[cat] = (state == false) and true or false
        UI.RebuildFiltered()
        UI.UpdateList()
        UI.UpdateRight()
        return
      end

      if IsShiftKeyDown() then
        local edit = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
        if edit then
          local link = BuildRecipeChatLink(e)
          if link then
            ChatEdit_InsertLink(link)
            return
          end
        end
      end

      UI.sel = self.index
      UI.UpdateRight()
      UI.UpdateList()
    end)

    btn:SetScript("OnEnter", function(self)
      local e = UI.filtered and UI.filtered[self.index]
      if not e then return end
      if e.isHeader then
        self.text:SetTextColor(1, 1, 1)
        SetRowTextPos(self, true, false)
      else
        if self.index ~= UI.sel then
          self.text:SetTextColor(1, 1, 1)
        end
        SetRowTextPos(self, false, false)
      end
    end)

    btn:SetScript("OnLeave", function(self)
      local e = UI.filtered and UI.filtered[self.index]
      if not e then return end
      if e.isHeader then
        self.text:SetTextColor(1, 0.82, 0)
        SetRowTextPos(self, true, false)
      else
        if self.index == UI.sel then
          self.text:SetTextColor(1, 1, 1)
        else
          self.text:SetTextColor(LIST_TEXT_GREY_R, LIST_TEXT_GREY_G, LIST_TEXT_GREY_B)
        end
        SetRowTextPos(self, false, false)
      end
    end)

    btn:SetScript("OnMouseDown", function(self, button)
      if button ~= "LeftButton" then return end
      local e = UI.filtered and UI.filtered[self.index]
      if not e then return end
      SetRowTextPos(self, e.isHeader, true)
    end)

    btn:SetScript("OnMouseUp", function(self, button)
      if button ~= "LeftButton" then return end
      local e = UI.filtered and UI.filtered[self.index]
      local isHeader = e and e.isHeader
      SetRowTextPos(self, isHeader, false)
    end)

    UI.rows[i] = btn
  end

  scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, UI.UpdateList)
  end)

  local right = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
  right:SetPoint("TOPLEFT", left, "TOPRIGHT", PANE_SEPARATOR_WIDTH, 0)
  right:SetPoint("BOTTOMRIGHT", -12, 12)
  UI.rightInset = right

  CreateBGContainer(right, RIGHT_BG_PAD, RIGHT_BG_TEXTURE, RIGHT_BG_TILE)
  HookDragArea(right, f)

  local sf = CreateFrame("ScrollFrame", "EthnoRightScroll", right, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 4, -4)
  sf:SetPoint("BOTTOMRIGHT", -18, 4)
  UI.rightScroll = sf

  After(0, function()
    local rightSB = sf.ScrollBar or _G["EthnoRightScrollScrollBar"]
    if rightSB and not UI.rightScrollBG then
      local bg = CreateFrame("Frame", nil, rightSB)
      bg:SetFrameLevel(rightSB:GetFrameLevel() - 1)

      bg:SetPoint("CENTER", rightSB, "CENTER", RIGHT_SCROLLBAR_OFFSET_X, RIGHT_SCROLLBAR_OFFSET_Y)

      local sbW = rightSB:GetWidth() or 16
      local sbH = rightSB:GetHeight() or 0

      local width  = (RIGHT_SCROLLBAR_WIDTH and RIGHT_SCROLLBAR_WIDTH > 0) and RIGHT_SCROLLBAR_WIDTH or sbW
      local bgExtra = RIGHT_SCROLLBAR_BG_HEIGHT_EXTRA or 0
      local height = sbH + bgExtra

      bg:SetWidth(width)
      if height > 0 then
        bg:SetHeight(height)
      end

      ApplyScrollbarBackdrop(bg, SCROLLBAR_BACKDROP, RIGHT_SCROLL_TILE_DEFAULT)
      UI.rightScrollBG = bg
      rightSB:Show()
    end
  end)

  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(400, 100)
  sf:SetScrollChild(content)
  UI.content = content
  sf:SetScript("OnSizeChanged", function(_, w, _)
    if w and w > 0 then UI.content:SetWidth(w - 6) After(0, ReflowRight) end
  end)

  UI.icon = content:CreateTexture(nil, "ARTWORK")
  UI.icon:SetSize(RECIPE_ICON_SIZE, RECIPE_ICON_SIZE)
  UI.icon:SetPoint("TOPLEFT", 8, -12)

  UI.iconBtn = CreateFrame("Button", nil, content)
  UI.iconBtn:SetAllPoints(UI.icon)
  UI.iconBtn:EnableMouse(true)

  UI.nameFS = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  UI.nameFS:SetPoint("TOPLEFT", UI.icon, "TOPRIGHT", 8, 0)
  UI.nameFS:SetPoint("RIGHT", content, "RIGHT", -DESC_SIDE_PAD, 0)
  UI.nameFS:SetJustifyH("LEFT")
  UI.nameFS:SetJustifyV("TOP")
  UI.nameFS:SetWordWrap(true)
  UI.nameFS:SetNonSpaceWrap(false)
  UI.nameFS:SetMaxLines(2)

  UI.descFS = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  UI.descFS:SetPoint("TOPLEFT", UI.icon, "BOTTOMLEFT", 0, -DESC_TOP_GAP)
  UI.descFS:SetPoint("RIGHT", content, "RIGHT", -DESC_SIDE_PAD, 0)
  UI.descFS:SetJustifyH("LEFT")
  UI.descFS:SetJustifyV("TOP")
  UI.descFS:SetWordWrap(true)
  UI.descFS:SetNonSpaceWrap(true)
  UI.descFS:SetSpacing(1)
  UI.descFS:SetMaxLines(0)

  UI.cdFS = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  UI.cdFS:SetPoint("TOPLEFT", UI.descFS, "BOTTOMLEFT", 0, -6)
  UI.cdFS:SetJustifyH("LEFT")
  UI.cdFS:SetText("")

  UI.reagLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  UI.reagLabel:SetText("Реагенты:")
  UI.reagLabel:SetPoint("TOPLEFT", UI.cdFS, "BOTTOMLEFT", 0, -10)


  -- Реагенты

  for i = 1, 8 do
    local fr = CreateFrame("Frame", "EthnoReagent" .. i, content)
    fr:SetSize(REAG_NAME_FRAME_WIDTH, REAG_NAME_FRAME_HEIGHT)

    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local x = col * REAG_COL_W
    local y = -REAG_TOP_GAP - (row * (REAG_NAME_FRAME_HEIGHT + REAG_ROW_VSP))
    fr:SetPoint("TOPLEFT", UI.reagLabel, "BOTTOMLEFT", x, y)

    fr.slot = fr:CreateTexture(nil, "BACKGROUND")
    fr.slot:SetSize(REAG_SLOT_WIDTH, REAG_SLOT_HEIGHT)
    fr.slot:SetPoint(REAG_SLOT_ANCHOR, fr, REAG_SLOT_REL_POINT, REAG_SLOT_OFFSET_X, REAG_SLOT_OFFSET_Y)
    fr.slot:SetTexture(REAG_SLOT_TEXTURE)

    if fr.slot.SetHorizTile then fr.slot:SetHorizTile(REAG_SLOT_TILE_H) end
    if fr.slot.SetVertTile  then fr.slot:SetVertTile(REAG_SLOT_TILE_V)  end
    if REAG_SLOT_TEXCOORDS then
      fr.slot:SetTexCoord(unpack(REAG_SLOT_TEXCOORDS))
    end
    fr.slot:SetVertexColor(REAG_SLOT_COLOR_R, REAG_SLOT_COLOR_G, REAG_SLOT_COLOR_B, REAG_SLOT_COLOR_A)

    fr:SetScript("OnSizeChanged", function(self)
      if not self.slot then return end
      self.slot:ClearAllPoints()
      self.slot:SetPoint(REAG_SLOT_ANCHOR, self, REAG_SLOT_REL_POINT, REAG_SLOT_OFFSET_X, REAG_SLOT_OFFSET_Y)
      self.slot:SetSize(REAG_SLOT_WIDTH, REAG_SLOT_HEIGHT)
    end)

    fr.icon = fr:CreateTexture(nil, "ARTWORK")
    fr.icon:SetSize(REAG_ICON_SIZE, REAG_ICON_SIZE)
    fr.icon:SetPoint("LEFT", 2, 0)
    fr.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    fr.count = fr:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fr.count:SetPoint("BOTTOMRIGHT", fr.icon, "BOTTOMRIGHT", -2, 4)
    BumpFont(fr.count, REAG_COUNT_FONT_DELTA or 0)
    fr.count:SetTextColor(1, 1, 1)

    fr.name = fr:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fr.name:SetJustifyH("LEFT")
    fr.name:SetJustifyV("MIDDLE")
    fr.name:SetWordWrap(true)
    fr.name:SetPoint("TOPLEFT", fr.icon, "TOPRIGHT", NAME_MIN_PAD_X, -2)
    fr.name:SetPoint("BOTTOMRIGHT", fr, "BOTTOMRIGHT", -NAME_RIGHT_PAD, 2)
    BumpFont(fr.name, 2)
    fr.name:SetTextColor(1, 1, 1)

    fr:EnableMouse(true)
    fr:SetScript("OnEnter", function(self)
      local d = self._data
      if not d then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if d.itemLink then
        GameTooltip:SetHyperlink(d.itemLink)
      elseif d.itemID then
        GameTooltip:SetHyperlink("item:" .. d.itemID)
      else
        GameTooltip:SetText(d.name or "-")
      end
      GameTooltip:Show()
    end)
    fr:SetScript("OnLeave", function() GameTooltip:Hide() end)

    fr:SetScript("OnMouseUp", function(self, button)
      local d = self._data
      if not d or button ~= "LeftButton" or not IsShiftKeyDown() then return end

      local itemName
      if d.itemID then
        itemName = GetItemInfo(d.itemID)
      end
      itemName = itemName or d.name or ""

      if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
        local box = _G["AuctionHouseFrameSearchBarSearchBox"]
          or (AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchBox)
        if box then
          box:SetText(itemName)
          box:ClearFocus()
          if AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchButton then
            AuctionHouseFrame.SearchBar.SearchButton:Click()
          end
          return
        end
      end

      if AuctionFrame and AuctionFrame:IsShown() and BrowseName then
        BrowseName:SetText(itemName)
        BrowseName:ClearFocus()
        if BrowseSearchButton and BrowseSearchButton:IsEnabled() then
          BrowseSearchButton:Click()
        elseif AuctionFrameBrowse_Search then
          AuctionFrameBrowse_Search()
        end
        return
      end

      local edit = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
      if not edit then return end

      local link = d.itemLink
      if not link and d.itemID then
        local _, pretty = GetItemInfo(d.itemID)
        link = pretty or ("item:" .. d.itemID)
      end

      if link then
        ChatEdit_InsertLink(link)
      elseif itemName ~= "" then
        ChatEdit_InsertLink(itemName)
      end
    end)

    fr:Hide()
    UI.reagRows[i] = fr
  end



  function UI.UpdateList()
    local data = UI.filtered or {}
    local total = #data
    local displayed = VISIBLE_ROWS

    FauxScrollFrame_Update(UI.scroll, total, displayed, ROW_H)

    local offset = FauxScrollFrame_GetOffset(UI.scroll) or 0
    for i = 1, displayed do
      local row = UI.rows[i]
      local idx = i + offset
      row.index = idx
      local e = data[idx]
      if e then
        row:Show()
        if e.isHeader then
          local txt = e.headerName or "Категория"
          row.text:SetText(txt)
          row.text:SetTextColor(1, 0.82, 0)
          row.icon:Show()
          row.selTex:Hide()
          local cat = e.headerName or ""
          if UI.groupState[cat] == false then
            row.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
          else
            row.icon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
          end
          SetRowTextPos(row, true, false)
        else
          row.icon:Hide()
          local txt = e.name or ("Запись " .. idx)
          local nCan = CraftableCount(e)
          if nCan and nCan >= 1 then
            txt = txt .. " (" .. nCan .. ")"
          end
          row.text:SetText(txt)

          if idx == UI.sel then
            row.text:SetTextColor(1, 1, 1)
            row.selTex:Show()
          else
            row.text:SetTextColor(LIST_TEXT_GREY_R, LIST_TEXT_GREY_G, LIST_TEXT_GREY_B)
            row.selTex:Hide()
          end
          SetRowTextPos(row, false, false)
        end
      else
        row:Hide()
      end
    end
  end

  function UI.UpdateRight()
    local e = UI.filtered and UI.filtered[UI.sel]
    if e and e.isHeader then e = nil end

    for i = 1, #UI.reagRows do UI.reagRows[i]:Hide() end
    if not e then
      UI.icon:SetTexture(nil)
      UI.nameFS:SetText("")
      UI.cdFS:SetText("")
      UI.descFS:SetText("")
      UI.content:SetHeight(FRAME_H)
      return
    end

    UI.icon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    UI.nameFS:SetText(e.name or "")

    UI.iconBtn:SetScript("OnEnter", function()
      GameTooltip:SetOwner(UI.iconBtn, "ANCHOR_RIGHT")
      GameTooltip:ClearLines()
      GameTooltip:AddLine(e.name or "-", 1, 0.82, 0)
      if e.desc and e.desc ~= "" then GameTooltip:AddLine(e.desc, 1, 1, 1, true) end
      if e.talentTree or e.talentReq then
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("Требования:", 1, 0.82, 0)
        if e.talentTree then
          GameTooltip:AddLine("Ветка: " .. e.talentTree, 0.8, 0.8, 1)
        end
        if e.talentReq then
          GameTooltip:AddLine("Талант: " .. e.talentReq, 0.8, 0.8, 1)
        end
      end
      GameTooltip:Show()
    end)
    UI.iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	
	UI.iconBtn:SetScript("OnClick", function(_, button)
      if button ~= "LeftButton" or not IsShiftKeyDown() then return end
      local edit = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
      if not edit then return end
      local link = BuildRecipeChatLink(e)
      if link then
        ChatEdit_InsertLink(link)
      end
    end)


    UI.descFS:SetText(BuildDescText(e.desc))

    local cdText, r, g, b = BuildCooldownText(e)
    if cdText then
      UI.cdFS:SetText(cdText)
      UI.cdFS:SetTextColor(r, g, b)
    else
      UI.cdFS:SetText("")
    end

    local regs = EnsureReagents(e) or {}
    local count = #regs
    UI._lastRegCount = count
    if count > 0 then UI.reagLabel:Show() else UI.reagLabel:Hide() end

    for i = 1, math.min(count, #UI.reagRows) do
      local rr = regs[i]
      local fr = UI.reagRows[i]
      fr._data = rr
      fr.icon:SetTexture(rr.texture or "Interface\\Icons\\INV_Misc_QuestionMark")

      rr.itemID = rr.itemID or ItemIDFromAny(rr.itemLink)
      local have = 0
      if rr.itemID then have = GetItemCount(rr.itemID) or 0 end
      local need = rr.count or 1
      if need <= 0 then need = 1 end

      fr.count:SetText((have or 0) .. "/" .. need)
      fr.count:SetTextColor(1, 1, 1)

      fr.name:SetText(rr.name or ("Компонент " .. i))
      if (have or 0) >= need then
        fr.name:SetTextColor(1, 1, 1)
        fr.icon:SetVertexColor(1, 1, 1)
      else
        fr.name:SetTextColor(REAG_TEXT_GREY_R, REAG_TEXT_GREY_G, REAG_TEXT_GREY_B)
        fr.icon:SetVertexColor(REAG_TEXT_GREY_R, REAG_TEXT_GREY_G, REAG_TEXT_GREY_B)
      end

      fr:Show()
    end

    After(0, ReflowRight)
  end

  function UI.ApplyFilter()
    local text = string.lower(UI.search:GetText() or "")
    UI.filterText = text
    UI.recipesFlat = BuildList()
    UI.RebuildFiltered()
    UI.UpdateList()
    UI.UpdateRight()
  end

  if not UI._tick then
    UI._tick = CreateFrame("Frame", nil, UI.frame)
    local acc = 0
    UI._tick:SetScript("OnUpdate", function(_, el)
      if not UI.frame:IsShown() then return end
      acc = acc + el
      if acc >= 1 then
        acc = 0
        local e = UI.filtered and UI.filtered[UI.sel]
        if e and e.isHeader then return end
        if e then
          local cdText, r, g, b = BuildCooldownText(e)
          if cdText then
            UI.cdFS:SetText(cdText)
            UI.cdFS:SetTextColor(r, g, b)
          else
            UI.cdFS:SetText("")
          end
          After(0, ReflowRight)
        end
      end
    end)
  end

  UI.frame:RegisterEvent("BAG_UPDATE")
  UI.frame:SetScript("OnEvent", function(_, ev)
    if ev == "BAG_UPDATE" and UI.frame:IsShown() then UI.UpdateList() end
  end)

  UI.search:SetScript("OnTextChanged", function(self)
    SearchBoxTemplate_OnTextChanged(self)
    UI.ApplyFilter()
  end)
end


-- Открытие окна

local function OpenOfflineUI()
  local db = Ethno_GetCharDB()
  if not next(db.recipes) then
    print("|cff33ff99EthnoProf:|r нет кэша. Откройте «Этнография» у НПЦ и введите |cffffff00/ethno reload|r.")
    return
  end
  EnsureUI()
  RefreshProfessionLinkUI()
  ShowUIPanel(UI.frame)
  UI.ApplyFilter()

  local docked = false
  for _, frame in ipairs(UI.anchorTargets or {}) do
    if frame:IsShown() then
      UI.DockTo(frame)
      docked = true
      break
    end
  end
  if not docked then
    UI.SetDefaultPosition()
  end
end

function EthnoProf_Toggle()
  EnsureUI()
  if UI.frame:IsShown() then
    HideUIPanel(UI.frame)
  else
    OpenOfflineUI()
  end
  if UpdateSpellbookButtonState then UpdateSpellbookButtonState() end
end

function EthnoProf_Open()
  if not (UI.frame and UI.frame:IsShown()) then
    OpenOfflineUI()
  end
  if UpdateSpellbookButtonState then UpdateSpellbookButtonState() end
end


-- Кнопк в книге заклинаний

local ETHNO_SPELLBOOK_ICON = "Interface\\Icons\\Spell_Monk_BrewmasterTraining"

local function EnsureSpellbookButton()
  if spellbookButton then return end
  if not SpellBookProfessionFrame then return end

  local parent = SpellBookProfessionFrame
  local anchor = _G["SecondaryProfession3"] or parent

  local btn = CreateFrame("Button", "EthnoProfProfessionButton", parent, "SecureActionButtonTemplate")
  spellbookButton = btn

  btn:SetSize(36, 36)
  btn:SetPoint("CENTER", anchor, "CENTER", SPELLBOOK_BUTTON_OFFSET_X, SPELLBOOK_BUTTON_OFFSET_Y)

  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetAllPoints()
  btn.icon:SetTexture(ETHNO_SPELLBOOK_ICON)

  btn.border = btn:CreateTexture(nil, "OVERLAY")
  btn.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  btn.border:SetBlendMode("ADD")
  btn.border:SetAlpha(0.9)
  btn.border:SetSize(64, 64)
  btn.border:SetPoint("CENTER")
  btn.border:Hide()

  btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

  btn:RegisterForClicks("AnyUp")
  btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
      EthnoProf_Toggle()
    end
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Этнография", 1, 1, 1)
    GameTooltip:AddLine("Прошло неизмеримо много времени с тех пор, когда изначальные покинули нас, но их знания добрались и до наших дней на древних на осколках скрижалей, в письменах которых заложена магическая суть.", 1, 0.82, 0, true)
    GameTooltip:AddLine("Изучение и применение этнографии производится у тренера", 0.9, 0.9, 0.9)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  if not spellbookText then
    spellbookText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellbookText:SetPoint("LEFT", btn, "RIGHT", 6, 0)
    spellbookText:SetText("Этнография")
  end
end

UpdateSpellbookButtonState = function()
  if not spellbookButton or not spellbookButton.border then return end
  if UI.frame and UI.frame:IsShown() then
    spellbookButton.border:Show()
  else
    spellbookButton.border:Hide()
  end
end




-- События - команды
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_TALENT_UPDATE")
ev:RegisterEvent("TRADE_SKILL_SHOW")
ev:RegisterEvent("CRAFT_SHOW")
ev:SetScript("OnEvent", function(_, evt)
  if evt == "PLAYER_LOGIN" then
    BuildTalentNameToTree()
    UpdateCurrentSpecName()
    SetupDockingHooks()

    local db = Ethno_GetCharDB()
    if db and db.recipes then
      for _, e in pairs(db.recipes) do
        if e.desc then
          e.desc = TrimDescTrailingNewlines(e.desc)
        end
      end
    end

    After(0.5, function()
      if SpellBookFrame and SpellBookFrame.HookScript and not UI._spellBookHooked then
        UI._spellBookHooked = true
        SpellBookFrame:HookScript("OnShow", function() EnsureSpellbookButton() end)
      end
      EnsureSpellbookButton()
      if UpdateSpellbookButtonState then UpdateSpellbookButtonState() end
    end)

    SLASH_ETHNO1 = "/ethno"
    SlashCmdList.ETHNO = function(msg)
      msg = string.lower(msg or "")

      if msg == "reload" then
        if RescanNow() then
          print("|cff33ff99EthnoProf:|r кэш обновлён.")
          if UI.frame and UI.frame:IsShown() then
            RefreshProfessionLinkUI()
          end
        else
          print("|cff33ff99EthnoProf:|r откройте окно Этнографии у НПЦ и повторите.")
        end

      elseif msg == "clear" then
        ResetDB()
        print("|cff33ff99EthnoProf:|r кэш очищен.")
        if UI.frame and UI.frame:IsShown() then
          RefreshProfessionLinkUI()
          UI.ApplyFilter()
        end

      elseif msg == "help" or msg == "?" then
        print("|cff33ff99EthnoProf:|r доступные команды:")
        print("  |cffffff00/ethno|r — открыть/закрыть окно оффлайн-Этнографии.")
        print("  |cffffff00/ethno reload|r — пересканировать рецепты из открытого окна профессии.")
        print("  |cffffff00/ethno clear|r — очистить сохранённый кэш рецептов.")
        print("  |cffffff00/ethno help|r — показать эту справку.")

      else
        EthnoProf_Toggle()
      end
    end

  elseif evt == "PLAYER_TALENT_UPDATE" then
    BuildTalentNameToTree()
    UpdateCurrentSpecName()
    if UI.frame and UI.frame:IsShown() then
      UI.recipesFlat = BuildList()
      UI.RebuildFiltered()
      UI.UpdateList()
      UI.UpdateRight()
    end

  elseif evt == "TRADE_SKILL_SHOW" or evt == "CRAFT_SHOW" then
    AutoScanEthno()
  end
end)
