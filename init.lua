-- Based on ideas of the LandRush mod
-- Created by Krock
-- License: WTFPL

local world_path = minetest.get_worldpath()
simple_protection = {}
simple_protection.claims = {}
simple_protection.share = {}
simple_protection.mod_path = minetest.get_modpath("simple_protection")
simple_protection.conf = world_path.."/s_protect.conf"
simple_protection.file = world_path.."/s_protect.data"
simple_protection.sharefile = world_path.."/s_protect_share.data"

dofile(simple_protection.mod_path.."/functions.lua")
simple_protection.load_config()
dofile(simple_protection.mod_path.."/protection.lua")

minetest.register_on_protection_violation(function(pos, player_name)
	minetest.chat_send_player(player_name, "Do not try to modify this area!")
	--PUNISH HIM!!!!
	
	--local player = minetest.get_player_by_name(player_name)
	--player:set_hp(player:get_hp() - 1)
end)

minetest.register_privilege("simple_protection", "Allows to modify and delete protected areas")

minetest.register_chatcommand("area", {
	description = "Manages all of your areas.",
	privs = {interact=true},
	func = function(name, param)
		if param == "" then
			minetest.chat_send_player(name, "Available area commands:")
			minetest.chat_send_player(name, "Information about current area: /area show")
			minetest.chat_send_player(name, "(Un)share one area: /area (un)share <name>")
			minetest.chat_send_player(name, "(Un)share all areas: /area (un)shareall <name>")
			minetest.chat_send_player(name, "Unclaim this area: /area unclaim")
			return
		end
		if param == "show" or param == "unclaim" then
			simple_protection["command_"..param](name)
			return
		end
		-- all other commands
		local args = param:split(" ")
		if #args ~= 2 then
			minetest.chat_send_player(name, "Error: Please check again '/area' for correct usage.")
			return
		end
		if args[1] == "share" or args[1] == "unshare" or
			args[1] == "shareall" or args[1] == "unshareall" then
			simple_protection["command_"..args[1]](name, args[2])
		else
			minetest.chat_send_player(name, "Error: No known argument for #1 '"..args[1].."'")
		end
	end,
})

simple_protection.command_show = function(name)
	local player = minetest.get_player_by_name(name)
	local player_pos = vector.round(player:getpos())
	local data = simple_protection.get_data(player_pos)
	
	minetest.add_entity(simple_protection.get_center(player_pos), "simple_protection:marker")
	local axis = simple_protection.get_y_axis(player_pos.y)
	minetest.chat_send_player(name, "Vertical area limit from Y "..axis.." to "..(axis+simple_protection.claim_heigh))
	if not data then
		if axis < simple_protection.underground_limit then
			minetest.chat_send_player(name, "Area status: Not claimable")
		else
			minetest.chat_send_player(name, "Area status: Unowned (!)")
		end
		return
	end
	
	minetest.chat_send_player(name, "Area status: Owned by "..data.owner)
	local text = ""
	for i, player in ipairs(data.shared) do
		text = text..player..", "
	end
	local shared = simple_protection.share[data.owner]
	if shared then
		for i, player in ipairs(shared) do
			text = text..player.."*, "
		end
	end
	if text ~= "" then
		minetest.chat_send_player(name, "Players with access: "..text)
	end
end

simple_protection.command_share = function(name, param)
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
	local player_pos = vector.round(player:getpos())
	local pos = simple_protection.get_location(player_pos)
	local data = simple_protection.claims[pos]
	if not data then
		minetest.chat_send_player(name, "You do not own this area.")
		return
	end
	if name ~= data.owner and not minetest.check_player_privs(name, {simple_protection=true}) then
		minetest.chat_send_player(name, "You do not own this area.")
		return
	end
	local shared = simple_protection.share[name]
	if shared and shared[param] then
		minetest.chat_send_player(name, param.." already has access to all your areas.")
		return
	end
	
	if table_contains(data.shared, param) then
		minetest.chat_send_player(name, param.." already has access to this area.")
		return
	end
	table.insert(data.shared, param)
	simple_protection.save()
	minetest.chat_send_player(name, param.." has now access to this area.")
	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, name.." shared an area with you.")
	end
end

simple_protection.command_unshare = function(name, param)
	if name == param then return end
	local player = minetest.get_player_by_name(name)
	local player_pos = vector.round(player:getpos())
	local pos = simple_protection.get_location(player_pos)
	local data = simple_protection.claims[pos]
	if not data then
		minetest.chat_send_player(name, "You do not own this area.")
		return
	end
	if name ~= data.owner and not minetest.check_player_privs(name, {simple_protection=true}) then
		minetest.chat_send_player(name, "You do not own this area.")
		return
	end
	if not table_contains(data.shared, param) then
		minetest.chat_send_player(name, "This player has no access to this area.")
		return
	end
	table_delete(data.shared, param)
	simple_protection.save()
	minetest.chat_send_player(name, param.." has no longer access to this area.")
	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, name.." unshared an area with you.")
	end
end

simple_protection.command_shareall = function(name, param)
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
	
	local shared = simple_protection.share[name]
	if table_contains(shared, param) then
		minetest.chat_send_player(name, param.." already has now access to all your areas.")
		return
	end
	if not shared then
		simple_protection.share[name] = {}
	end
	table.insert(simple_protection.share[name], param)
	simple_protection.save()
	minetest.chat_send_player(name, param.." has now access to all your areas.")
	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, name.." shared all areas with you.")
	end
end

simple_protection.command_unshareall = function(name, param)
	if name == param then return end
	local removed = false
	local shared = simple_protection.share[name]
	if table_delete(shared, param) then
		removed = true
	end
	
	--loops everywhere
	for pos, data in pairs(simple_protection.claims) do
		if data.owner == name then
			if table_delete(data.shared, param) then
				removed = true
			end
		end
	end
	simple_protection.save()
	if not removed then
		minetest.chat_send_player(name, param.." did not have access to any of your areas.")
		return
	end
	minetest.chat_send_player(name, param.." has no longer access to your areas.")
	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, name.." unshared all areas with you.")
	end
end

simple_protection.command_unclaim = function(name)
	local player = minetest.get_player_by_name(name)
	local player_pos = vector.round(player:getpos())
	local pos = simple_protection.get_location(player_pos)
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
end