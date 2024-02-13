if not ptl then ChatFrame1:AddMessage("|cffff0000Translator Error: PyTemp not found!") return end
if not pylib then print("|cffff0000Translator Error: PyLib not found!") return end
local py_lib, py_timer, py_string, py_table, py_num, py_hash, py_color, py_hook, py_callback, py_item, py_helper = pylib.GetLibraries()

local me = {
	name = "Translator",
	version = "v1.0",
	path = "interface/addons/RoM-Translator",
	hooks = {},
	children = {
		-- loca
		{"loca", "/loca/langcore"},
	},
	config = {
		enabled = true,
		--events
		system = true,
		gm = true,
		say = true,
		zone = true,
		party = true,
		guild = true,
		yell = true,
		whisper = true,
		combat = true,
		channel = true,
		cmd = true,
		slash = true,
		--frames
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true,
		[7] = true,
		[8] = true,
		[9] = true,
		[10] = true,
	},
	lst = {
		frame = {types = {}},
		event = {types = {}},
	},
	Interface = {
		Filter = {
			event = {
				system = true,
				gm = true,
				cmd = true,
				say = true,
				zone = true,
				party = true,
				guild = true,
				yell = true,
				whisper = true,
				combat = true,
				channel = true,
				channelsub = {true, true, true, true, true, true, true, true},
				slash = true,
			},
			frame = {
				--frames
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = true,
				[7] = true,
				[8] = true,
				[9] = true,
				[10] = true,
			},
		},
	},
};
local events = {
	-- System
	CHAT_MSG_SYSTEM="system",
	CHAT_MSG_SYSTEM_VALUE="system",
	CHAT_MSG_SYSTEM_GET="system",

	-- GM
	CHAT_MSG_GM="gm",
	CHAT_MSG_GM_TALK="gm",

	--Combat Log
	CHAT_MSG_COMBAT="combat",
	CHAT_MSG_COMBAT_SELF="combat",

	CHAT_MSG_SAY="say",
	CHAT_MSG_ZONE="zone",
	CHAT_MSG_PARTY="party",
	CHAT_MSG_GUILD="guild",
	CHAT_MSG_YELL="yell",
	CHAT_MSG_RAID="party",

	--Whisper
	CHAT_MSG_WHISPER="whisper",
	CHAT_MSG_WHISPER_INFORM="whisper",
	CHAT_MSG_WHISPER_OFFLINE="whisper",
	
	--Private Channel
	CHAT_MSG_CHANNEL="channel", 
	--CHAT_MSG_CHANNEL_JOIN="channel",
	--CHAT_MSG_CHANNEL_LEAVE="channel",
}

me._Init = function(var)
	if not var then return end --after load of children
	py_lib.RegisterEventHandler("VARIABLES_LOADED", "Translator", me.LoadVars)
	py_lib.RegisterEventHandler("REGISTER_HOOKS", "Translator", me.SetHook)
	py_lib.RegisterEventHandler("UNREGISTER_HOOKS", "Translator", me.RemoveHook)
	for a, b in pairs(events) do
		py_lib.RegisterEventHandler(a, "Translator", me.HandleChatEvent)
	end
end
function me.RegisterWithAddonManager()
	if AddonManager and AddonManager.RegisterAddonTable then
		local addon={
			name = Translator.loca.GetText("name"),
			description = "Translator is a fork of AdvancedCopyChat.",
			author = "github.com/furkun/RoM-Translator",
			category="Interface",
			slashCommands="/tr",
			version = me.version,
			configFrame = Translator_Frame,
			icon = "interface\\addons\\RoM-Translator\\img\\icon.png",
			mini_icon = "interface\\addons\\RoM-Translator\\img\\icon.png",
		}
		AddonManager.RegisterAddonTable(addon)
		TranslatorMinimap:Hide()
	else
		TranslatorMinimap:Show()
		printf("|cffff9a00%s", sprintf(me.loca.GetText("loaded", "%s loaded!"), me.loca.GetText("name", me.name)))
	end
