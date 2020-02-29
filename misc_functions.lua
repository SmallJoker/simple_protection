--[[
File: functions.lua

Table helper functions
Protection helper functions
Configuration loading
]]

-- Helper functions
function table_contains(t, e)
	if not t or not e then
		return false
	end
	for i, v in ipairs(t) do
		if v == e then
			return true
		end
	end
	return false
end

function table_erase(t, e)
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

s_protect.can_access = function(pos, player_name)
	if not player_name then
		return false
	end
	-- Allow access for pipeworks and unidentified mods
	if player_name == ":pipeworks"
			or player_name == "" then
		return true
	end

	-- Admin power, handle privileges
	local privs = minetest.get_player_privs(player_name)
	if privs.simple_protection or privs.protection_bypass then
		return true
	end

	-- Data of current area
	local data = s_protect.get_claim(pos)

	-- Area is not claimed
	if not data then
		-- Allow digging when claiming is not forced
		if not s_protect.claim_to_dig then
			return true
		end

		-- Must claim everywhere? Disallow everywhere.
		if not s_protect.underground_limit then
			return false
		end
		-- Is it in claimable area? Yes? Disallow.
		if pos.y >= s_protect.underground_limit then
			return false
		end
		return true
	end
	if player_name == data.owner then
		return true
	end
	-- Owner shared the area with the player
	if table_contains(s_protect.share[data.owner], player_name) then
		return true
	end
	-- Globally shared area
	if table_contains(data.shared, player_name) then
		return true
	end
	if table_contains(data.shared, "*all") then
		return true
	end
	return false
end

s_protect.get_location = function(pos_)
	local pos = vector.round(pos_)
	return vector.floor({
		x =  pos.x                                / s_protect.claim_size,
		y = (pos.y + s_protect.start_underground) / s_protect.claim_height,
		z =  pos.z                                / s_protect.claim_size
	})
end

local get_location = s_protect.get_location
s_protect.get_area_bounds = function(pos_)
	local cs = s_protect.claim_size
	local cy = s_protect.claim_height

	local p = get_location(pos_)

	local minp = {
		x = p.x * cs,
		y = p.y * cy - s_protect.start_underground,
		z = p.z * cs
	}
	local maxp = {
		x = minp.x + cs - 1,
		y = minp.y + cy - 1,
		z = minp.z + cs - 1
	}

	return minp, maxp
end

s_protect.get_center = function(pos1)
	local size = s_protect.claim_size
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

simple_protection = false
s_protect.load_config = function()
	-- Load defaults
	dofile(s_protect.mod_path.."/default_settings.lua")
	local file = io.open(s_protect.conf, "r")
	if file then
		io.close(file)
		-- Load existing config
		simple_protection = {}
		dofile(s_protect.conf)

		-- Backwards compatibility
		for k, v in pairs(simple_protection) do
			s_protect[k] = v
		end
		simple_protection = nil
		if s_protect.claim_heigh then
			minetest.log("warning", "[simple_protection] "
				.. "Loaded deprecated setting: claim_heigh")
			s_protect.claim_height = s_protect.claim_heigh
		end
		if s_protect.underground_claim then
			minetest.log("warning", "[simple_protection] "
				.. "Loaded deprecated setting: underground_claim")
			s_protect.underground_limit = nil
		end
		return
	end
	-- Duplicate configuration file on first time
	local src = io.open(s_protect.mod_path.."/default_settings.lua", "r")
	file = io.open(s_protect.conf, "w")

	while true do
		local block = src:read(128) -- 128B at once
		if not block then
			io.close(src)
			io.close(file)
			break
		end
		file:write(block)
	end
end
