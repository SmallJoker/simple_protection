local sp = simple_protection

local store = minetest.get_mod_storage()
local version

local function json_read(key)
	local list = store:get(key)
	if not list then
		return
	end

	list = minetest.parse_json(list)
	if type(list) ~= "table" then
		-- parse_json already prints the error -> give backtrace.
		minetest.log("error", "Source: " .. key)
		return
	end
	return list
end

local function json_write(key, value)
	assert(type(value) == "table")

	local str, msg = minetest.write_json(value)
	if not str then
		minetest.log("error", "Source: " .. key .. ": " .. (msg or "<nil>"))
		return
	end
	store:set_string(key, str)
	return true
end

function sp.load_db()
	local world = minetest.get_worldpath()
	local backend = Settings(world .. "/world.mt"):get("mod_storage_backend") or "files"
	if backend == "files" then
		minetest.log("warning", "[simple_protection] Ineffective mod storage is being used! " ..
			"Please migrate the 'files' backend to a database like 'sqlite3'. Example: " ..
			"minetest --server --worldname <NAME> --migrate-mod-storage sqlite3")
	end

	version = store:get_int("!_VERSION") -- 0 if not existing
	assert(version < 1000, "Incompatible store format.")
	if version == 0 then
		version = 1
		store:set_int("!_VERSION", version)
	end

	minetest.log("action", "[simple_protection] Loaded claim data (storage: " .. backend .. ")")
end

--===================-- Player data --===================--

function sp.get_player_data(player_name)
	local pdata = json_read("P" .. player_name) or {}
	pdata.shared = pdata.shared or {}
	return pdata
end

function sp.set_player_data(player_name, pdata)
	if not pdata then
		-- Data removal
		store:set_string("P" .. player_name, "")
		return
	end

	json_write("P" .. player_name, pdata)
end

--===================-- Claim management --===================--

-- Speed up the function access
local get_location = sp.get_location
function sp.get_claim(pos, direct, z)
	if not direct then
		-- Get current grind position
		pos = get_location(pos)
		-- Convert position vector to database key
		pos = "C"..pos.x..","..pos.y..","..pos.z
	elseif z then
		pos = "C"..pos..","..direct.. ","..z
	end

	-- type(pos) == number
	local claim = json_read(pos)
	if claim then
		claim.shared = claim.shared or {}
	end
	return claim, pos
end

function sp.set_claim(data, index)
	if not data then
		-- Claim removal
		store:set_string(index, "")
		return
	end

	-- Update claim
	json_write(index, data)
end

-- Internal function
function sp.claim_index_to_gridpos(index)
	local x, y, z = index:match("^C([%d-]+),([%d-]+),([%d-]+)$")
	return vector.new(
		tonumber(x),
		tonumber(y),
		tonumber(z)
	)
end

function sp.get_player_claims(owner)
	-- This is rather inefficient
	local count = 0
	local claims = {}

	local all = store:to_table()
	for index in pairs(all.fields) do
		local first = index:byte()
		if first == 67 then -- "C"
			local cdata = sp.get_claim(index, true)
			if cdata.owner == owner then
				claims[index] = cdata
				count = count + 1
			end
		end
	end
	return claims, count
end

-- Bulk update
function sp.update_claims(updated)
	for index, data in pairs(updated) do
		sp.set_claim(data, index)
	end
end

--===================-- Sharing system --===================--

function sp.is_shared(id, player_name)
	if type(id) == "table" and id.shared then
		-- Find shared information in ClaimData
		return table.indexof(id.shared, player_name) > 0
	end

	-- Provided owner name -> find in globally shared data
	assert(type(id) == "string", "is_shared(): Either ClaimData or string expected")
	local list = json_read(id)
	return table.indexof(list or {}, player_name) > 0
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