end

me.LoadVars = function()
	me.RegisterWithAddonManager()
	-- Save Vars
	TRANSLATOR_SETTINGS = TRANSLATOR_SETTINGS or {}
	for a,b in pairs(TRANSLATOR_SETTINGS) do
		me.config[a] = b
	end
	TRANSLATOR_SETTINGS = me.config
	SaveVariables("TRANSLATOR_SETTINGS")
	me.InitFrames()
end

me.SetHook = function()
	for i=1,10 do
		if _G["ChatFrame"..i] then
			py_hook.AddHook(sprintf("ChatFrame%d.AddMessage",i), "Translator", me.HandleChatFrame)
		end
	end
	py_hook.AddHook("SendChatMessage", "Translator", me.SendChatMessage)
	-- slash Commands
	for a, b in pairs(SlashCmdList) do
		if type(b)=="function" then
			me.hooks[a] = b
			SlashCmdList[a] = function(frame, msg) b(frame, msg) me.HandleSlashCommands(a, msg) end
		end
	end
end
me.RemoveHook = function()
	for i=1,10 do
		if _G["ChatFrame"..i] then
			py_hook.RemoveHook(sprintf("ChatFrame%d.AddMessage",i), "Translator")
		end
	end
	py_hook.RemoveHook("SendChatMessage", "Translator")
	for a, b in pairs(me.hooks) do
		if SlashCmdList[a] then
			SlashCmdList[a] = b
			me.hooks[a] = nil
		end
	end
end

me.InsertFrame = function(id, text)
	me.lst.frame.types[id] = true
	table.insert(me.lst.frame,1, {id, text})
	py_lib.SendEvent("Translator_InsertFrame", true, id)
end
me.InsertEvent = function(typ,sender, text, channel, event)
	me.lst.event.types[typ] = true
	local channelname = nil
	if typ=="channel" then
		me.lst.event.types[channel or 0] = true
		channelname = GetChannelName(channel or -1)
		channelname= channelname~="" and channelname or event
	else
		channelname = me.GetEventName(typ)
	end
	table.insert(me.lst.event,1, {typ, text or "",sender, channel, channelname})
	py_lib.SendEvent("Translator_InsertEvent", false, typ)
end
me.HandleChatFrame = function(nextfn, frame, text, ...) -- Add Message
	nextfn(frame, text, ...)
	local id = frame:GetID()
	if not me.config.enabled then return end
	if not me.config[id] then return end
	me.InsertFrame(id, text)
	
end
me.HandleChatEvent = function(event, text, link, channel, name, class, ...) -- Add Message
	local typ = events[event]
	if not me.config.enabled then return end
	if not me.config[typ] then return end
	me.InsertEvent(typ, name, text, channel, event)
	--[[
		arg1 -> Text
		arg2 -> Name + Link
		arg3 -> nil -> Channelnum
		arg4 -> Name
		arg5 -> class
	]]
end
me.HandleSlashCommands = function(script, msg)
	if not me.config.enabled then return end
	if not me.config.slash then return end
	me.InsertEvent("slash", script, msg, nil)
end
me.SendChatMessage = function(nextfn, txt, typ, ...)
	nextfn(txt, typ, ...)
	if typ=="GM" then
		if string.match(txt, "([^%s]+)") then
			me.InsertEvent("cmd", UnitName("player") or "", txt, nil)
		end
	end
end

-- UI
me.GetEventName = function(key)
	return me.loca.GetText("events."..tostring(key), key)
end
me.OnLoad = function(frame)
	local name = frame:GetName()
	me._Frame = frame
	me._Events = _G[name.."_Events"]
	me._Frames = _G[name.."_Frames"]
	me._Config = _G[name.."_Config"]
	me._Dropdown = _G[name.."_Dropdown"]
	me._Tabs = _G[name.."_Tabs"]
	UIDropDownMenu_Initialize(me._Dropdown, me.ShowDropdown)
	py_lib.RegisterEventHandler("Translator_InsertFrame", "Translator", me.InterfaceEvent)
	py_lib.RegisterEventHandler("Translator_InsertEvent", "Translator", me.InterfaceEvent)
