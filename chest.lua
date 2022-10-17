local sp = simple_protection
local S = sp.translator

-- A shared chest for simple_protection but works with other protection mods too

local function get_item_count(pos, player, count)
	local name = player and player:get_player_name()
	if not name or minetest.is_protected(pos, name) then
		return 0
	end
	return count
end

-- Just in case we are under MineClone
local default = rawget(_G, "default") or nil
if default == nil then
	default = rawget(_G, "mcl_sounds")
end

local tex_mod = "^[colorize:#FF2:50"
minetest.register_node("simple_protection:chest", {
	description = S("Shared Chest") .. " " .. S("(by protection)"),
	tiles = {
		"simple_protection_chest_top.png"  .. tex_mod,
		"simple_protection_chest_top.png"  .. tex_mod,
		"simple_protection_chest_side.png" .. tex_mod,
		"simple_protection_chest_side.png" .. tex_mod,
		"simple_protection_chest_side.png" .. tex_mod,
		"simple_protection_chest_lock.png" .. tex_mod
	},
	paramtype2 = "facedir",
	sounds = default.node_sound_wood_defaults(),
	groups = {
		-- Minetest Game
		choppy = 2, oddly_breakable_by_hand = 2,
		-- MineClone
		handy=1,axey=1, deco_block=1,
	},
	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 2.5,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Shared Chest"))
		if minetest.registered_items["default:dirt"] then
			meta:set_string("formspec",
				"size[8,9]" ..
				default.gui_bg ..
				default.gui_bg_img ..
				"list[context;main;0,0.3;8,4;]" ..
				"list[current_player;main;0,5;8,4;]" ..
				"listring[context;main]" ..
				"listring[current_player;main]"
			)
			local inv = meta:get_inventory()
			inv:set_size("main", 8*4)
		elseif minetest.registered_items["mcl_core:dirt"] then
			-- In MineClone they have a separate overlay of images for the inventory,
			-- This branch should setup the proper dimentions (9x3) instead of Minetest's fairly nice dimentions (8x4)
			local mcl_formspec = rawget(_G, "mcl_formspec") or nil
			meta:set_string("formspec",
				"size[9,8.75]"..
				"label[0,0;"..minetest.formspec_escape(minetest.colorize("#313131", "Shared Chest")).."]"..
				"list[context;main;0,0.5;9,3;]"..
				mcl_formspec.get_itemslot_bg(0,0.5,9,3)..
				"label[0,4.0;"..minetest.formspec_escape(minetest.colorize("#313131", S("Inventory"))).."]"..
				"list[current_player;main;0,4.5;9,3;9]"..
				mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
				"list[current_player;main;0,7.74;9,1;]"..
				mcl_formspec.get_itemslot_bg(0,7.74,9,1)..
				"listring[context;main]"..
				"listring[current_player;main]"
			)
			local inv = meta:get_inventory()
			inv:set_size("main", 9*3)
		end
	end,
	can_dig = function(pos, player)
		return minetest.get_meta(pos):get_inventory():is_empty("main")
	end,
	on_blast = function() end,

	allow_metadata_inventory_put = function(pos, fl, fi, stack, player)
		return get_item_count(pos, player, stack:get_count())
	end,
	allow_metadata_inventory_take = function(pos, fl, fi, stack, player)
		return get_item_count(pos, player, stack:get_count())
	end,
	allow_metadata_inventory_move = function(pos, fl, fi, tl, ti, count, player)
		return get_item_count(pos, player, count)
	end,
	on_metadata_inventory_put = function(pos, fl, fi, stack, player)
		minetest.log("action", player:get_player_name()
			.. " moves " .. stack:get_name() .. " to shared chest at "
			.. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, fl, fi, stack, player)
		minetest.log("action", player:get_player_name()
			.. " takes " .. stack:get_name() .. " from shared chest at "
			.. minetest.pos_to_string(pos))
	end,
	-- on_metadata_inventory_move logging is redundant: Same chest contents
})

-- If neither of these occur then the shared chest is just uncraftable
if minetest.registered_items["default:dirt"] then
	minetest.register_craft({
		type = "shapeless",
		output = "simple_protection:chest",
		recipe = { "simple_protection:claim", "default:chest_locked" }
	})

	minetest.register_craft({
		type = "shapeless",
		output = "simple_protection:chest",
		recipe = { "simple_protection:claim", "default:chest" }
	})
elseif minetest.registered_items["mcl_core:dirt"] then
	minetest.register_craft({
		type = "shapeless",
		output = "simple_protection:chest",
		recipe = { "simple_protection:claim", "mcl_chests:trapped_chest" }
	})

	minetest.register_craft({
		type = "shapeless",
		output = "simple_protection:chest",
		recipe = { "simple_protection:claim", "mcl_chests:chest" }
	})
end
