-- simple_protection initialization

if not minetest.get_translator then
	error("[simple_protection] Your Minetest version is no longer supported."
		.. " (version < 5.0.0)")
end


local world_path = minetest.get_worldpath()
s_protect = {}
s_protect.translator = minetest.get_translator("simple_protection")
s_protect.share = {}
s_protect.mod_path = minetest.get_modpath("simple_protection")
s_protect.conf      = world_path.."/s_protect.conf"
s_protect.file      = world_path.."/s_protect.data"
s_protect.sharefile = world_path.."/s_protect_share.data"

minetest.register_privilege("simple_protection",
	s_protect.translator("Allows to modify and delete protected areas"))

-- Load helper functions and configuration
dofile(s_protect.mod_path.."/misc_functions.lua")
s_protect.load_config()

-- Load database functions
dofile(s_protect.mod_path.."/command_mgr.lua")
dofile(s_protect.mod_path.."/database_raw.lua")
-- Spread the load a bit
minetest.after(0.5, s_protect.load_db)

-- General things to make this mod friendlier
dofile(s_protect.mod_path.."/protection.lua")
dofile(s_protect.mod_path.."/hud.lua")
dofile(s_protect.mod_path.."/radar.lua")
dofile(s_protect.mod_path.."/chest.lua")