end

me.InitFrames = function()
	me._Frame:SetTitle(me.loca.GetText("name", "CopyChat"))
	local def = {
		{VisibleOnShow=true, Text = me.loca.GetText("tab.Frame", "_Frames"), 	Frame=me._Frames, OnClick=me.FilterFramesList},
		{VisibleOnShow=false, Text = me.loca.GetText("tab.Event", "_Events"), 	Frame=me._Events, OnClick=me.FilterEventList},
		{VisibleOnShow=false, Text = me.loca.GetText("tab.Config", "_Config"), 	Frame=me._Config},
	}
	me._Tabs:Init(def)
	def = {
		OnClick = me.OnButtonClick,
		Text = me.loca.GetText("filter", "Filter"),
	}
	_G[me._Events:GetName().."_Filter"]:Init(def)
	_G[me._Frames:GetName().."_Filter"]:Init(def)
	
	def = {
		RepaintFn = me.RepaintEventList,
		
		NumRows = 13,
		Columns = {80,100,300},
		
		RowFn = {OnClick = me.OnListClicked, OnEnter = me.OnListEnter, OnLeave=me.OnListLeave},
		
		Head = {true,true,true,true,true,true, true, true},
		HeadFn = {OnClick = me.OnListClicked, OnEnter = me.OnListEnter, OnLeave=me.OnListLeave},
		
		Filter = {OnTextChangedFn = me.FilterEventList,nil, "sender", "text"},
	}
	_G[me._Events:GetName().."_List"]:Init(def)
	_G[me._Events:GetName().."_List"]._Head = {me.loca.GetText("event","Event"),me.loca.GetText("sender", "Sender"),me.loca.GetText("text", "Text")}
	_G[me._Events:GetName().."_List"]:Update()
	def = {
		RepaintFn = me.RepaintFramesList,
		
		NumRows = 13,
		Columns = {80,400},
		
		RowFn = {OnClick = me.OnListClicked, OnEnter = me.OnListEnter, OnLeave=me.OnListLeave},
		
		Head = {true,true,true,true,true,true, true, true},
		HeadFn = {OnClick = me.OnListClicked, OnEnter = me.OnListEnter, OnLeave=me.OnListLeave},
		
		Filter = {OnTextChangedFn = me.FilterFramesList,nil, "text"},
	}
	_G[me._Frames:GetName().."_List"]:Init(def)
	_G[me._Frames:GetName().."_List"]._Head = {me.loca.GetText("frame","Frame"), me.loca.GetText("text", "Text")}
	_G[me._Frames:GetName().."_List"]:Update()
	
	local config = me._Config:GetName()
	
	for a, b in pairs(me.config) do
		if type(a)=="number" then
			_G[config.."_Chat"..a]:Init({Text=sprintf(CHAT_NAME_TEMPLATE, a), Checked=b, OnClick=me.ConfigOnClick, OnEnter=me.ConfigOnEnter})
			_G[config.."_Chat"..a].key = a
		else
			_G[config.."_"..string.upper(a)]:Init({Text=a~="enabled" and me.GetEventName(a) or me.loca.GetText("config.enabled","_Enabled"), Checked=b, OnClick=me.ConfigOnClick, OnEnter=me.ConfigOnEnter})
			_G[config.."_"..string.upper(a)].key = a
		end
	end
end

me.ConfigOnClick = function(frame, key)
	me.config[frame.key] = frame:IsChecked()
end
me.ConfigOnEnter = function(frame)
	if frame:GetID()==2 then
		GameTooltip:Show();
		GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT", 0, 0);
		GameTooltip:SetText(_G["ChatFrame"..frame.key.."Tab"]:GetText())
		frame.__tt_show = true
	end
