--[[
	SETTINGS FILE

simple_protection/default_settings.lua
	Contains the default settings for freshly created worlds.
	Please do not modify in order to not get any configuration-related errors
	after updating all other files but this

[world_path]/s_protect.conf
	Contains the per-world specific settings.
	You may modify this one but pay attention, as some settings may cause
	unwanted side effects when claims were made.
]]

local sp = simple_protection

-- Back-end for data saving
-- Possible values:
--   "raw"     : Data is serialized to files using a custom format
--   "storage" : Generic implementation using Minetest API
sp.backend = "raw"

-- Width and length of claims in nodes
-- !! Distorts the claim locations along the X and Z axis !!
-- Type: Integer, positive, even number
sp.claim_size = 16

-- Height of claims in nodes
-- !! Distorts the claim locations along the Y axis !!
-- Type: Integer, positive
sp.claim_height = 150

-- Defines the Y offset where the 0th claim should start in the underground
-- Example of claim (0,0,0): Ymin = -(50) = -50, Ymax = 150 - (50) - 1 = 99
-- Type: Integer
sp.start_underground = 50

-- Only allows claiming above this Y value
-- To disable this limit, set the value to 'nil'
-- Type: Integer or nil
sp.underground_limit = -300

-- Returns the claim stick when unclaiming the area
-- Type: Boolean
sp.claim_return = true

-- Players will need to claim the area (or have access to it) to dig
-- Digging will be still allowed in the underground,
--   as defined by the setting 'simple_protection.underground_limit'
-- Type: Boolean
sp.claim_to_dig = false

-- Allows players to list their areas using '/area list'
-- Type: Boolean
sp.area_list = true

-- Limits the amount of claims per player
-- Doubled limit for players with the 'simple_protection' privilege
-- Type: Integer
sp.max_claims = 200
