--[[
File: init.lua

Initialisations
Module loading
Glue
]]

local world_path = minetest.get_worldpath()
s_protect = {}
s_protect.share = {}
s_protect.mod_path = minetest.get_modpath("simple_protection")
s_protect.conf      = world_path.."/s_protect.conf"
s_protect.file      = world_path.."/s_protect.data"
s_protect.sharefile = world_path.."/s_protect_share.data"

-- INTTLIB SUPPORT START
s_protect.gettext = function(rawtext, replacements, ...)
	replacements = {replacements, ...}
	local text = rawtext:gsub("@(%d+)", function(n)
		return replacements[tonumber(n)]
	end)
	return text
end

if minetest.global_exists("intllib") then
	if intllib.make_gettext_pair then
		s_protect.gettext = intllib.make_gettext_pair()
	else
		s_protect.gettext = intllib.Getter()
	end
end
local S = s_protect.gettext
-- INTTLIB SUPPORT END

minetest.register_privilege("simple_protection", S("Allows to modify and delete protected areas"))

dofile(s_protect.mod_path.."/misc_functions.lua")
s_protect.load_config()

dofile(s_protect.mod_path.."/command_mgr.lua")
dofile(s_protect.mod_path.."/database_raw.lua")
minetest.after(0.5, s_protect.load_db)

dofile(s_protect.mod_path.."/protection.lua")
dofile(s_protect.mod_path.."/hud.lua")
dofile(s_protect.mod_path.."/radar.lua")
dofile(s_protect.mod_path.."/chest.lua")