end

function RemoveColorCodes(text)
    -- Renk kodlarını temizle
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")  -- Başlangıç renk kodunu sil
    text = string.gsub(text, "|r", "")  -- Renk kodu bitiş işaretini sil
    return text
end

me.OnListClicked = function(button, index, column, frame, caller,...)
    if not(index and index>0) then return end
    local lst_frame = frame:GetParent():GetParent():GetParent()
    local lst = lst_frame._List
    if not lst then return end
    if button == "RBUTTON" then
        ToggleDropDownMenu(me._Dropdown, 1, {lst_frame, index, column}, caller:GetName(), 1 ,1 )
    elseif button=="LBUTTON" then
        local cleanedText = RemoveColorCodes(lst[index][column] or "")
		--StaticPopupDialogs["OPEN_WEBROWER"].link = linkData;
		--StaticPopup_Show("OPEN_WEBROWER");
		GC_OpenWebRadio("https://translate.google.com/?sl=auto&tl=auto&text=" ..  cleanedText)
    end
end


me.OnButtonClick = function(frame, key, typ)
	local id = frame:GetID()
	ToggleDropDownMenu(me._Dropdown, 1, id, frame:GetName(), 1 ,1 )
end

me.FilterEventList = function(...)
	local frame = _G[me._Events:GetName().."_List"]
	frame._List = {}
	local typ, text, sender, channel, channelname
	local typfilter = me.Interface.Filter.event
	local filter = frame:GetFilter()
	for _, data in ipairs(me.lst.event) do
		typ, text, sender, channel, channelname = unpack(data)
		if typfilter[typ] and (typ~="channel" or typfilter.channelsub[channel or 1]) 
			and (not filter.text or string.match(string.lower(text), string.lower(filter.text))) 
			and (not filter.sender or string.match(string.lower(sender), string.lower(filter.sender))) then
			table.insert(frame._List, {channelname, sender, text})
		end
	end
	frame:Update()
end
me.RepaintEventList = function(frame)
	return frame._List or {},frame._Head or {"_Event","_Sender","_Text"}, nil
end
me.FilterFramesList = function()
	local frame = _G[me._Frames:GetName().."_List"]
	frame._List = {}
	local typ, text
	local typfilter = me.Interface.Filter.frame
	local filter = frame:GetFilter()
	local names = {}
	for i=1,10 do
		names[i] = _G["ChatFrame"..i.."Tab"]:GetText()
	end
	for _, data in ipairs(me.lst.frame) do
		typ, text = unpack(data)
		if typfilter[typ] 
			and (not filter.text or string.match(string.lower(text), string.lower(filter.text))) then
			table.insert(frame._List, {names[typ], text})
		end
	end
	frame:Update()
end
me.RepaintFramesList = function(frame)
	return frame._List or {}, frame._Head or {"_Frame","_Text"}, nil
end

me.InterfaceEvent = function(event, isframe, typ)
	if not me._Frame:IsVisible() then return end
	if me._Frames:IsVisible() and isframe then 
		if me.Interface.Filter.frame[typ] then
			me.FilterFramesList()
		end
		return
	end
	
	if me._Events:IsVisible() and not isframe then 
		if me.Interface.Filter.event[typ] then
			me.FilterEventList()
		end
		return
	end
end

