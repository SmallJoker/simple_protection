--[[
File: protection.lua

Protection callback handler
Node placement checks
Claim Stick item definition
]]

local sp = simple_protection
local S = sp.translator

local function notify_player(pos, player_name)
	local data = sp.get_claim(pos)
	if not data and sp.claim_to_dig then
		minetest.chat_send_player(player_name, S("Please claim this area to modify it."))
	elseif not data then
		-- Access restricted by another protection mod. Not my job.
		return
	else
		minetest.chat_send_player(player_name, S("Area owned by: @1", data.owner))
	end
end

sp.old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, player_name)
	if sp.can_access(pos, player_name) then
		return sp.old_is_protected(pos, player_name)
	end
	return true
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
		if sp.old_is_protected(pos, player_name) then
			minetest.chat_send_player(player_name,
					S("This area is already protected by an other protection mod."))
			return
		end
		if sp.underground_limit then
			local minp, _ = sp.get_area_bounds(pos)
			if minp.y < sp.underground_limit then
				minetest.chat_send_player(player_name,
					S("You can not claim areas below @1.",
					sp.underground_limit .. "m"))
				return
			end
		end
		local data, index = sp.get_claim(pos)
		if data then
			minetest.chat_send_player(player_name,
					S("This area is already owned by: @1", data.owner))
			return
		end
		-- Count number of claims for this user
		local claims_max = sp.max_claims

		if minetest.check_player_privs(player_name, {simple_protection=true}) then
			claims_max = claims_max * 2
		end

		local _, count = sp.get_player_claims(player_name)
		if count >= claims_max then
			minetest.chat_send_player(player_name,
				S("You can not claim any further areas: Limit (@1) reached.",
				tostring(claims_max)))
			return
		end

		itemstack:take_item(1)
		sp.update_claims({
			[index] = {owner=player_name, shared={}}
		})

		minetest.add_entity(sp.get_center(pos), "simple_protection:marker")
		minetest.chat_send_player(player_name, S("Congratulations! You now own this area."))
		return itemstack
	end,
})
minetest.register_alias("simple_protection:claim_stick", "simple_protection:claim")
minetest.register_alias("claim_stick", "simple_protection:claim")

minetest.register_craft({
	output = "simple_protection:claim",
	recipe = {
		{sp.resource.copper, sp.resource.steel, sp.resource.copper},
		{sp.resource.steel, sp.resource.stonebrick, sp.resource.steel},
		{sp.resource.copper, sp.resource.steel, sp.resource.copper},
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
local size = sp.claim_size / 2
minetest.register_node("simple_protection:mark", {
	tiles = {"simple_protection_marker.png"},
	groups = {dig_immediate=3, not_in_creative_inventory=1},
	drop = "",
	use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "clip" or true,
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
