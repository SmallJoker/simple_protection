--[[
File: database_raw.lua

Raw text format database functions:
	get_data
	load_db
	save_db
minetest.safe_file_write compatibility code
]]

s_protect.claims = {}
local last_save = os.time()
local is_db_dirty = false

-- Speed up the function access
local get_location = s_protect.get_location
function s_protect.get_data(pos)
	local pos = get_location(pos)
	local str = pos.x..","..pos.y..","..pos.z
	return s_protect.claims[str], str
end

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
			s_protect.claims[data[1]] = {owner=data[2], shared=_shared}
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
if not minetest.safe_file_write then
	function minetest.safe_file_write(path, content)
		local file = io.open(path, "w")
		file:write(content)
		io.close(file)
	end
end

function s_protect.save_db()
	local dtime = os.time() - last_save
	if dtime < 6 then
		-- Excessive save requests. Delay them.
		if not is_db_dirty then
			minetest.after(6 - dtime, s_protect.save_db)
		end
		is_db_dirty = true
		return
	end
	last_save = os.time()
	is_db_dirty = false

	local contents = ""
	for pos, data in pairs(s_protect.claims) do
		if data.owner and data.owner ~= "" then
			contents = contents ..
				pos .. " ".. data.owner ..
				table.concat(data.shared, " ") .. "\n"
		end
	end
	minetest.safe_file_write(s_protect.file, contents)

	-- Save globally shared areas
	contents = ""
	for name, players in pairs(s_protect.share) do
		if #players > 0 then
			contents = contents .. name ..
				table.concat(players, " ") .. "\n"
		end
	end
	minetest.safe_file_write(s_protect.sharefile, contents)
end
