-- mods/ob_mapgen/mapgen.lua
-- OldBlock Edition — MCPE 0.1.x style finite world (no lava pools)
-- 256×256 world, y=0..63; gentle plains, oak trees, blobby sand/gravel,
-- optional tiny static water puddles.

local BORDER     = 128
local YMIN, YMAX = 0, 63
local BASE_Y     = 34
local H_AMPL     = 2

-- Features
local ENABLE_PUDDLES = true   -- set false for strict 0.1.0 without natural water

-- Cluster tuning
local CLUSTER_STEP            = 16
local SAND_CLUSTER_CHANCE     = 0.14
local GRAVEL_CLUSTER_CHANCE   = 0.08
local SAND_CLUSTER_R_MINMAX   = {3, 5}
local GRAVEL_CLUSTER_R_MINMAX = {2, 4}
local WORLD_MARGIN            = 4
local EDGE_BLOCK_MARGIN       = 2

-- Content IDs
local cid_air    = minetest.CONTENT_AIR
local cid_bed    = minetest.get_content_id("ob_core:bedrock")
local cid_stone  = minetest.get_content_id("ob_core:stone")
local cid_dirt   = minetest.get_content_id("ob_core:dirt")
local cid_grass  = minetest.get_content_id("ob_core:dirt_with_grass")
local cid_sand   = minetest.get_content_id("ob_core:sand")
local cid_gravel = minetest.get_content_id("ob_core:gravel")
local cid_log    = minetest.get_content_id("ob_core:log_oak")
local cid_leaf   = minetest.get_content_id("ob_core:leaves_oak")
local cid_water  = minetest.registered_nodes["ob_core:water_source"]
                  and minetest.get_content_id("ob_core:water_source") or nil

-- Helpers
local function within_border(x, z)
  return x >= -BORDER and x < BORDER and z >= -BORDER and z < BORDER
end

local function hash01(x, z, seed)
  return (math.sin(x*12.9898 + z*78.233 + seed*37.719) * 43758.5453) % 1
end

local function surface_y(x, z)
  local n = math.sin(x*0.02)*0.25 + math.sin(z*0.02)*0.25
  local h = BASE_Y + math.floor(n * H_AMPL + 0.5)
  if h < 10 then h = 10 elseif h > YMAX-6 then h = YMAX-6 end
  return h
end

local function slope4(x, z)
  local c = surface_y(x, z)
  local n = surface_y(x,   z-1)
  local s = surface_y(x,   z+1)
  local w = surface_y(x-1, z  )
  private_e = surface_y(x+1, z  )
  return c, (math.abs(n-c)+math.abs(s-c)+math.abs(w-c)+math.abs(private_e-c))/4
end

local function place_oak(area, data, emin, emax, x, y, z)
  local h = 4 + math.random(0, 1)
  for t = 0, h-1 do
    local yy = y + t
    if yy > emax.y then break end
    data[area:index(x, yy, z)] = cid_log
  end
  local top = math.min(y + h, emax.y)
  for dy = -2, 1 do
    local r = (dy == 1) and 1 or 2
    for dz = -r, r do for dx = -r, r do
      if math.abs(dx) + math.abs(dz) <= r + 1 then
        local ax, ay, az = x + dx, top + dy, z + dz
        if ax>=emin.x and ax<=emax.x and az>=emin.z and az<=emax.z and ay>=emin.y and ay<=emax.y then
          local vi = area:index(ax, ay, az)
          if data[vi] == cid_air then data[vi] = cid_leaf end
        end
      end
    end end
  end
end

-- Ovoid static water puddles (surface level)
local function in_ovoid(cx, cz, x, z, rx, rz, seed)
  local nx, nz = (x - cx) / rx, (z - cz) / rz
  local r2 = nx*nx + nz*nz
  if r2 > 1.15 then return false end
  local j = (hash01(x, z, seed*0.71) - 0.5) * 0.25
  return r2 <= (1.0 + j)
end

local function place_water_pond(area, data, minp, maxp, emin, emax, cx, cz, rx, rz, seed)
  local s  = surface_y(cx, cz)
  local wl = s
  local x0, x1 = cx - rx - 2, cx + rx + 2
  local z0, z1 = cz - rz - 2, cz + rz + 2
  for z = z0, z1 do
    for x = x0, x1 do
      if x>=emin.x and x<=emax.x and z>=emin.z and z<=emax.z and within_border(x, z) then
        local inside = in_ovoid(cx, cz, x, z, rx, rz, seed)
        local edge   = not inside and in_ovoid(cx, cz, x, z, rx+1, rz+1, seed)
        if inside then
          if wl-1 >= minp.y and wl-1 <= maxp.y then data[area:index(x, wl-1, z)] = cid_dirt end
          if wl   >= minp.y and wl   <= maxp.y then data[area:index(x, wl,   z)] = cid_water end
          if wl+1 >= minp.y and wl+1 <= maxp.y then data[area:index(x, wl+1, z)] = cid_air   end
        elseif edge then
          if s >= minp.y and s <= maxp.y then data[area:index(x, s, z)] = cid_sand end
        end
      end
    end
  end
end

