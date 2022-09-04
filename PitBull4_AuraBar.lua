local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_AuraBar requires PitBull4")
end

local L = PitBull4.L

local PitBull4_AuraBar = PitBull4:NewModule("AuraBar")

PitBull4_AuraBar:SetModuleType("bar_provider")
PitBull4_AuraBar:SetName("AuraBar")
PitBull4_AuraBar:SetDescription("AuraBar")
PitBull4_AuraBar:SetDefaults({
	enabled = false,
	first = true,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function()
	PitBull4_AuraBar:UpdateAll()
end)

function PitBull4_AuraBar:OnEnable()
	timerFrame:Show()
end


function PitBull4_AuraBar:OnDisable()
	timerFrame:Hide()
end



function PitBull4_AuraBar:OnNewLayout(layout)
	local layout_db = self.db.profile.layouts[layout]
	
	if layout_db.first then
		layout_db.first = false
		local default_bar = layout_db.elements[L["Default"]]
		default_bar.exists = true
	end
end



function PitBull4_AuraBar:GetValue(frame, bar_db)
	if not frame.unit or not bar_db.aura then return end
	local _, name, duration, expirationTime, source
	if bar_db.friend and UnitIsFriend("player", frame.unit) or  bar_db.enemy and not UnitIsFriend("player", frame.unit) then
		name , _, _, _, _, duration, expirationTime, source = UnitBuff(frame.unit, bar_db.aura, true)
		if not name then 
			name , _, _, _, _, duration, expirationTime, source = UnitDebuff(frame.unit, bar_db.aura, true)
		end
	else
		return nil
	end	
	
	if not name then
		return not bar_db.hide and 0	-- buff not found, maybe hide when empty
	end
	
	if  not bar_db.all and source~="player" then
		return not bar_db.hide and 0
	end
	
	if expirationTime == 0 or duration == 0 then -- buff with unlimited duration
		return 1
	end
	
	local time_left = expirationTime-GetTime()
	if not bar_db.truncate or  bar_db.truncate == 0 then
		return time_left / duration
	else
		return math.min(time_left / bar_db.truncate, 1)
	end
end



function PitBull4_AuraBar:GetExampleValue(frame, bar_db)
	return 1
end


function PitBull4_AuraBar:GetColor(frame, bar_db, value)	
	if value < (bar_db.red or 0) then return 1,0,0 end
	if value < (bar_db.yellow or 0) then return 1,1,0 end
	return 0,1,0
end
 
 
PitBull4_AuraBar:SetLayoutOptionsFunction(function(self)
	return 'watch', {
		type = 'input',
		name = "Aura to watch",
		desc = "Insert the name of the buff you want to watch here",
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.aura
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.aura = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	},
	
	'trunc', {
		type = "range",
		name = "Truncate buff duration",
		desc = "Use this slider, to define the lenght of the bar in seconds. Additional time will be truncated. 0 means max duration of the buff",
		min = 0,
		max = 3600,
		step = 1,
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.truncate or 0
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.truncate = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	},
	
	"all_auras", {
		type = "toggle",
		name = "Show auras of other players.",
		desc = "Check this, to show the AuraBar for all buffs instead of those you own.",
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.all
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.all = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	},
	
	"show_friend", {
		type = "toggle",
		name = "Show on friendlies",
		desc = "Check this, to show the AuraBar on friendlies.",
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.friend
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.friend = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	},
	
	"show_enemy", {
		type = "toggle",
		name = "Show on enemies",
		desc = "Check this, to show the AuraBar on enemies.",
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.enemy
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.enemy = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	},
	
	"hide_empty", {
		type = "toggle",
		name = "Hide empty bar",
		desc = "Check this, to hide the AuraBar if empty.",
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.hide
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.hide = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	},
	
	'yellow_upper', {
		type = "range",
		name = "Upper bound for yellow region",
		desc = "Below this fraction of the total bar length, the bar turns to yellow if custom colors are NOT activated.",
		min = 0,
		max = 1,
		step = 0.01,
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.yellow or 0
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.yellow = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	},
	
	'red_upper', {
		type = "range",
		name = "Upper bound for red region",
		desc = "Below this fraction of the total bar length, the bar turns to red if custom colors are NOT activated.",
		min = 0,
		max = 1,
		step = 0.01,
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.red or 0
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.red = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	}
end)

