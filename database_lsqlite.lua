--[[
File: database_raw.lua

lSQLite database functions:
	load_db()
	save_share_db()
	get_claim(<pos or index>, direct access)
	set_claim(data, index)
	get_player_claims(player name)
	update_claims(claims table)
]]

local worldpath = minetest.get_worldpath()

local ie = minetest.request_insecure_environment()
if not ie then
	error("Cannot access insecure environment!")
end

local sql = ie.require("lsqlite3")
-- Remove public table
if sqlite3 then
	sqlite3 = nil
end

local db = sql.open(worldpath .. "/s_protect.sqlite3")

local function sql_exec(q)
	if db:exec(q) ~= sql.OK then
		minetest.log("info", "[simple_protection] lSQLite: " .. db:errmsg())
	end
end

local function sql_row(q)
	q = q .. " LIMIT 1;"
	for row in db:nrows(q) do
		return row
	end
end

sql_exec([[
CREATE TABLE IF NOT EXISTS claims (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	x INTEGER,
	y INTEGER,
	z INTEGER,
	owner TEXT,
	shared TEXT,
	data TEXT
);
CREATE TABLE IF NOT EXISTS shares (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	owner TEXT,
	shared TEXT,
	data TEXT
);
]])

function s_protect.load_db() end
function s_protect.load_shareall() end
function s_protect.save_share_db() end

function s_protect.set_claim(cpos, claim)
	local id, row = s_protect.get_claim(cpos)

	if not claim then
		if not id then
			-- Claim never existed
			return
		end

		-- Remove claim
		sql_exec(
			("DELETE FROM claims WHERE id = %i LIMIT 1;"):format(id)
		)
	end

	if id then
		local vals = {}
		for k, v in pairs(claim) do
			if row[k] ~= v and type(v) == "string" then
				vals[#vals + 1] = ("%s = `%s`"):format(k, v)
			end
		end
		if #vals == 0 then
			return
		end
		sql_exec(
			("UPDATE claims SET %s WHERE id = %i LIMIT 1;")
			:format(table.concat(vals, ","), id)
		)
	else
		sql_exec(
			("INSERT INTO claims VALUES (%i, %i, %i, %s, %s, %s);")
			:format(pos.x, pos.y, pos.z, claim.owner,
				claim.shared or "", claim.data or "")
		)
	end
end

function s_protect.get_claim(cpos)
	local q
	if type(pos) == "number" then
		-- Direct index
		q = "id = " .. cpos
	else
		q = ("x = %i AND y = %i AND z = %z"):format(cpos.x, cpos.y, cpos.z)
	end
	local row = sql_row("SELECT id, owner, shared, data FROM claims WHERE " .. q)
	if not row then
		return
	end

	local id = row.id
	row.id = nil
	return id, row
end

function s_protect.get_player_claims(owner)
	local q = ("SELECT * FROM claims WHERE owner = %s;"):format(owner)
	local vals = {}
	for row in db:nrows(q) do
		vals[#vals + 1] = row
	end
	return vals
end

function s_protect.update_claims(updated)
	error("Inefficient. To be removed.")
end
