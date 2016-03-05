minetest.after(1, function()
	simple_protection.load_claims()
	simple_protection.load_shareall()
end)

simple_protection.old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, player_name)
	if simple_protection.can_access(pos, player_name) then
		return simple_protection.old_is_protected(pos, player_name)
	end
	return true
end

simple_protection.old_item_place = minetest.item_place
minetest.item_place = function(itemstack, placer, pointed_thing)
	local player_name = placer:get_player_name()
	--local under_node = minetest.get_node(pointed_thing.under)

	-- if rightclick on special nodes
	--[[if not placer:get_player_control().sneak then
		if minetest.registered_nodes[under_node.name] and minetest.registered_nodes[under_node.name].on_rightclick then
			minetest.registered_nodes[under_node.name].on_rightclick(pos, node, placer, itemstack, pointed_thing)
			return itemstack
		end
	end]]

	if simple_protection.can_access(pointed_thing.above, player_name) or not minetest.registered_nodes[itemstack:get_name()] then
		return simple_protection.old_item_place(itemstack, placer, pointed_thing)
	else
		local data = simple_protection.get_data(pointed_thing.above)
		minetest.chat_send_player(player_name, "Area owned by: "..data.owner)
		return itemstack
	end
end

simple_protection.hud_time = 0
simple_protection.player_huds = {}

minetest.register_globalstep(function(dtime)
	simple_protection.hud_time = simple_protection.hud_time + dtime
	if simple_protection.hud_time < 3 then
		return
	end
	simple_protection.hud_time = 0
	-- get players
	local shared = simple_protection.share
	for _,player in ipairs(minetest.get_connected_players()) do
		local pos = vector.round(player:getpos())
		local player_name = player:get_player_name()

		local current_owner = ""
		local data = simple_protection.get_data(pos)
		if data then
			current_owner = data.owner
		end

		local has_access = (current_owner == player_name)
		if not has_access and data then
			has_access = table_contains(data.shared, player_name)
		end
		if not has_access then
			has_access = table_contains(shared[current_owner], player_name)
		end
		local changed = true

		if simple_protection.player_huds[player_name] then
			if simple_protection.player_huds[player_name].owner == current_owner and
				simple_protection.player_huds[player_name].had_access == has_access then
				-- still the same hud
				changed = false
			end
		end

		if simple_protection.player_huds[player_name] and changed then
			player:hud_remove(simple_protection.player_huds[player_name].hudID)
			simple_protection.player_huds[player_name] = nil
		end

		if current_owner ~= "" and changed then
			-- green if access
			local color = 0xFFFFFF
			if has_access then
				color = 0x00CC00
			end
			simple_protection.player_huds[player_name] = {
				hudID = player:hud_add({
					hud_elem_type	= "text",
					name			= "area_hud",
					number			= color,
					position		= {x=0.15, y=0.97},
					text			= "Area owner: "..current_owner,
					scale			= {x=100,y=25},
					alignment		= {x=0, y=0},
				}),
				owner = current_owner,
				had_access = has_access
			}
		end
	end
end)

minetest.register_craftitem("simple_protection:claim", {
	description = "Claim stick",
	inventory_image = "simple_protection_claim.png",
	stack_max = 10,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		local player_name = user:get_player_name()
		local pos = pointed_thing.under
		if simple_protection.old_is_protected(pos, player_name) then
			minetest.chat_send_player(player_name, "Area is already protected by an other protection mod.")
			return
		end
		if not simple_protection.underground_claim then
			local y = simple_protection.get_y_axis(pos.y)
			if y < simple_protection.underground_limit then
				minetest.chat_send_player(player_name, "You can not claim areas under "..simple_protection.underground_limit.."m")
				return
			end
		end
		local area_pos = simple_protection.get_location(pos)
		local data = simple_protection.claims[area_pos]
		if data then
			minetest.chat_send_player(player_name, "Area already owned by: "..data.owner)
			return
		end
		itemstack:take_item(1)
		simple_protection.claims[area_pos] = {owner=player_name, shared={}}
		simple_protection.save()

		minetest.add_entity(simple_protection.get_center(pos), "simple_protection:marker")
		minetest.chat_send_player(player_name, "Congratulations! You now own this area.")
		return itemstack
	end,
})

minetest.register_craft({
	output = "simple_protection:claim",
	recipe = {
		{"default:copper_ingot", "default:steel_ingot", "default:copper_ingot"},
		{"default:steel_ingot", "default:stonebrick", "default:steel_ingot"},
		{"default:copper_ingot", "default:steel_ingot", "default:copper_ingot"},
	}
})

minetest.register_entity("simple_protection:marker",{
	initial_properties = {
		hp_max = 1,
		visual = "wielditem",
		visual_size = {x=1.0/1.5,y=1.0/1.5},
		physical = false,
		textures = {"simple_protection:mark"},
	},
	on_activate = function(self, staticdata, dtime_s)
		minetest.after(10, function()
			self.object:remove()
		end)
	end,
})

-- hacky - I'm not a regular node!
local size = simple_protection.claim_size / 2
minetest.register_node("simple_protection:mark", {
	tiles = {"simple_protection_marker.png"},
	groups = {dig_immediate=3, not_in_creative_inventory=1},
	drop = "",
	use_texture_alpha = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-size-.5, -size-.5, -size-.5,	-size-.5, size+.5,  size-.5},
			{-size-.5, -size-.5,  size-.5,	 size-.5, size+.5,  size-.5},
			{ size-.5, -size-.5, -size-.5,	 size-.5, size+.5,  size-.5},
			{-size-.5, -size-.5, -size-.5,	 size-.5, size+.5, -size-.5},
		},
	},
})