local sp = simple_protection
local S = sp.S

local commands = {}

function sp.register_subcommand(name, func)
	if commands[name] then
		minetest.log("info", "[simple_protection] Overwriting chat command " .. name)
	end

	assert(#name:split(" ") == 1, "Invalid name")
	assert(type(func) == "function")

	commands[name] = func
end

minetest.register_chatcommand("area", {
	description = S("Manages all of your areas."),
	privs = {interact = true},
	func = function(name, param)
		if param == "" or param == "help" then
			local function chat_send(desc, cmd)
				minetest.chat_send_player(name, desc .. ": "
					.. minetest.colorize("#0FF", cmd))
			end
			local privs = minetest.get_player_privs(name)
			minetest.chat_send_player(name, minetest.colorize("#0F0",
				"=> " .. S("Available area commands")))

			chat_send(S("Information about this area"), "/area show")
			chat_send(S("View of surrounding areas"), "/area radar")
			chat_send(S("(Un)share one area"), "/area (un)share <name>")
			chat_send(S("(Un)share all areas"), "/area (un)shareall <name>")
			if sp.area_list or privs.simple_protection then
				chat_send(S("List claimed areas"), "/area list [<name>]")
			end
			chat_send(S("Unclaim this area"), "/area unclaim")
			if privs.server then
				chat_send(S("Delete all areas of a player"), "/area delete <name>")
			end
			return
		end

		local args = param:split(" ", 2)
		local func = commands[args[1]]
		if not func then
			return false, S("Unknown command parameter: @1. Check '/area' for correct usage.", args[1])
		end

		return func(name, args[2])
	end,
})

sp.register_subcommand("show", function(name, param)
	local player = minetest.get_player_by_name(name)
	local player_pos = player:get_pos()
	local data = sp.get_claim(player_pos)

	minetest.add_entity(sp.get_center(player_pos), "simple_protection:marker")
	local minp, maxp = sp.get_area_bounds(player_pos)
	minetest.chat_send_player(name, S("Vertical from Y @1 to @2",
			tostring(minp.y), tostring(maxp.y)))

	if not data then
		if sp.underground_limit and minp.y < sp.underground_limit then
			return true, S("Area status: @1", S("Not claimable"))
		end
		return true, S("Area status: @1", S("Unowned (!)"))
	end

	minetest.chat_send_player(name, S("Area status: @1", S("Owned by @1", data.owner)))

	local v = {}
	for _, player in ipairs(data.shared) do
		v[#v + 1] = player
	end

	local pdata = sp.get_player_data(data.owner)
	for _, player in ipairs(pdata.shared) do
		v[#v + 1] = player .. "*"
	end

	if #v > 0 then
		return true, S("Players with access: @1", table.concat(v, ", "))
	end
end)

local function check_ownership(name)
	local player = minetest.get_player_by_name(name)
	local data, index = sp.get_claim(player:get_pos())
	if not data then
		return false, S("This area is not claimed yet.")
	end
	local priv = minetest.check_player_privs(name, {simple_protection=true})
	if name ~= data.owner and not priv then
		return false, S("You do not own this area.")
	end
	return true, data, index
end

local function table_erase(t, e)
	if not t or not e then
		return false
	end
	local removed = false
	for i, v in ipairs(t) do
		if v == e then
			table.remove(t, i)
			removed = true
		end
	end
	return removed
end

sp.register_subcommand("share", function(name, param)
	if not param or name == param then
		return false, S("No player name given.")
	end
	if not minetest.get_auth_handler().get_auth(param) and param ~= "*all" then
		return false, S("Unknown player.")
	end
	local success, data, index = check_ownership(name)
	if not success then
		return success, data
	end

	if sp.is_shared(name, param) then
		return true, S("@1 already has access to all your areas.", param)
	end

	if sp.is_shared(data, param) then
		return true, S("@1 already has access to this area.", param)
	end
	table.insert(data.shared, param)
	sp.set_claim(data, index)

	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, S("@1 shared an area with you.", name))
	end
	return true, S("@1 has now access to this area.", param)
end)

sp.register_subcommand("unshare", function(name, param)
	if not param or name == param or param == "" then
		return false, S("No player name given.")
	end
	local success, data, index = check_ownership(name)
	if not success then
		return success, data
	end
	if not sp.is_shared(data, param) then
		return true, S("That player has no access to this area.")
	end
	table_erase(data.shared, param)
	sp.set_claim(data, index)

	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, S("@1 unshared an area with you.", name))
	end
	return true, S("@1 has no longer access to this area.", param)
end)

sp.register_subcommand("shareall", function(name, param)
	if not param or name == param or param == "" then
		return false, S("No player name given.")
	end
	if not minetest.get_auth_handler().get_auth(param) then
		if param == "*all" then
			return false, S("You can not share all your areas with everybody.")
		end
		return false, S("Unknown player.")
	end

	if sp.is_shared(name, param) then
		return true, S("@1 already has now access to all your areas.", param)
	end
	sp.update_share_all(name, { [param] = true })

	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, S("@1 shared all areas with you.", name))
	end
	return true, S("@1 has now access to all your areas.", param)
end)

