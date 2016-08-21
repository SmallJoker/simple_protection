-- Based on ideas of the LandRush mod
-- Created by Krock
-- License: WTFPL

local world_path = minetest.get_worldpath()
s_protect = {}
s_protect.claims = {}
s_protect.share = {}
s_protect.mod_path = minetest.get_modpath("simple_protection")
s_protect.conf = world_path.."/s_protect.conf"
s_protect.file = world_path.."/s_protect.data"
s_protect.sharefile = world_path.."/s_protect_share.data"

-- INTTLIB SUPPORT START
s_protect.gettext = function(rawtext, replacements, ...)
	replacements = {replacements, ...}
	return rawtext:gsub("@(%d+)", function(n)
		return replacements[tonumber(n)]
	end)
end

if minetest.get_modpath("intllib") then
    s_protect.gettext = intllib.Getter()
end

-- Function to insert words without translating
s_protect.gettext_replace = function(rawtext, replacement, ...)
	return s_protect.gettext(rawtext, ...):gsub("[$]", replacement)
end
local S = s_protect.gettext
local SR = s_protect.gettext_replace
-- INTTLIB SUPPORT END


dofile(s_protect.mod_path.."/functions.lua")
s_protect.load_config()
dofile(s_protect.mod_path.."/protection.lua")

minetest.register_on_protection_violation(function(pos, player_name)
	minetest.chat_send_player(player_name, S("Do not try to modify this area!"))
	--PUNISH HIM!!!!

	--local player = minetest.get_player_by_name(player_name)
	--player:set_hp(player:get_hp() - 1)
end)

minetest.register_privilege("simple_protection", S("Allows to modify and delete protected areas"))

minetest.register_chatcommand("area", {
	description = S("Manages all of your areas."),
	privs = {interact = true},
	func = function(name, param)
		if param == "" then
			local function chat_send(text, raw_text)
				if raw_text then
					raw_text = ": "..raw_text
				end
				minetest.chat_send_player(name, S(text).." "..(raw_text or ""))
			end
			chat_send("Available area commands:")
			chat_send("Information about this area", "/area show")
			chat_send("(Un)share one area",  "/area (un)share <name>")
			chat_send("(Un)share all areas", "/area (un)shareall <name>")
			chat_send("Unclaim this area",   "/area unclaim")
			return
		end
		if param == "show" or param == "unclaim" then
			return s_protect["command_"..param](name)
		end
		-- all other commands
		local args = param:split(" ")
		if #args ~= 2 then
			return false, S("Invalid number of arguments. Check '/area' for correct usage.")
		end
		if args[1] == "share" or args[1] == "unshare" or
			args[1] == "shareall" or args[1] == "unshareall" then
			return s_protect["command_"..args[1]](name, args[2])
		end

		return false, SR("Unknown command parameter: $", args[1])
	end,
})

s_protect.command_show = function(name)
	local player = minetest.get_player_by_name(name)
	local player_pos = vector.round(player:getpos())
	local data = s_protect.get_data(player_pos)

	minetest.add_entity(s_protect.get_center(player_pos), "simple_protection:marker")
	local axis = s_protect.get_y_axis(player_pos.y)
	local y_end = axis + s_protect.claim_height
	minetest.chat_send_player(name, S("Vertical area limit from Y @1 to @2",
			tostring(axis), tostring(y_end)))

	if not data then
		if axis < s_protect.underground_limit then
			return true, S("Area status: @1", "Not claimable")
		end
		return true, S("Area status: @1", "Unowned (!)")
	end

	minetest.chat_send_player(name, SR("Area status: @1", data.owner, "Owned by $"))
	local text = ""
	for i, player in ipairs(data.shared) do
		text = text..player..", "
	end
	local shared = s_protect.share[data.owner]
	if shared then
		for i, player in ipairs(shared) do
			text = text..player.."*, "
		end
	end

	if text ~= "" then
		return true, SR("Players with access: $", text)
	end
end

s_protect.command_share = function(name, param)
	if name == param or param == "" then
		return false, S("No player name given.")
	end
	if not minetest.auth_table[param] and param ~= "*all" then
		return false, S("Unknown player.")
	end

	local player = minetest.get_player_by_name(name)
	local data = s_protect.get_data(player:getpos())
	if not data then
		return false, S("This area is not claimed yet.")
	end
	if name ~= data.owner and not minetest.check_player_privs(name, {s_protect=true}) then
		return false, S("You do not own this area.")
	end
	local shared = s_protect.share[name]
	if shared and shared[param] then
		return true, SR("$ already has access to all your areas.", param)
	end

	if table_contains(data.shared, param) then
		return true, SR("$ already has access to this area.", param)
	end
	table.insert(data.shared, param)
	s_protect.save()

	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, SR("$ shared an area with you.", name))
	end
	return true, SR("$ has now access to this area.", param)
end

s_protect.command_unshare = function(name, param)
	if name == param or param == "" then
		return false, S("No player name given.")
	end
	local player = minetest.get_player_by_name(name)
	local data = s_protect.get_data(player:getpos())
	if not data then
		return false, S("This area is not claimed yet.")
	end
	if name ~= data.owner and not minetest.check_player_privs(name, {simple_protection=true}) then
		return false, S("You do not own this area.")
	end
	if not table_contains(data.shared, param) then
		return true, S("That player has no access to this area.")
	end
	table_delete(data.shared, param)
	s_protect.save()

	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, SR("$ unshared an area with you.", name))
	end
	return true, SR("$ has no longer access to this area.", param)
end

s_protect.command_shareall = function(name, param)
	if name == param or param == "" then
		return false, S("No player name given.")
	end
	if not minetest.auth_table[param] then
		if param == "*all" then
			return false, S("You can not share all your areas with everybody.")
		end
		return false, S("Unknown player.")
	end

	local shared = s_protect.share[name]
	if table_contains(shared, param) then
		return true, SR("$ already has now access to all your areas.", param)
	end
	if not shared then
		s_protect.share[name] = {}
	end
	table.insert(s_protect.share[name], param)
	s_protect.save()

	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, SR("$ shared all areas with you.", name))
	end
	return true, SR("$ has now access to all your areas.", param)
end

s_protect.command_unshareall = function(name, param)
	if name == param then return end
	local removed = false
	local shared = s_protect.share[name]
	if table_delete(shared, param) then
		removed = true
	end

	-- Unshare each single claim
	for pos, data in pairs(s_protect.claims) do
		if data.owner == name then
			if table_delete(data.shared, param) then
				removed = true
			end
		end
	end
	if not removed then
		return false, SR("$ does not have access to any of your areas.", param)
	end
	s_protect.save()
	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, SR("$ unshared all areas with you.", name))
	end
	return true, SR("$ has no longer access to your areas.", param)
end

s_protect.command_unclaim = function(name)
	local player = minetest.get_player_by_name(name)
	local player_pos = vector.round(player:getpos())
	local pos = s_protect.get_location(player_pos)
	local data = s_protect.claims[pos]
	if not data then
		return false, S("You do not own this area.")
	end
	local privs = minetest.check_player_privs(name, {simple_protection=true})
	if name ~= data.owner and not priv then
		return false, S("You do not own this area.")
	end
	if not priv and s_protect.claim_return then
		local inv = player:get_inventory()
		if inv:room_for_item("main", "simple_protection:claim") then
			inv:add_item("main", "simple_protection:claim")
		end
	end
	s_protect.claims[pos] = nil
	s_protect.save()
	return true, S("This area is unowned now.")
end