--[[
File: database_raw.lua

Raw text format database functions:
	load_db()
	save_share_db()
	get_claim(<pos or index>, direct access)
	set_claim(data, index)
	get_player_claims(player name)
	update_claims(claims table)
]]

local claim_data = {}
local sp = simple_protection

function sp.load_db()
	-- Don't forget the "parties"
	sp.load_shareall()

	local file = io.open(sp.file, "r")
	if not file then
		return
	end
	for line in file:lines() do
		local data = line:split(" ")
		if #data >= 2 then
			-- Line format: pos, owner, shared_player, shared_player2, ..
			local _shared = {}
			for index = 3, #data do
				if data[index] ~= "" then
					table.insert(_shared, data[index])
				end
			end
			claim_data[data[1]] = {owner=data[2], shared=_shared}
		end
	end
	io.close(file)
	minetest.log("action", "[simple_protection] Loaded claim data")
end

function sp.load_shareall()
	local file = io.open(sp.sharefile, "r")
	if not file then
		return
	end
	for line in file:lines() do
		if line ~= "" then
			local data = line:split(" ")
			-- Line format: owner, shared_player, shared_player2, ..
			local _shared = {}
			if #data > 1 then
				for index = 2, #data do
					if data[index] ~= "" then
						table.insert(_shared, data[index])
					end
				end
				sp.share[data[1]] = _shared
			end
		end
	end
	io.close(file)
	minetest.log("action", "[simple_protection] Loaded shared claims")
end

local claim_db = { time = os.time(), dirty = false }
local share_db = { time = os.time(), dirty = false }

local function delay(db_info, func)
	local dtime = os.time() - db_info.time
	if dtime < 6 then
		-- Excessive save requests. Delay them.
		if not db_info.dirty then
			minetest.after(6 - dtime, func)
		end
		db_info.dirty = true
		return true
	end
	db_info.time = os.time()
	db_info.dirty = false
end

local function save_claims()
	if delay(claim_db, save_claims) then
		return
	end

	local contents = {}
	for pos, data in pairs(claim_data) do
		if data.owner and data.owner ~= "" then
			contents[#contents + 1] =
				pos .. " ".. data.owner .. " " ..
				table.concat(data.shared, " ")
		end
	end
	minetest.safe_file_write(sp.file, table.concat(contents, "\n"))
end

function sp.save_share_db()
	if delay(share_db, sp.save_share_db) then
		return
	end

	-- Save globally shared areas
	local contents = {}
	for name, players in pairs(sp.share) do
		if #players > 0 then
			contents[#contents + 1] = name .. " " ..
				table.concat(players, " ")
		end
	end
	minetest.safe_file_write(sp.sharefile, table.concat(contents, "\n"))
end

-- Speed up the function access
local get_location = sp.get_location
function sp.get_claim(pos, direct_access)
	if direct_access then
		return claim_data[pos], pos
	end
	local pos = get_location(pos)
	local index = pos.x..","..pos.y..","..pos.z
	return claim_data[index], index
end

function sp.set_claim(data, index)
	claim_data[index] = data
	save_claims()
end

function sp.get_player_claims(owner)
	local count = 0
	local claims = {}
	for index, data in pairs(claim_data) do
		if data.owner == owner then
			claims[index] = data
			count = count + 1
		end
	end
	return claims, count
end

function sp.update_claims(updated)
	for index, data in pairs(updated) do
		if not data then
			claim_data[index] = nil
		else
			claim_data[index] = data
		end
	end
	save_claims()
end

local function table_contains(t, to_find)
	for i, v in pairs(t) do
		if v == to_find then
			return true
		end
	end
	return false
end
function sp.is_shared(id, player_name)
	if type(id) == "table" and id.shared then
		-- by area
		return table_contains(id.shared, player_name)
	end
	assert(type(id) == "string", "is_shared(): Either ClaimData or string expected")
	-- by owner
	return table_contains(sp.share[id] or {}, player_name)
end