sp.register_subcommand("unshareall", function(name, param)
	if not param or name == param or param == "" then
		return false, S("No player name given.")
	end

	local removed = sp.update_share_all(name, { [param] = false }) > 0

	-- Unshare each single claim
	local claims = sp.get_player_claims(name)
	for index, data in pairs(claims) do
		if table_erase(data.shared, param) then
			removed = true
		end
	end
	if not removed then
		return false, S("@1 does not have access to any of your areas.", param)
	end
	sp.update_claims(claims)
	if minetest.get_player_by_name(param) then
		minetest.chat_send_player(param, S("@1 unshared all areas with you.", name))
	end
	return true, S("@1 has no longer access to your areas.", param)
end)

sp.register_subcommand("unclaim", function(name)
	local success, data, index = check_ownership(name)
	if not success then
		return success, data
	end
	if sp.claim_return and name == data.owner then
		local player = minetest.get_player_by_name(name)
		local inv = player:get_inventory()
		if inv:room_for_item("main", "simple_protection:claim") then
			inv:add_item("main", "simple_protection:claim")
		end
	end
	sp.set_claim(nil, index)
	return true, S("This area is unowned now.")
end)

sp.register_subcommand("delete", function(name, param)
	if not param or name == param or param == "" then
		return false, S("No player name given.")
	end
	if not minetest.check_player_privs(name, {server=true}) then
		return false, S("Missing privilege: @1", "server")
	end

	local removed = {}

	-- Remove globally shared areas
	if sp.update_share_all(param, "erase") > 0 then
		table.insert(removed, S("Globally shared areas"))
	end

	-- Delete all claims
	local claims, count = sp.get_player_claims(param)
	for index in pairs(claims) do
		claims[index] = false
	end
	sp.update_claims(claims)

	if count > 0 then
		table.insert(removed, S("@1 claimed area(s)", tostring(count)))
	end

	if #removed == 0 then
		return false, S("@1 does not own any claimed areas.", param)
	end
	return true, S("Removed")..": "..table.concat(removed, ", ")
end)

sp.register_subcommand("list", function(name, param)
	local has_sp_priv = minetest.check_player_privs(name, {simple_protection=true})
	if not sp.area_list and not has_sp_priv then
		return false, S("This command is not available.")
	end
	if not param or param == "" then
		param = name
	end
	if not has_sp_priv and param ~= name then
		return false, S("Missing privilege: @1", "simple_protection")
	end

	local list = {
		"" -- Header placeholder
	}
	local claims = sp.get_player_claims(param)
	for index, cdata in pairs(claims) do
		local minp, maxp = sp.get_area_bounds(index, true)
		table.insert(list, string.format("%5i,%5i,%5i | %s",
			math.floor((minp.x + maxp.x) / 2),
			math.floor((minp.y + maxp.y) / 2),
			math.floor((minp.z + maxp.z) / 2),
			table.concat(cdata.shared or {}, ", ")
		))
	end

	list[1] = S("Listing all areas of @1. Amount: @2", param, tostring(#list - 1))
	return true, table.concat(list, "\n")
end)
