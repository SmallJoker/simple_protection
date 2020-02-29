--[[
File: protection.lua

Protection callback handler
Node placement checks
Claim Stick item definition
]]

local S = s_protect.gettext

local function notify_player(pos, player_name)
	local data = s_protect.get_claim(pos)
	if not data and s_protect.claim_to_dig then
		minetest.chat_send_player(player_name, S("Please claim this area to modify it."))
	elseif not data then
		-- Access restricted by another protection mod. Not my job.
		return
	else
		minetest.chat_send_player(player_name, S("Area owned by: @1", data.owner))
	end
end

s_protect.old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, player_name)
	if s_protect.can_access(pos, player_name) then
		return s_protect.old_is_protected(pos, player_name)
	end
	return true
end

local old_item_place = minetest.item_place
minetest.item_place = function(itemstack, placer, pointed_thing)
	local player_name = placer and placer:get_player_name() or ""

	if s_protect.can_access(pointed_thing.above, player_name)
			or not minetest.registered_nodes[itemstack:get_name()] then
		return old_item_place(itemstack, placer, pointed_thing)
	end

	notify_player(pointed_thing.above, player_name)
	return itemstack
end

minetest.register_on_protection_violation(notify_player)


minetest.register_craftitem("simple_protection:claim", {
	description = S("Claim Stick") .. " " .. S("(click to protect)"),
	inventory_image = "simple_protection_claim.png",
	stack_max = 10,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		local player_name = user:get_player_name()
		local pos = pointed_thing.under
		if s_protect.old_is_protected(pos, player_name) then
			minetest.chat_send_player(player_name,
					S("This area is already protected by an other protection mod."))
			return
		end
		if s_protect.underground_limit then
			local minp, maxp = s_protect.get_area_bounds(pos)
			if minp.y < s_protect.underground_limit then
				minetest.chat_send_player(player_name,
					S("You can not claim areas below @1.",
					s_protect.underground_limit .. "m"))
				return
			end
		end
		local data, index = s_protect.get_claim(pos)
		if data then
			minetest.chat_send_player(player_name,
					S("This area is already owned by: @1", data.owner))
			return
		end
		-- Count number of claims for this user
		local claims_max = s_protect.max_claims

		if minetest.check_player_privs(player_name, {simple_protection=true}) then
			claims_max = claims_max * 2
		end

		local claims, count = s_protect.get_player_claims(player_name)
		if count >= claims_max then
			minetest.chat_send_player(player_name,
				S("You can not claim any further areas: Limit (@1) reached.",
				tostring(claims_max)))
			return
		end

		itemstack:take_item(1)
		s_protect.update_claims({
			[index] = {owner=player_name, shared={}}
		})

		minetest.add_entity(s_protect.get_center(pos), "simple_protection:marker")
		minetest.chat_send_player(player_name, S("Congratulations! You now own this area."))
		return itemstack
	end,
})
minetest.register_alias("simple_protection:claim_stick", "simple_protection:claim")
minetest.register_alias("claim_stick", "simple_protection:claim")

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
local size = s_protect.claim_size / 2
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
