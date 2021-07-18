-- simple_protection initialization

if not minetest.get_translator then
	error("[simple_protection] Your Minetest version is no longer supported."
		.. " (version < 5.0.0)")
end

simple_protection = {}

local world_path = minetest.get_worldpath()
local sp = simple_protection
-- Backwards compat
s_protect = sp

sp.translator = minetest.get_translator("simple_protection")
sp.share = {}
sp.mod_path  = minetest.get_modpath("simple_protection")
sp.conf      = world_path.."/s_protect.conf"
sp.file      = world_path.."/s_protect.data"
sp.sharefile = world_path.."/s_protect_share.data"

local S = sp.translator

minetest.register_privilege("simple_protection",
	S("Allows to modify and delete protected areas"))

-- Load helper functions and configuration
dofile(sp.mod_path.."/misc_functions.lua")
sp.load_config()

-- Load database functions
dofile(sp.mod_path.."/command_mgr.lua")
dofile(sp.mod_path.."/database_raw.lua")
-- Spread the load a bit
minetest.after(0.5, sp.load_db)

-- General things to make this mod friendlier
dofile(sp.mod_path.."/protection.lua")
dofile(sp.mod_path.."/hud.lua")
dofile(sp.mod_path.."/radar.lua")
dofile(sp.mod_path.."/chest.lua")
