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

local tex_mod = "^[colorize:#FF2:50"
minetest.register_node("simple_protection:chest", {
	description = S("Shared Chest") .. " " .. S("(by protection)"),
	tiles = {
		"default_chest_top.png"  .. tex_mod,
		"default_chest_top.png"  .. tex_mod,
		"default_chest_side.png" .. tex_mod,
		"default_chest_side.png" .. tex_mod,
		"default_chest_side.png" .. tex_mod,
		"default_chest_lock.png" .. tex_mod
	},
	paramtype2 = "facedir",
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 2, oddly_breakable_by_hand = 2},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Shared Chest"))
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

minetest.register_craft({
	type = "shapeless",
	output = "simple_protection:shared_chest",
	recipe = { "simple_protection:claim", "default:chest_locked" }
})

minetest.register_craft({
	type = "shapeless",
	output = "simple_protection:shared_chest",
	recipe = { "simple_protection:claim", "default:chest" }
})