me.EventFilterDropdown = function()
	local filter = me.Interface.Filter.event
	local menuitem = {}
	if UIDROPDOWNMENU_MENU_LEVEL==1 then
		for name, active in pairs(filter) do
			if type(active)=="boolean" then
				menuitem.text = sprintf("%s (%s)", me.GetEventName(name), name or "")
				menuitem.checked = active
				menuitem.hasArrow = name=="channel"
				menuitem.value = UIDROPDOWNMENU_MENU_VALUE
				menuitem.func = function() filter[name] = not filter[name] me.FilterEventList() end
				local used = me.lst.event.types[name]
				local r,g,b = 1,1,1
				if not used then
					r,g,b = 0.5,0.5,0.5
				end
				menuitem.textR = r
				menuitem.textG = g
				menuitem.textB = b
				UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
			end
		end
	else
		filter = filter.channelsub
		for index, active in ipairs(filter) do
			menuitem.text = sprintf("%s (%d)", GetChannelName(index) or index, index)
			menuitem.checked = active
			menuitem.func = function() filter[index] = not filter[index] me.FilterEventList() end
			local used = me.lst.event.types[index]
			local r,g,b = 1,1,1
			if not used then
				r,g,b = 0.5,0.5,0.5
			end
			menuitem.textR = r
			menuitem.textG = g
			menuitem.textB = b
			UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
		end
	end
end

me.FrameFilterDropdown = function()
	local filter = me.Interface.Filter.frame
	local menuitem = {}
	for index, active in ipairs(filter) do
		menuitem.text = sprintf("%s (%d)", _G["ChatFrame"..index.."Tab"]:GetText(), index)
		menuitem.checked = active
		menuitem.func = function() filter[index] = not filter[index] me.FilterFramesList() end
		local visible = _G["ChatFrame"..index.."Tab"]:IsVisible() or _G["ChatFrame"..index]:IsVisible()
		local used = me.lst.frame.types[index]
		local r,g,b = 1,1,1
		if not used then
			r,g,b = 1,0,0
		end
		if not visible then
			r,g,b = math.max(0, r-0.4), math.max(0, g-0.4), math.max(0, b-0.4)
		end
		menuitem.textR = r
		menuitem.textG = g
		menuitem.textB = b
		UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
	end
end

me.ListCopy = function()
	if type(UIDROPDOWNMENU_MENU_VALUE)~="table" then return end
	local frame, index, column = unpack(UIDROPDOWNMENU_MENU_VALUE)
	local frameid = frame:GetID()
	local menuitem = {}
	menuitem.notCheckable = 1;
	menuitem.text = me.loca.GetText("copy.head","Copy")
	menuitem.isTitle = 1
	UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
	menuitem = {}
	menuitem.text = me.loca.GetText("copy.text","Copy Text")
	menuitem.func = function() Chat_CopyToClipboard(frameid==1 and frame._List[index][3] or frame._List[index][2] or "") end
	UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
	if frameid==1 then
		menuitem.text = me.loca.GetText("copy.sender","Copy Sender")
		menuitem.func = function() Chat_CopyToClipboard(frame._List[index][2] or "") end
		UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
	end
	menuitem.text = me.loca.GetText("copy.row","Copy Row")
	if frameid==1 then
		menuitem.func = function() Chat_CopyToClipboard(sprintf("%s - %s: %s", unpack(frame._List[index]))) end
	else
		menuitem.func = function() Chat_CopyToClipboard(sprintf("%s: %s", unpack(frame._List[index]))) end
	end
	UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
end
me.ShowDropdown = function()
	local menuitem = {}
	if UIDROPDOWNMENU_MENU_LEVEL==1 and type(UIDROPDOWNMENU_MENU_VALUE)=="number" then
		menuitem.notCheckable = 1;
		menuitem.text = me.loca.GetText("filter","Filter")
		menuitem.isTitle = 1
		UIDropDownMenu_AddButton(menuitem, UIDROPDOWNMENU_MENU_LEVEL);
	end
	if UIDROPDOWNMENU_MENU_VALUE==1 then -- Events
		me.EventFilterDropdown()
	elseif UIDROPDOWNMENU_MENU_VALUE==2 then -- Frames
		me.FrameFilterDropdown()
	else -- copy dropdown
		me.ListCopy()
	end
end

SLASH_AdvancedTR1= "/tr"
SlashCmdList["AdvancedTR"] = function (editBox, msg)
	ToggleUIFrame(Translator_Frame)
end
ptl.CreateTable(me, me.name, nil, _G) --Create Parent
