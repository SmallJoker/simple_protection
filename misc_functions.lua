--[[
File: functions.lua

Protection helper functions
Configuration loading
]]

-- Helper functions

-- Cache for performance
local get_player_privs = minetest.get_player_privs
local registered_on_access = {}
local sp = simple_protection

sp.can_access = function(pos, player_name)
	if not player_name then
		return false
	end
	-- Allow access for pipeworks and unidentified mods
	if player_name == ":pipeworks"
			or player_name == "" then
		return true
	end

	-- Admin power, handle privileges
	local privs = get_player_privs(player_name)
	if privs.simple_protection or privs.protection_bypass then
		return true
	end

	-- Data of current area
	local data = sp.get_claim(pos)

	-- Area is not claimed
	if not data then
		-- Allow digging when claiming is not forced
		if not sp.claim_to_dig then
			return true
		end

		-- Must claim everywhere? Disallow everywhere.
		if not sp.underground_limit then
			return false
		end
		-- Is it in claimable area? Yes? Disallow.
		if pos.y >= sp.underground_limit then
			return false
		end
		return true
	end
	if player_name == data.owner then
		return true
	end

	-- Complicated-looking return value handling:
	-- false: Forbid access instantly
	-- true:  Access granted if none returns false
	-- nil:   Do nothing
	local override_access = false
	for i = 1, #registered_on_access do
		local ret = registered_on_access[i](
			vector.new(pos), player_name, data.owner)

		if ret == false then
			return false
		end
		if ret == true then
			override_access = true
		end
	end
	if override_access then
		return true
	end

	-- Owner shared the area with the player
	if sp.is_shared(data.owner, player_name) then
		return true
	end
	-- Globally shared area
	if sp.is_shared(data, player_name) then
		return true
	end
	if sp.is_shared(data, "*all") then
		return true
	end
	return false
end

sp.register_on_access = function(func)
	registered_on_access[#registered_on_access + 1] = func
end

sp.get_location = function(pos_)
	local pos = vector.round(pos_)
	return vector.floor({
		x =  pos.x                         / sp.claim_size,
		y = (pos.y + sp.start_underground) / sp.claim_height,
		z =  pos.z                         / sp.claim_size
	})
end

sp.get_area_bounds = function(pos, direct_access)
	local cs = sp.claim_size
	local cy = sp.claim_height

	if direct_access then
		-- by ClaimIndex
		pos = sp.claim_index_to_gridpos(pos)
	else
		-- by 3D vector
		pos = sp.get_location(pos)
	end

	local minp = {
		x = pos.x * cs,
		y = pos.y * cy - sp.start_underground,
		z = pos.z * cs
	}
	local maxp = {
		x = minp.x + cs - 1,
		y = minp.y + cy - 1,
		z = minp.z + cs - 1
	}

	return minp, maxp
end

sp.get_center = function(pos1)
	local size = sp.claim_size
	local pos = {
		x = pos1.x / size,
		y = pos1.y + 1.5,
		z = pos1.z / size
	}
	pos = vector.floor(pos)
	-- Get the middle of the area
	pos.x = pos.x * size + (size / 2)
	pos.z = pos.z * size + (size / 2)
	return pos
end

sp.load_config = function()
	-- Load defaults
	dofile(sp.mod_path.."/default_settings.lua")
	local file = io.open(sp.conf, "r")
	if not file then
		-- Duplicate configuration file on first time
		local src = io.open(sp.mod_path.."/default_settings.lua", "r")
		file = io.open(sp.conf, "w")

		while true do
			local block = src:read(128) -- 128B at once
			if not block then
				io.close(src)
				io.close(file)
				break
			end
			file:write(block)
		end
		return
	end

	io.close(file)

	-- Load existing config
	rawset(_G, "s_protect", {})
	dofile(sp.conf)

	-- Backwards compatibility
	for k, v in pairs(s_protect) do
		sp[k] = v
	end
	s_protect = nil

	-- Sanity check individual settings
	assert((sp.claim_size % 2) == 0 and sp.claim_size >= 4,
		"claim_size must be even and >= 4")
	assert(sp.claim_height >= 4, "claim_height must be >= 4")

	if sp.claim_heigh then
		minetest.log("warning", "[simple_protection] "
			.. "Deprecated setting: claim_heigh")
		sp.claim_height = sp.claim_heigh
	end
	if sp.underground_claim then
		minetest.log("warning", "[simple_protection] "
			.. "Deprecated setting: underground_claim")
		sp.underground_limit = nil
	end
end
