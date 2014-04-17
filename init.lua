-- Based on ideas of the LandRush mod
-- Created by Krock
-- License: WTFPL

if freeminer then
	minetest = freeminer
end

local world_path = minetest.get_worldpath()
simple_protection = {}
simple_protection.claims = {}
simple_protection.mod_path = minetest.get_modpath("simple_protection")
simple_protection.conf = world_path.."/s_protect.conf"
simple_protection.file = world_path.."/s_protect.data"

dofile(simple_protection.mod_path.."/functions.lua")
simple_protection.load_config()
dofile(simple_protection.mod_path.."/protection.lua")

minetest.register_on_protection_violation(function(pos, player_name)
	local player = minetest.get_player_by_name(player_name)
	if not player then
		return
	end
	
	minetest.chat_send_player(player_name, "Do not try to modify this area!")
	--PUNISH HIM!!!!
	
	--player:set_hp(player:get_hp() - 1)
end)

minetest.register_privilege("simple_protection", "Allows to modify and delete protected areas")
minetest.register_chatcommand("show_area", {
	description = "Shows up data of current area",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local pos = player:getpos()
		local data = simple_protection.get_data(pos)
		
		minetest.add_entity(simple_protection.get_center(pos), "simple_protection:marker")
		if not data then
			minetest.chat_send_player(name, "Nobody owns this area. Yet.")
			return
		end
		
		minetest.chat_send_player(name, "Area owned by: "..data.owner)
		local shared = ""
		for player, really in pairs(data.shared) do
			if really then
				shared = shared..player..", "
			end
		end
		if shared ~= "" then
			minetest.chat_send_player(name, "Players with access: "..shared)
		end
	end,
})

minetest.register_chatcommand("share_area", {
	description = "Shares current area with <name>",
	params = "<name>",
	privs = {interact=true},
	func = function(name, param)
		if name == param then return end
		if param == "" then
			minetest.chat_send_player(name, "No player name given.")
			return
		end
		if not minetest.auth_table[param] and param ~= "*all" then
			minetest.chat_send_player(name, "Unknown player.")
			return
		end
		
		local player = minetest.get_player_by_name(name)
		local pos = simple_protection.get_location(player:getpos())
		local data = simple_protection.claims[pos]
		if not data then
			minetest.chat_send_player(name, "You do not own this area.")
			return
		end
		if name ~= data.owner and not minetest.check_player_privs(name, {simple_protection=true}) then
			minetest.chat_send_player(name, "You do not own this area.")
			return
		end
		if data.shared[param] then
			minetest.chat_send_player(name, param.." already has access to this area.")
			return
		end
		simple_protection.claims[pos].shared[param] = true
		simple_protection.save()
		minetest.chat_send_player(name, param.." has now access to this area.")
		if minetest.get_player_by_name(param) then
			minetest.chat_send_player(param, name.." shared an area with you.")
		end
	end,
})

minetest.register_chatcommand("share_all_areas", {
	description = "Shares all your areas with <name>",
	params = "<name>",
	privs = {interact=true},
	func = function(name, param)
		if name == param then return end
		if param == "" then
			minetest.chat_send_player(name, "No player name given.")
			return
		end
		if not minetest.auth_table[param] then
			if param == "*all" then
				minetest.chat_send_player(name, "ERROR: I want to protect your areas!")
			else
				minetest.chat_send_player(name, "Unknown player.")
			end
			return
		end
		--loops everywhere
		for pos, data in pairs(simple_protection.claims) do
			if data.owner == name then
				data.shared[param] = true
			end
		end
		simple_protection.save()
		minetest.chat_send_player(name, param.." has now access to all your areas.")
		if minetest.get_player_by_name(param) then
			minetest.chat_send_player(param, name.." shared all areas with you.")
		end
	end,
})

minetest.register_chatcommand("unshare_area", {
	description = "Unshares current area with <name>",
	params = "<name>",
	privs = {interact=true},
	func = function(name, param)
		if name == param then return end
		local player = minetest.get_player_by_name(name)
		local pos = simple_protection.get_location(player:getpos())
		local data = simple_protection.claims[pos]
		if not data then
			minetest.chat_send_player(name, "You do not own this area.")
			return
		end
		if name ~= data.owner and not minetest.check_player_privs(name, {simple_protection=true}) then
			minetest.chat_send_player(name, "You do not own this area.")
			return
		end
		if not data.shared[param] then
			minetest.chat_send_player(name, "This player has no access to this area.")
			return
		end
		simple_protection.claims[pos].shared[param] = nil
		simple_protection.save()
		minetest.chat_send_player(name, param.." has no longer access to this area.")
		if minetest.get_player_by_name(param) then
			minetest.chat_send_player(param, name.." unshared an area with you.")
		end
	end,
})

minetest.register_chatcommand("unshare_all_areas", {
	description = "Unshares all your areas with <name>",
	params = "<name>",
	privs = {interact=true},
	func = function(name, param)
		if name == param then return end
		--loops everywhere
		for pos, data in pairs(simple_protection.claims) do
			if data.owner == name then
				data.shared[param] = nil
			end
		end
		simple_protection.save()
		minetest.chat_send_player(name, param.." has no longer access to your areas.")
		if minetest.get_player_by_name(param) then
			minetest.chat_send_player(param, name.." unshared all areas with you.")
		end
	end,
})

minetest.register_chatcommand("unclaim_area", {
	description = "Unclaims current area",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local pos = simple_protection.get_location(player:getpos())
		local data = simple_protection.claims[pos]
		if not data then
			minetest.chat_send_player(name, "You do not own this area.")
			return
		end
		local priv = minetest.check_player_privs(name, {simple_protection=true})
		if name ~= data.owner and not priv then
			minetest.chat_send_player(name, "You do not own this area.")
			return
		end
		if not priv and simple_protection.claim_return then
			local inv = player:get_inventory()
			if inv:room_for_item("main", "simple_protection:claim") then
				inv:add_item("main", "simple_protection:claim")
			end
		end
		simple_protection.claims[pos] = nil
		simple_protection.save()
		minetest.chat_send_player(name, "This area is unowned now.")
	end,
})