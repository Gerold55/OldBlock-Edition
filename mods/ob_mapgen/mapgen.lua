-- Plains with inland sand patches (no beaches), non-floating trees, no Perlin

local BORDER   = 128
local GROUND_Y = 1

local cid_air    = minetest.CONTENT_AIR
local cid_stone  = minetest.get_content_id("ob_core:stone")
local cid_dirt   = minetest.get_content_id("ob_core:dirt")
local cid_grass  = minetest.get_content_id("ob_core:dirt_with_grass")
local cid_sand   = minetest.get_content_id("ob_core:sand")
local cid_log    = minetest.get_content_id("ob_core:log_oak")
local cid_leaf   = minetest.get_content_id("ob_core:leaves_oak")

local function hash01(x, z, seed) return (math.sin(x*12.9898 + z*78.233 + seed*37.719) * 43758.5453) % 1 end
local function smoothstep(t) return t*t*(3 - 2*t) end
local function lerp(a,b,t) return a + (b - a) * t end
local function vnoise2d(x, z, freq, seed)
  local xf, zf = x/freq, z/freq
  local x0, z0 = math.floor(xf), math.floor(zf)
  local tx, tz = smoothstep(xf - x0), smoothstep(zf - z0)
  local v00 = hash01(x0,   z0,   seed)
  local v10 = hash01(x0+1, z0,   seed)
  local v01 = hash01(x0,   z0+1, seed)
  local v11 = hash01(x0+1, z0+1, seed)
  local xa = lerp(v00, v10, tx)
  local xb = lerp(v01, v11, tx)
  return lerp(xa, xb, tz) * 2 - 1
end
local function within_border(x, z) return x >= -BORDER and x < BORDER and z >= -BORDER and z < BORDER end

local function is_flat_grass(area, data, x, y, z)
  if data[area:index(x,y,z)] ~= cid_grass then return false end
  if data[area:index(x,y+1,z)] ~= cid_air then return false end
  return true
end
local function place_oak(area, data, x, y, z)
  local height = 4 + math.random(0,1)
  for ty = 0, height do data[area:index(x, y+ty, z)] = cid_log end
  for dy = 2, 4 do
    local r = (dy == 4) and 1 or 2
    for dz = -r, r do for dx = -r, r do
      if math.abs(dx) + math.abs(dz) <= r + 1 then
        data[area:index(x+dx, y+height-1 + (dy-2), z+dz)] = cid_leaf
      end end end
  end
end

minetest.register_on_generated(function(minp, maxp, seed)
  if maxp.x < -BORDER or minp.x >= BORDER or maxp.z < -BORDER or minp.z >= BORDER then return end
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
  local data = vm:get_data()

  -- clear to air
  for z = minp.z, maxp.z do
    for y = minp.y, maxp.y do
      local vi = area:index(minp.x, y, z)
      for x = minp.x, maxp.x do data[vi] = cid_air; vi = vi + 1 end
    end
  end

  -- terrain (gentle rolling plains)
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      if within_border(x, z) then
        local nh1 = vnoise2d(x, z, 48, 901)
        local nh2 = vnoise2d(x, z, 24, 177)
        local nh  = nh1 * 0.6 + nh2 * 0.4
        local h   = GROUND_Y + math.floor(nh * 4)

        for y = minp.y, math.min(h - 3, maxp.y) do data[area:index(x,y,z)] = cid_stone end
        for y = math.max(minp.y, h - 3), math.min(h - 1, maxp.y) do data[area:index(x,y,z)] = cid_dirt end

        if h >= minp.y and h <= maxp.y then
          local idx = area:index(x, h, z)
          data[idx] = cid_grass
        end
      end
    end
  end

  -- inland sand patches via independent noise threshold (no beaches)
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      if within_border(x, z) then
        local nhs = vnoise2d(x, z, 20, 333)  -- patchiness
        local topy = nil
        for y = maxp.y, minp.y, -1 do
          local id = data[area:index(x,y,z)]
          if id == cid_grass then topy = y; break
          elseif id == cid_sand or id == cid_dirt or id == cid_stone then break end
        end
        if topy and nhs > 0.35 then
          data[area:index(x, topy, z)] = cid_sand
        end
      end
    end
  end

  -- trees (only on flat grass)
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      if within_border(x, z) and math.random(0,225) == 0 then
        for y = maxp.y, minp.y, -1 do
          local id = data[area:index(x,y,z)]
          if id == cid_grass and is_flat_grass(area, data, x, y, z) then
            place_oak(area, data, x, y+1, z)
            break
          elseif id == cid_sand or id == cid_dirt or id == cid_stone then
            break
          end
        end
      end
    end
  end

  vm:set_data(data)
  vm:calc_lighting()
  vm:update_liquids()
  vm:write_to_map(true)
end)
