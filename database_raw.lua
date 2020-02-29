--[[
File: database_raw.lua

Raw text format database functions:
	load_db()
	save_share_db()
	get_claim(<pos or index>, direct access)
	set_claim(data, index)
	get_player_claims(player name)
	update_claims(claims table)

minetest.safe_file_write compatibility code
]]

local claim_data = {}
local claim_db = { time = os.time(), dirty = false }
local share_db = { time = os.time(), dirty = false }

function s_protect.load_db()
	-- Don't forget the "parties"
	s_protect.load_shareall()

	local file = io.open(s_protect.file, "r")
	if not file then
		return
	end
	for line in file:lines() do
		if line ~= "" then
			local data = line:split(" ")
			-- Line format: pos, owner, shared_player, shared_player2, ..
			local _shared = {}
			if #data > 2 then
				for index = 3, #data do
					if data[index] ~= "" then
						table.insert(_shared, data[index])
					end
				end
			end
			claim_data[data[1]] = {owner=data[2], shared=_shared}
		end
	end
	io.close(file)
	minetest.log("action", "[simple_protection] Loaded claim data")
end

function s_protect.load_shareall()
	local file = io.open(s_protect.sharefile, "r")
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
				s_protect.share[data[1]] = _shared
			end
		end
	end
	io.close(file)
	minetest.log("action", "[simple_protection] Loaded shared claims")
end

-- <= 0.4.16 compatibility
local function write_file(path, content)
	local file = io.open(path, "w")
	file:write(content)
	io.close(file)
end

-- Superior function
if minetest.safe_file_write then
	write_file = minetest.safe_file_write
end

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
	write_file(s_protect.file, table.concat(contents, "\n"))
end

function s_protect.save_share_db()
	if delay(share_db, s_protect.save_share_db) then
		return
	end

	-- Save globally shared areas
	local contents = {}
	for name, players in pairs(s_protect.share) do
		if #players > 0 then
			contents[#contents + 1] = name .. " " ..
				table.concat(players, " ")
		end
	end
	write_file(s_protect.sharefile, table.concat(contents, "\n"))
end

-- Speed up the function access
local get_location = s_protect.get_location
function s_protect.get_claim(pos, direct_access)
	if direct_access then
		return claim_data[pos], pos
	end
	local pos = get_location(pos)
	local index = pos.x..","..pos.y..","..pos.z
	return claim_data[index], index
end

function s_protect.set_claim(data, index)
	claim_data[index] = data
	save_claims()
end

function s_protect.get_player_claims(owner)
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

function s_protect.update_claims(updated)
	for index, data in pairs(updated) do
		if not data then
			claim_data[index] = nil
		else
			claim_data[index] = data
		end
	end
	save_claims()
end
