-- ob_fog: MCPE 0.1.x style blue haze + (optional) permanent day

local SKY_DAY      = "#9fcaff"
local SKY_HORIZON  = "#cfe7ff"
local SKY_INDOORS  = "#a8d0ff"

local FOG_SUN_TINT  = "#b8dcff"
local FOG_MOON_TINT = "#8aa7ff"

-- Keep it always day (set false if you want normal time later)
local LOCK_TIME  = true
local TARGET_TOD = 0.5   -- noon

local function apply_fog(player)
  if not (player and player.is_player and player:is_player()) then return end

  -- sky + fog tint (per-player)
  player:set_sky({
    type = "regular",
    clouds = true,
    sky_color = {
      day_sky       = SKY_DAY,
      day_horizon   = SKY_HORIZON,
      dawn_sky      = SKY_DAY,
      dawn_horizon  = SKY_HORIZON,
      night_sky     = "#0b0f1a",
      night_horizon = "#1a2233",
      indoors       = SKY_INDOORS,

      -- custom fog tints (supported in 5.x/Luanti 5.13)
      fog_sun_tint  = FOG_SUN_TINT,
      fog_moon_tint = FOG_MOON_TINT,
      fog_tint_type = "custom",
    }
  })

  -- clouds (per-player API)
  if player.set_clouds then
    player:set_clouds({
      density   = 0.4,
      color     = "#f2f6ff",
      ambient   = "#b8d6ff",
      thickness = 16,
      height    = 128,
      speed     = {x = 0, y = 0}
    })
  end
end

minetest.register_on_joinplayer(function(player)
  apply_fog(player)

  if LOCK_TIME then
    minetest.set_timeofday(TARGET_TOD)
    -- tiny keeper: re-pin time every ~2s for this session
    local key = "__ob_fog_time_lock"
    if not _G[key] then
      _G[key] = true
      local function keep()
        if _G[key] then
          minetest.set_timeofday(TARGET_TOD)
          minetest.after(2, keep)
        end
      end
      minetest.after(2, keep)
    end
  end
end)

minetest.register_on_respawnplayer(apply_fog)
