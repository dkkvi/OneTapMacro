-- One Tap Macro
-- hover a spell on your bars or in the spellbook, press ctrl+alt, and it turns
-- into a character macro made from your template. modifiers only, so it needs
-- no key binding and can't clash with yours

-- the old key binding from before ctrl+alt, cleared once at login
local OLD_BIND = "ONETAPMACRO_CREATE"

-- casts at the enemy under your mouse if there is one, otherwise your target.
-- /startattack stays on your target either way
local DEFAULT_TEMPLATE = "#showtooltip\n/startattack\n/cast [@mouseover,harm,nodead][] {spell}"
-- the default before mouseover, so an untouched copy of it gets upgraded
local OLD_DEFAULT_TEMPLATE = "#showtooltip\n/startattack\n/cast {spell}"
-- the ? icon makes a macro follow #showtooltip
local DYNAMIC_ICON = 134400
local MACRO_NAME_MAX = 16
local MACRO_BODY_MAX = 255

local function say(msg)
	print("|cffffd200One Tap Macro|r: " .. msg)
end

-- Finding the spell ------------------------------------------------------------

local function hoveredFrame()
	if GetMouseFoci then
		return GetMouseFoci()[1]
	end
	return GetMouseFocus and GetMouseFocus()
end

-- action buttons know their slot, which also tells us what's on it
local function hoveredSlot()
	local frame = hoveredFrame()
	if not frame then return end
	local slot = frame.action or (frame.GetAttribute and frame:GetAttribute("action"))
	if type(slot) == "number" and HasAction(slot) then
		return slot
	end
end

-- the spellbook has no slot, but whatever you hover shows its tooltip
local function tooltipSpell()
	if not GameTooltip:IsShown() then return end
	local data = GameTooltip.GetPrimaryTooltipData and GameTooltip:GetPrimaryTooltipData()
	if data and data.type == Enum.TooltipDataType.Spell then
		return data.id
	end
	local _, spellID = GameTooltip:GetSpell()
	return spellID
end

-- Making the macro -------------------------------------------------------------

local function buildBody(spellName)
	local template = OneTapMacroDB.template
	-- a function as the replacement, so a % in a spell name can't break it
	return (template:gsub("{spell}", function() return spellName end))
end

-- same name means same spell, so pressing it again updates instead of
-- making a second one
local function saveMacro(spellName, body)
	local name = spellName:sub(1, MACRO_NAME_MAX)
	local index = GetMacroIndexByName(name)
	if index > 0 then
		EditMacro(index, name, DYNAMIC_ICON, body)
		return index, true
	end
	if select(2, GetNumMacros()) >= (MAX_CHARACTER_MACROS or 18) then
		say("your character macros are full.")
		return
	end
	return CreateMacro(name, DYNAMIC_ICON, body, true), false
end

local function createMacro()
	local slot = hoveredSlot()
	local spellID
	if slot then
		local actionType, id = GetActionInfo(slot)
		if actionType ~= "spell" then
			say("that button isn't a spell.")
			return
		end
		spellID = id
	else
		spellID = tooltipSpell()
	end
	-- not hovering a spell: stay quiet, ctrl+alt also starts other key combos
	if not spellID then return end
	if InCombatLockdown() then
		say("can't make macros in combat, try again after.")
		return
	end

	local spellName = C_Spell.GetSpellName(spellID)
	if not spellName then return end
	local body = buildBody(spellName)
	if #body > MACRO_BODY_MAX then
		say("the macro would be too long, shorten your template.")
		return
	end

	local index, updated = saveMacro(spellName, body)
	if not index then return end

	if slot then
		-- the spell that was there ends up on the cursor, drop it
		PickupMacro(index)
		PlaceAction(slot)
		ClearCursor()
	else
		PickupMacro(index)
	end
	say((updated and "updated" or "made") .. " the " .. spellName .. " macro.")
end

-- Options panel ----------------------------------------------------------------

-- start hidden! if it's visible at login the edit box grabs the keyboard and
-- escape stops opening the game menu
local panel = CreateFrame("Frame")
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("One Tap Macro")

local intro = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
intro:SetPoint("RIGHT", -16, 0)
intro:SetJustifyH("LEFT")
intro:SetText("Hover a spell on your bars or in the spellbook and press Ctrl and Alt together. On a bar the macro replaces the spell, from the spellbook it lands on your cursor.")

local templateLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
templateLabel:SetPoint("TOPLEFT", 16, -90)
templateLabel:SetText("Template")

local templateHint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
templateHint:SetPoint("TOPLEFT", templateLabel, "BOTTOMLEFT", 0, -6)
templateHint:SetText("{spell} gets replaced with the spell's name. Macros can be 255 characters at most.")

local templateBox = CreateFrame("ScrollFrame", nil, panel, "InputScrollFrameTemplate")
templateBox:SetPoint("TOPLEFT", templateHint, "BOTTOMLEFT", 6, -12)
templateBox:SetSize(400, 120)
templateBox.EditBox:SetWidth(templateBox:GetWidth() - 18)
templateBox.EditBox:SetMaxLetters(MACRO_BODY_MAX)
templateBox.EditBox:SetAutoFocus(false)
templateBox.EditBox:SetScript("OnTextChanged", function(self, userInput)
	if userInput then
		OneTapMacroDB.template = self:GetText()
	end
end)
templateBox.EditBox:SetScript("OnEscapePressed", templateBox.EditBox.ClearFocus)

local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetButton:SetPoint("TOPLEFT", templateBox, "BOTTOMLEFT", -6, -12)
resetButton:SetText("Reset template")
resetButton:SetSize(resetButton:GetTextWidth() + 24, 22)
resetButton:SetScript("OnClick", function()
	OneTapMacroDB.template = DEFAULT_TEMPLATE
	templateBox.EditBox:SetText(DEFAULT_TEMPLATE)
end)

panel:SetScript("OnShow", function()
	templateBox.EditBox:SetText(OneTapMacroDB.template)
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, "One Tap Macro")
Settings.RegisterAddOnCategory(category)

-- Setup ------------------------------------------------------------------------

-- fires once per press: both down makes the macro, and nothing happens again
-- until one of them is let go
local armed = true

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("MODIFIER_STATE_CHANGED")
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		OneTapMacroDB = OneTapMacroDB or {}
		if not OneTapMacroDB.template or OneTapMacroDB.template == OLD_DEFAULT_TEMPLATE then
			OneTapMacroDB.template = DEFAULT_TEMPLATE
		end
		-- bindings can't change in combat, e.g. a /reload mid-fight
		local oldKeys = InCombatLockdown() and {} or { GetBindingKey(OLD_BIND) }
		for _, key in ipairs(oldKeys) do
			SetBinding(key)
		end
		if #oldKeys > 0 then
			SaveBindings(GetCurrentBindingSet())
		end
		return
	end

	local both = IsControlKeyDown() and IsAltKeyDown() and not IsShiftKeyDown()
	if both and armed then
		armed = false
		createMacro()
	elseif not both then
		armed = true
	end
end)

SLASH_ONETAPMACRO1 = "/otm"
SlashCmdList.ONETAPMACRO = function()
	Settings.OpenToCategory(category:GetID())
end
