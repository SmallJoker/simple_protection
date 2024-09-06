-- simple_protection initialization

if not minetest.get_translator then
	error("[simple_protection] Your Minetest version is no longer supported."
		.. " (version < 5.0.0)")
end

simple_protection = {}

local world_path = minetest.get_worldpath()
local sp = simple_protection
s_protect = sp -- Backwards compat

sp.mod_path  = minetest.get_modpath("simple_protection")
sp.conf      = world_path.."/s_protect.conf"

-- Raw backend paths
sp.file      = world_path.."/s_protect.data"
sp.sharefile = world_path.."/s_protect_share.data"


-- Translation functions
sp.S = minetest.get_translator("simple_protection")
sp.FS = function(...)
	return minetest.formspec_escape(sp.S(...))
end
sp.translator = sp.S -- TODO: Remove


-- Unify checks of what game we are under
if minetest.get_modpath("default") then
	sp.game_mode = "MTG" -- Minetest Game
elseif minetest.get_modpath("mcl_core") then
	sp.game_mode = "MCL" -- VoxeLibre / Mineclonia and any other similar fork
else
	sp.game_mode = "???"
end


minetest.register_privilege("simple_protection",
	sp.S("Allows to modify and delete protected areas"))

-- Load helper functions and configuration
dofile(sp.mod_path.."/misc_functions.lua")
sp.load_config()

-- Unify crafting items
sp.resource = {
	copper = "default:copper_ingot",
	steel = "default:steel_ingot",
	stonebrick = "default:stonebrick",
	chest = {
		-- Used in: chest.lua
		regular = "default:chest",
		locked = "default:chest_locked"
	},
}
if sp.game_mode == "MCL" then
	if minetest.get_modpath("mcl_copper") then
		sp.resource.copper = "mcl_copper:copper_ingot"
	else
		-- No copper, fallback to gold
		sp.resource.copper = "mcl_core:gold_ingot"
	end
	sp.resource.steel = "mcl_core:iron_ingot"
	sp.resource.stonebrick = "mcl_core:stonebrick"
	sp.resource.chest.regular = "mcl_chests:chest"
	-- There is no locked chest, fallback to trapped chest
	sp.resource.chest.locked = "mcl_chests:trapped_chest"
end

-- Load database functions
dofile(sp.mod_path.."/command_mgr.lua")

if sp.backend == "storage" then
	dofile(sp.mod_path.."/database_storage.lua")
else
	dofile(sp.mod_path.."/database_raw.lua")
end

-- Spread the load a bit
minetest.after(0.5, sp.load_db)

-- General things to make this mod friendlier
dofile(sp.mod_path.."/protection.lua")
dofile(sp.mod_path.."/hud.lua")
dofile(sp.mod_path.."/radar.lua")
dofile(sp.mod_path.."/chest.lua")
