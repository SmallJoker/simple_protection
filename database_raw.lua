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
local share_data = {}
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
	minetest.log("action", "[simple_protection] Loaded claim data (raw)")
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
				share_data[data[1]] = _shared
			end
		end
	end
	io.close(file)
	minetest.log("action", "[simple_protection] Loaded shared claims (raw)")
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

local function save_share_db()
	if delay(share_db, save_share_db) then
		return
	end

	-- Save globally shared areas
	local contents = {}
	for name, players in pairs(share_data) do
		if #players > 0 then
			contents[#contents + 1] = name .. " " ..
				table.concat(players, " ")
		end
	end
	minetest.safe_file_write(sp.sharefile, table.concat(contents, "\n"))
end

--===================-- Player data --===================--

function sp.get_player_data(player_name)
	return {
		shared = share_data[player_name] or {}
	}
end

function sp.set_player_data(player_name, pdata)
	-- Other fields are not supported
	if next(pdata and pdata.shared or {}) then
		share_data[player_name] = pdata.shared
	else
		share_data[player_name] = nil
	end
	save_share_db()
end

--===================-- Claim management --===================--

-- Speed up the function access
local get_location = sp.get_location
function sp.get_claim(pos, direct, z)
	if not direct then
		-- Get current grind position
		pos = get_location(pos)
		-- Convert position vector to database key
		pos = pos.x..","..pos.y..","..pos.z
	elseif z then
		pos = pos..","..direct.. ","..z
	end

	return claim_data[pos], pos
end

function sp.set_claim(data, index)
	claim_data[index] = data
	save_claims()
end

-- Internal function
function sp.claim_index_to_gridpos(index)
	local x, y, z = index:match("^([%d-]+),([%d-]+),([%d-]+)$")
	return vector.new(
		tonumber(x),
		tonumber(y),
		tonumber(z)
	)
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
			-- false --> remove
			claim_data[index] = nil
		else
			claim_data[index] = data
		end
	end
	save_claims()
end

--===================-- Sharing system --===================--

function sp.is_shared(id, player_name)
	if type(id) == "table" and id.shared then
		-- Find shared information in ClaimData
		return table.indexof(id.shared, player_name) > 0
	end

	-- Provided owner name -> find in globally shared data
	assert(type(id) == "string", "is_shared(): Either ClaimData or string expected")
	return table.indexof(share_data[id] or {}, player_name) > 0
end

function sp.update_share_all(owner, modify)
	local updated = 0
	local pdata = sp.get_player_data(owner)
	local list = pdata.shared -- by table reference

	if modify == "erase" then
		updated = #list
		list = {}
		modify = {}
	end

	for name, status in pairs(modify) do
		local index = table.indexof(list, name)
		if (index > 0) ~= status then
			-- Mismatch -> update list
			if status then
				table.insert(list, name)
			else
				table.remove(list, index)
			end
			updated = updated + 1
		end
	end

	if updated > 0 then
		sp.set_player_data(owner, pdata)
	end
	return updated
end