-- Blobby cluster painter (sand/gravel)
local function place_cluster(area, data, minp, maxp, emin, emax, cx, cz, rmin, rmax, seed, node_cid)
  local rx = rmin + math.floor(hash01(cx, cz, seed*1.3) * (rmax - rmin + 1))
  local rz = rmin + math.floor(hash01(cx, cz, seed*2.1) * (rmax - rmin + 1))
  for z = cz - rz - 1, cz + rz + 1 do
    for x = cx - rx - 1, cx + rx + 1 do
      if x>=emin.x and x<=emax.x and z>=emin.z and z<=emax.z and within_border(x, z) then
        local nx, nz = (x - cx) / (rx + 0.001), (z - cz) / (rz + 0.001)
        local r2 = nx*nx + nz*nz
        if r2 <= 1.05 + (hash01(x, z, seed*0.57)-0.5)*0.15 then
          local s = surface_y(x, z)
          if s>=minp.y and s<=maxp.y then
            local vi = area:index(x, s, z)
            local id = data[vi]
            -- Don’t overwrite water
            if id ~= (cid_water or -1) then
              data[vi] = node_cid
            end
          end
        end
      end
    end
  end
end

minetest.register_on_generated(function(minp, maxp, seed)
  if maxp.x < -BORDER or minp.x >= BORDER or maxp.z < -BORDER or minp.z >= BORDER then return end

  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
  local data = vm:get_data()

  -- clear to air
  for z = minp.z, maxp.z do
    for y = minp.y, maxp.y do
      local vi = area:index(minp.x, y, z)
      for x = minp.x, maxp.x do
        data[vi] = cid_air
        vi = vi + 1
      end
    end
  end

  -- base terrain
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      if within_border(x, z) then
        local s, sl = slope4(x, z)
        if 0 >= minp.y and 0 <= maxp.y then
          data[area:index(x, 0, z)] = cid_bed
        end
        local stone_top = s - 3
        if stone_top >= minp.y then
          for y = math.max(minp.y, 1), math.min(stone_top, maxp.y) do
            data[area:index(x, y, z)] = cid_stone
          end
        end
        local dirt_th = (sl >= 2.5 and 1) or 2
        for y = math.max(minp.y, s - dirt_th), math.min(s - 1, maxp.y) do
          if y >= 1 then data[area:index(x, y, z)] = cid_dirt end
        end
        if s >= minp.y and s <= maxp.y then
          data[area:index(x, s, z)] = (sl > 3.0) and cid_stone or cid_grass
        end
      end
    end
  end

  -- blobby sand & gravel clusters
  for z = minp.z + EDGE_BLOCK_MARGIN, maxp.z - EDGE_BLOCK_MARGIN, CLUSTER_STEP do
    for x = minp.x + EDGE_BLOCK_MARGIN, maxp.x - EDGE_BLOCK_MARGIN, CLUSTER_STEP do
      if within_border(x, z)
        and math.abs(x) < (BORDER - WORLD_MARGIN)
        and math.abs(z) < (BORDER - WORLD_MARGIN) then

        if hash01(x, z, seed*0.33) < SAND_CLUSTER_CHANCE then
          place_cluster(area, data, minp, maxp, emin, emax, x, z,
            SAND_CLUSTER_R_MINMAX[1], SAND_CLUSTER_R_MINMAX[2], seed*11.1, cid_sand)
        end

        if hash01(x, z, seed*0.77) < GRAVEL_CLUSTER_CHANCE then
          place_cluster(area, data, minp, maxp, emin, emax, x, z,
            GRAVEL_CLUSTER_R_MINMAX[1], GRAVEL_CLUSTER_R_MINMAX[2], seed*13.7, cid_gravel)
        end
      end
    end
  end

  -- tiny puddles (static water) — optional
  if ENABLE_PUDDLES and cid_water then
    for z = minp.z + EDGE_BLOCK_MARGIN, maxp.z - EDGE_BLOCK_MARGIN, 12 do
      for x = minp.x + EDGE_BLOCK_MARGIN, maxp.x - EDGE_BLOCK_MARGIN, 12 do
        if within_border(x, z)
          and math.abs(x) < (BORDER - WORLD_MARGIN)
          and math.abs(z) < (BORDER - WORLD_MARGIN) then
          local _, sl = slope4(x, z)
          if sl <= 1.5 and hash01(x, z, seed*0.21) > 0.978 then
            local rx = 2 + (hash01(x, z, seed*1.1) > 0.85 and 1 or 0)
            local rz = 2 + (hash01(x, z, seed*1.7) > 0.80 and 1 or 0)
            if x - rx - 2 > minp.x and x + rx + 2 < maxp.x
              and z - rz - 2 > minp.z and z + rz + 2 < maxp.z then
              place_water_pond(area, data, minp, maxp, emin, emax, x, z, rx, rz, seed)
            end
          end
        end
      end
    end
  end

  -- sparse oak trees
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      if within_border(x, z) and hash01(x, z, seed*0.77) > 0.995 then
        local s = surface_y(x, z)
        if s + 6 <= emax.y and s >= minp.y and s <= maxp.y then
          local vi = area:index(x, s, z)
          if data[vi] == cid_grass and data[area:index(x, s+1, z)] == cid_air then
            place_oak(area, data, emin, emax, x, s+1, z)
          end
        end
      end
    end
  end

  vm:set_data(data)
  vm:write_to_map()
  vm:calc_lighting()
end)
