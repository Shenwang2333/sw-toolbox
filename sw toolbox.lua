_DEBUG = true
local math = math or _G.math

local gradient = require("neverlose/gradient")
local l_pui_0 = require("neverlose/pui")

local hitmarker_group = ui.find("Visuals", "World", "Other", "Hit Marker")

if hitmarker_group then
    local group = hitmarker_group:create()
    local hitmarker_enabled = group:switch(ui.get_icon("plus") .. "     crosshair hitmarker", true)
    local hitmarker_color = hitmarker_enabled:color_picker(color(255, 255, 255, 255))
    
    local hitmarker_queue = {}
    
    local function add_crosshair_hitmarker(event)
        if hitmarker_enabled:get() and event.state == nil then
            table.insert(hitmarker_queue, { time = globals.tickcount + 35, alpha = 0 })
        end
    end
    
    local function render_crosshair_hitmarker()
        if not hitmarker_enabled:get() then
            return
        end
        
        if not globals.is_connected then
            hitmarker_queue = {}
            return
        end
        
        local screen_center = render.screen_size() * 0.5
        local color_val = hitmarker_color:get()
        
        for i = #hitmarker_queue, 1, -1 do
            local marker = hitmarker_queue[i]
            
            if globals.tickcount >= marker.time then
                table.remove(hitmarker_queue, i)
            else
                marker.alpha = math.min(marker.alpha + 10, 255)
                local col = color(color_val.r, color_val.g, color_val.b, marker.alpha)
                
                render.line(vector(screen_center.x + 4, screen_center.y + 4), vector(screen_center.x + 9, screen_center.y + 9), col)
                render.line(vector(screen_center.x - 4, screen_center.y - 4), vector(screen_center.x - 9, screen_center.y - 9), col)
                render.line(vector(screen_center.x - 4, screen_center.y + 4), vector(screen_center.x - 9, screen_center.y + 9), col)
                render.line(vector(screen_center.x + 4, screen_center.y - 4), vector(screen_center.x + 9, screen_center.y - 9), col)
            end
        end
    end
    
    events.aim_ack:set(add_crosshair_hitmarker)
    events.render:set(render_crosshair_hitmarker)
end

local spectators_group = ui.find("Miscellaneous", "Main", "Other", "Windows")

if spectators_group then
    local spectators_settings = spectators_group:create()
    local spectators_enabled = spectators_settings:switch("GS Spects list")
    
    local function get_spectators()
        local spectators = {}
        local local_player = entity.get_local_player()
        
        if local_player then
            local target = local_player.m_hObserverTarget or local_player
            
            for _, player in ipairs(entity.get_players(false, false) or {}) do
                if player.m_hObserverTarget == target then
                    table.insert(spectators, player)
                end
            end
        end
        
        return spectators
    end
    
    local function render_spectators()
        if not spectators_enabled:get() then
            return
        end
        
        local screen_size = render.screen_size()
        local y_offset = 5
        
        for _, spec in ipairs(get_spectators()) do
            local name = spec:get_name()
            local text_width = render.measure_text(1, nil, name).x
            
            render.text(1, vector(screen_size.x - text_width - 2, 2 + y_offset), color(255), nil, name)
            y_offset = y_offset + 17
        end
    end
    
    events.render:set(render_spectators)
end

local reference = ui.find("Visuals", "World", "Other")

if reference then
    local hitmarker_3d_enabled = reference:switch("world hitmarker", true)
    local hitmarker_3d_color = hitmarker_3d_enabled:color_picker(color(88, 255, 209, 255))
    
    local FADE_TIME = 0.5
    local WAIT_TIME = 1.0
    local shots = {}
    
    local function add_3d_hitmarker(shot)
        shots[shot.id] = {
            Position = shot.aim,
            WaitTime = WAIT_TIME,
            FadeTime = 1,
            Reason = shot.state
        }
    end
    
    local function render_3d_hitmarker()
        if not hitmarker_3d_enabled:get() then
            return
        end
        
        local ss = render.screen_size()
        
        for i, shot in pairs(shots) do
            if shot.FadeTime <= 0 then
                shots[i] = nil
            else
                shot.WaitTime = shot.WaitTime - globals.frametime
                if shot.WaitTime <= 0 then
                    shot.FadeTime = shot.FadeTime - ((1 / FADE_TIME) * globals.frametime)
                end
                
                if shot.Position and shot.Reason == nil then
                    local pos = render.world_to_screen(vector(shot.Position.x, shot.Position.y, shot.Position.z))
                    
                    if pos then
                        local x, y = pos.x, pos.y
                        local r, g, b, a = hitmarker_3d_color:get():unpack()
                        local col = color(r, g, b, a * shot.FadeTime)
                        
                        render.rect(
                            vector(x - (1 / ss.x) * ss.x, y - (5 / ss.y) * ss.y),
                            vector(x + (1 / ss.x) * ss.x, y + (5 / ss.y) * ss.y),
                            col, 0, true
                        )
                        render.rect(
                            vector(x - (5 / ss.x) * ss.x, y - (1 / ss.y) * ss.y),
                            vector(x + (5 / ss.x) * ss.x, y + (1 / ss.y) * ss.y),
                            col, 0, true
                        )
                    end
                end
            end
        end
    end
    
    events.render:set(render_3d_hitmarker)
    events.aim_ack:set(add_3d_hitmarker)
    
    events.round_start:set(function()
        shots = {}
    end)
    
    events.player_spawned:set(function()
        shots = {}
    end)
end

local world_other_group = ui.find("Visuals", "World", "Other")

if world_other_group then
    local visualize_exploits = world_other_group:switch("visualize exploits", false)
    local visualize_exploits_sub = visualize_exploits:create()
    local visualize_exploits_color = visualize_exploits_sub:color_picker("color", color(255, 0, 0, 255))
    local visualize_exploits_thickness = visualize_exploits_sub:slider("thickness", 0, 100, 35, 1, "%")
    
    local visualize_exploits_state = false
    local visualize_exploits_color_val = color(255, 0, 0, 255)
    local visualize_exploits_thickness_val = 0.35
    
    local function update_visualize_exploits()
        visualize_exploits_state = visualize_exploits:get()
        visualize_exploits_color_val = visualize_exploits_color:get()
        visualize_exploits_thickness_val = visualize_exploits_thickness:get() * 0.01
    end
    
    visualize_exploits:set_callback(update_visualize_exploits, true)
    visualize_exploits_color:set_callback(update_visualize_exploits, true)
    visualize_exploits_thickness:set_callback(update_visualize_exploits, true)
    
    local function visualize_exploits_core_init()
        local lagrecord = nil
        pcall(function() lagrecord = require("neverlose/lagrecord") end)
        if lagrecord == nil then return end
        lagrecord = lagrecord ^ lagrecord.SIGNED
        
        local edges = {
            {0,1}, {1,2}, {2,3}, {3,0},
            {5,6}, {6,7}, {1,4}, {4,8},
            {0,4}, {1,5}, {2,6}, {3,7},
            {5,8}, {7,8}, {3,4}
        }
        
        local function draw_bounding_box(ctx, offset, bbox, clr, thickness)
            if ctx == nil or offset == nil or bbox == nil then return end
            if clr == nil then clr = color() end
            if thickness == nil then thickness = 0.15 end
            
            local points = {
                bbox[1] + offset,
                bbox[2] + offset
            }
            
            local vertices = {
                vector(points[1].x, points[1].y, points[1].z),
                vector(points[1].x, points[2].y, points[1].z),
                vector(points[2].x, points[2].y, points[1].z),
                vector(points[2].x, points[1].y, points[1].z),
                vector(points[1].x, points[1].y, points[2].z),
                vector(points[1].x, points[2].y, points[2].z),
                vector(points[2].x, points[2].y, points[2].z),
                vector(points[2].x, points[1].y, points[2].z)
            }
            
            for _, edge in ipairs(edges) do
                if vertices[edge[1]] and vertices[edge[2]] then
                    local v1 = vertices[edge[1]]
                    local v2 = vertices[edge[2]]
                    if v1:length2dsqr() > 0 and v2:length2dsqr() > 0 then
                        ctx:render(v1, v2, thickness, "lgw", clr)
                    end
                end
            end
        end
        
        local function on_render_glow(ctx)
            if not visualize_exploits_state then return end
            local local_player = entity.get_local_player()
            if local_player == nil or lagrecord == nil then return end
            
            entity.get_players(true, false, function(player)
                if player:get_bbox().pos1 == nil then return end
                local snapshot = lagrecord.get_snapshot(player)
                if snapshot == nil then return end
                
                local no_entry = snapshot.command.no_entry
                if no_entry.y > 0 then
                    if local_player.m_hObserverTarget == player and local_player.m_iObserverMode == 5 then
                        return
                    end
                    local origin = snapshot.origin
                    draw_bounding_box(
                        ctx,
                        origin.current,
                        origin.volume,
                        visualize_exploits_color_val,
                        visualize_exploits_thickness_val * (no_entry.x / no_entry.y)
                    )
                end
            end)
        end
        
        events.render_glow:set(on_render_glow)
        
        local function on_update()
            pcall(lagrecord.set_update_callback, function(e) return e:is_enemy() end)
        end
        on_update()
    end
    
    visualize_exploits_core_init()
end

local misc_other_group = ui.find("Miscellaneous", "Main", "Other")

if misc_other_group then
    local chimera_log = misc_other_group:switch("chimera logs", true)
    local chimera_log_sub = chimera_log:create()
    
    local text_color = chimera_log_sub:color_picker("text color", color("#FFBC80FF"))
    local events_select = chimera_log_sub:selectable("events", {"damage dealt", "purchases", "aimbot"})
    local output_select = chimera_log_sub:selectable("style", {"on Screen", "console panel"})
    local glow_switch = chimera_log_sub:switch("glow")
    
    local text_case = "Default"
    local text_align = "Centered"
    local screen_pos_x = 0.5
    local screen_pos_y = 0.8
    local display_duration = 6
    local max_logs = 6
    
    local log_queue = {}
    local log_id = 0
    
    local hitgroups = {
        [0] = "generic", [1] = "head", [2] = "chest", [3] = "stomach",
        [4] = "left arm", [5] = "right arm", [6] = "left leg", [7] = "right leg",
        [8] = "neck", [10] = "gear"
    }
    
    local weapon_names = {
        hegrenade = "Naded", inferno = "Mollied",
        taser = "Tased", knife = "Knifed"
    }
    
    local miss_reasons = {
        correction = "resolver"
    }
    
    local function add_log(text, to_console)
        if not chimera_log:get() then return end
        
        if to_console ~= false then
            print_raw("\aBC838300neverlose \a888888FF· \aC5CAD0FF" .. text)
            if to_console == true then return end
        end
        
        if output_select:get("On Screen") then
            log_id = log_id + 1
            
            local processed_text = text
            if text_case == "Upper" then
                processed_text = text:upper()
            elseif text_case == "Lower" then
                processed_text = text:lower()
            end
            
            table.insert(log_queue, {
                time = -1,
                offset = -1,
                pct = 0,
                text = processed_text,
                id = log_id
            })
            
            table.sort(log_queue, function(a, b) return a.id > b.id end)
        end
        
        if output_select:get("Console Panel") then
            print_dev(text)
        end
    end
    
    add_log(string.format("Welcome, \a%s%s\aFFFFFFFF!", text_color:get():to_hex(), common.get_username()))
    
    local function on_player_hurt(event)
        if not events_select:get("Damage Dealt") then return end
        
        local local_player = entity.get_local_player()
        if not local_player then return end
        
        local victim = entity.get(event.userid, true)
        local attacker = entity.get(event.attacker, true)
        
        if not victim or local_player ~= attacker then return end
        
        local hitgroup = hitgroups[event.hitgroup] or "GENERIC"
        local weapon = weapon_names[event.weapon] or "Hit"
        
        local color = text_color:get()
        
        local log_msg = string.format(
            "\aFFFFFFFF%s \a%s%s%s\aFFFFFFFF for \a%s%d damage\aFFFFFFFF (\a%s%d health remaining\aFFFFFFFF)",
            weapon,
            color:to_hex(),
            victim:get_name():sub(1, 32),
            weapon == "Hit" and " \aFFFFFFFFin the \a" .. color:to_hex() .. hitgroup or "",
            color:to_hex(),
            event.dmg_health,
            color:to_hex(),
            event.health
        )
        
        add_log(log_msg, false)
    end
    
    events.aim_ack:set(function(shot)
        if not chimera_log:get() then return end
        if not events_select:get("Aimbot") then return end
        
        local color_hex = text_color:get():to_hex()
        
        if shot.state then
            local reason = miss_reasons[shot.state] or shot.state
            local log_msg = string.format(
                "Missed shot at \a%s%s\aFFFFFFFF's \a%s%s\aFFFFFFFF(\a%s%d%%\aFFFFFFFF) due to \a%s%s",
                color_hex, shot.target:get_name(),
                color_hex, hitgroups[shot.wanted_hitgroup] or "unknown",
                color_hex, shot.hitchance,
                color_hex, reason
            )
            add_log(log_msg, true)
        else
            local log_msg = string.format(
                "Hit \a%s%s\aFFFFFFFF's \a%s%s\aFFFFFFFF for \a%s%d\aFFFFFFFF aimed=\a%s%s(\a%s%d%%)",
                color_hex, shot.target:get_name():sub(1, 32),
                color_hex, hitgroups[shot.hitgroup] or "unknown",
                color_hex, shot.damage,
                color_hex, hitgroups[shot.wanted_hitgroup] or "unknown",
                color_hex, shot.hitchance
            )
            add_log(log_msg, true)
        end
    end)
    
    local function on_item_purchase(event)
        if not events_select:get("Purchases") then return end
        
        local player = entity.get(event.userid, true)
        if not player or not player:is_enemy() then return end
        if event.weapon == "unknown" or event.weapon == "weapon_unknown" then return end
        
        local weapon_name = string.match(event.weapon, "^.+_(.*)$") or event.weapon
        local log_msg = string.format(
            "\a%s%s \aFFFFFFFFbought \a%s%s",
            text_color:get():to_hex(),
            player:get_name():sub(1, 32),
            text_color:get():lerp(color(), 0.5):to_hex(),
            weapon_name
        )
        
        add_log(log_msg)
    end
    
    local function render_screen_logs()
        if not output_select:get("On Screen") then return end
        if #log_queue == 0 then return end
        
        local frametime = globals.frametime or 0.01
        local realtime = globals.realtime or os.clock()
        local screen_size = render.screen_size()
        local base_pos = vector(screen_size.x * screen_pos_x, screen_size.y * screen_pos_y)
        
        local font = 1
        local font_flags = "d"
        local line_height = render.measure_text(font, font_flags, "Sample text").y * 1.04
        
        local fade_in_speed = frametime * 5
        local fade_out_speed = frametime * 2
        local move_speed = frametime * 10
        
        local current_offset = 0
        
        for i = #log_queue, 1, -1 do
            local log = log_queue[i]
            
            if log.offset == -1 then
                log.offset = current_offset
            end
            
            if log.offset < current_offset then
                log.offset = math.min(log.offset + move_speed, current_offset)
            elseif log.offset > current_offset then
                log.offset = math.max(log.offset - move_speed, current_offset)
            end
            
            if log.offset >= max_logs then
                table.remove(log_queue, i)
                goto next_log
            end
            
            local is_fading = false
            
            if log.time == -1 then
                log.pct = math.min(log.pct + fade_in_speed, 1)
                if log.pct == 1 then
                    log.time = realtime
                end
            else
                if realtime - log.time > display_duration then
                    log.pct = math.max(log.pct - fade_out_speed, 0)
                    is_fading = true
                end
                if log.pct == 0 then
                    table.remove(log_queue, i)
                    goto next_log
                end
            end
            
            local text_size = render.measure_text(font, font_flags, log.text)
            local progress = is_fading and (1 - (1 - log.pct) ^ 2) or log.pct ^ 2
            local animated_width = text_size.x * progress
            
            local text_pos = vector(
                base_pos.x - (text_align == "Centered" and animated_width * 0.5 or text_align == "Right-Aligned" and animated_width or 0),
                base_pos.y + log.offset * line_height
            )
            
            if glow_switch:get() then
                local glow_color = text_color:get():lerp(color(), 0.5) * log.pct
                glow_color.a = glow_color.a * 0.2
                render.shadow(
                    text_pos + vector(0, text_size.y * 0.5),
                    text_pos + vector(animated_width, text_size.y * 0.5),
                    glow_color, 50, 0
                )
                glow_color.a = glow_color.a * 0.275
                render.rect(
                    text_pos + vector(0, text_size.y * 0.5),
                    text_pos + vector(animated_width, text_size.y * 0.5),
                    glow_color
                )
            end
            
            render.push_clip_rect(text_pos, text_pos + vector(animated_width, text_size.y), true)
            render.text(font, text_pos, color(255, 220 * progress), font_flags, log.text)
            render.pop_clip_rect()
            
            current_offset = current_offset + 1
            ::next_log::
        end
    end
    
    events.player_hurt:set(on_player_hurt)
    events.item_purchase:set(on_item_purchase)
    events.render:set(render_screen_logs)
    
    _G.chimera_log = add_log
end

local misc_other_group = ui.find("Aimbot", "Ragebot", "Main")

if misc_other_group then
    local dormant_aimbot = misc_other_group:switch("* dormant aimbot", false)
    local dormant_aimbot_sub = dormant_aimbot:create()
    local hitbox_select = dormant_aimbot_sub:selectable("Dormant target hitbox", {"Head", "Chest", "Stomach"})
    local hitchance_slider = dormant_aimbot_sub:slider("Dormant aimbot hit chance", 0, 100, 75, 1, "%")
    local max_seed_slider = dormant_aimbot_sub:slider("MAX_SEED (MAY AFFECT FPS)", 1, 512, 256)
    local min_damage_slider = dormant_aimbot_sub:slider("Dormant minimum damage", 0, 120, 15, nil, function(i)
        if i == 0 then return "Inherited" end
        if i > 100 then return "HP + " .. i - 100 end
        return tostring(i)
    end)
    local prefer_body_aim = dormant_aimbot_sub:switch("Dormant prefer body aim", false)
    
    local global_min_damage = ui.find("Aimbot", "Ragebot", "Selection", "Global", "Min. Damage")
    
    local function trace_bullet(ent, src, dest)
        local damage, tr = utils.trace_bullet(ent, src, dest, function(player)
            return player:is_enemy() and player:is_dormant()
        end)
        
        if not tr.entity or not tr.entity:is_enemy() then
            return 0, tr
        end
        
        if damage == 0 or tr.entity == nil then
            return 0, tr
        end
        
        if tr:is_visible() then
            return 0, tr
        end
        
        return damage, tr
    end
    
    local function create_multipoints(from, to, radius)
        local angles = from:to(to):angles()
        local radian = math.rad(angles.y + 90)
        
        local forward = vector(math.cos(radian), math.sin(radian), 0)
        local direction = forward * radius
        
        return {
            { text = "Middle", vec = to },
            { text = "Left", vec = to + direction },
            { text = "Right", vec = to - direction }
        }
    end
    
    local function hitchance_check(angle, position, chance, max_seed)
        local me = entity.get_local_player()
        if not me or not me:is_alive() then return false end
        
        local weapon = me:get_player_weapon()
        if not weapon then return false end
        
        local src = me:get_eye_position()
        
        local forward = vector()
        local pitch, yaw = math.rad(angle.x), math.rad(angle.y)
        forward = vector(
            math.cos(pitch) * math.cos(yaw),
            math.cos(pitch) * math.sin(yaw),
            -math.sin(pitch)
        )
        
        local right, up = forward:vectors()
        
        local needed_hits = math.ceil((chance * max_seed) / 100)
        local weap_spread = weapon:get_spread()
        local weap_inaccuracy = weapon:get_inaccuracy()
        local hits = 0
        
        for i = 1, max_seed do
            local a = utils.random_float(0, 1)
            local b = utils.random_float(0, 2 * math.pi)
            local c = utils.random_float(0, 1)
            local d = utils.random_float(0, 2 * math.pi)
            
            local inaccuracy = a * weap_inaccuracy
            local spread = c * weap_spread
            
            local spread_vec = vector(
                math.cos(b) * inaccuracy + math.cos(d) * spread,
                math.sin(b) * inaccuracy + math.sin(d) * spread,
                0
            )
            
            local direction = (forward + right * -spread_vec.x + up * -spread_vec.y):normalized()
            local damage, trace = trace_bullet(me, src, position)
            
            if position:dist_to_ray(src, direction) < 25 and damage ~= 0 and trace.fraction < 1 then
                hits = hits + 1
            end
            
            if hits >= needed_hits then
                return true
            end
            
            if (max_seed - i + hits) < needed_hits then
                return false
            end
        end
        
        return false
    end
    
    local function predict_movement(local_player, point)
        local sim_time = local_player:get_simulation_time()
        local current, old = sim_time.current, sim_time.old
        local ticks = globals.to_ticks(current - old)
        local ctx = local_player:simulate_movement()
        ctx:think(ticks)
        
        if ctx.did_hit_collision then
            ctx:think(1)
        end
        
        local damage = trace_bullet(local_player, ctx.origin + vector(0, 0, ctx.view_offset), point)
        return damage
    end
    
    local hitpoints = {
        { name = "Head", index = 0, radius = 1 },
        { name = "Chest", index = 6, radius = 6 },
        { name = "Stomach", index = 4, radius = 5 }
    }
    
    local aim_cache = {
        player = nil,
        points = {},
        best_point = nil
    }
    
    local function reset_cache()
        aim_cache.player = nil
        aim_cache.points = {}
        aim_cache.best_point = nil
    end
    
    local function build_points(local_player, player, weapon)
        aim_cache.points = {}
        aim_cache.player = player
        
        local point_list = {}
        for idx, point in ipairs(hitpoints) do
            if hitbox_select:get(idx) then
                table.insert(point_list, {
                    name = point.name,
                    position = player:get_hitbox_position(point.index),
                    radius = point.radius
                })
            end
        end
        
        local eye_pos = local_player:get_eye_position()
        
        for _, point in ipairs(point_list) do
            local pts = create_multipoints(eye_pos, point.position, point.radius)
            
            for _, p in ipairs(pts) do
                local damage, _ = trace_bullet(local_player, eye_pos, p.vec)
                
                if point.index == 0 then
                    damage = damage * 4
                end
                
                table.insert(aim_cache.points, {
                    predictive = predict_movement(local_player, p.vec),
                    damage = damage,
                    position = p.vec
                })
            end
        end
    end
    
    local function get_best_point(cmd, local_player, player)
        if #aim_cache.points == 0 then
            return nil
        end
        
        local health = player.m_iHealth
        local desired_damage = min_damage_slider:get()
        
        if desired_damage == 0 and global_min_damage then
            desired_damage = global_min_damage:get()
        end
        
        if desired_damage >= 100 then
            desired_damage = desired_damage - 100 + health
        end
        
        table.sort(aim_cache.points, function(a, b) return a.damage > b.damage end)
        
        for _, point in ipairs(aim_cache.points) do
            if point.predictive > 0 then
                local on_ground = bit.band(local_player.m_fFlags, bit.lshift(1, 0)) == 1
                local has_velocity = local_player.m_vecVelocity:length2d() >= 5
                if on_ground and has_velocity and cmd then
                    cmd.block_movement = 1
                end
                point.predictive = 0
            end
            
            if point.damage < desired_damage then
                break
            end
            
            if prefer_body_aim:get() and (point.damage >= health or point.damage >= 1) then
                aim_cache.best_point = point
                return point
            end
            
            aim_cache.best_point = point
            return point
        end
        
        return nil
    end
    
    events.createmove:set(function(cmd)
        if not dormant_aimbot:get() then
            reset_cache()
            return
        end
        
        local me = entity.get_local_player()
        if not me or not me:is_alive() then
            reset_cache()
            return
        end
        
        local weapon = me:get_player_weapon()
        if not weapon then
            reset_cache()
            return
        end
        
        local weapon_info = weapon:get_weapon_info()
        if not weapon_info then
            reset_cache()
            return
        end
        
        local eye_pos = me:get_eye_position()
        local sim_time = me:get_simulation_time().current
        local hitchance = hitchance_slider:get()
        local max_seed = max_seed_slider:get()
        
        local can_shoot = false
        if weapon_info.is_revolver then
            can_shoot = weapon.m_flNextPrimaryAttack < sim_time
        else
            can_shoot = math.max(me.m_flNextAttack, weapon.m_flNextPrimaryAttack, weapon.m_flNextSecondaryAttack) < sim_time
        end
        
        if not can_shoot then
            return
        end
        
        local target_found = false
        
        entity.get_players(true, true, function(player)
            if target_found then return end
            if not player or not player:is_alive() then
                reset_cache()
                return
            end
            
            if not player:is_dormant() or not player:is_enemy() then
                reset_cache()
                return
            end
            
            local bbox = player:get_bbox()
            if bbox.alpha <= 0 or player:get_network_state() == 5 then
                reset_cache()
                return
            end
            
            build_points(me, player, weapon)
            
            local point = get_best_point(cmd, me, player)
            if not point or not point.damage or point.damage <= 0 then
                return
            end
            
            local position = point.position
            if position == vector() then
                return
            end
            
            local angle = eye_pos:to(position):angles()
            
            local on_ground = not cmd.in_jump and bit.band(me.m_fFlags, bit.lshift(1, 0)) == 1
            local is_scoped = me.m_bIsScoped or me.m_bResumeZoom
            local is_sniper = weapon_info.weapon_type == 5
            
            if not is_scoped and is_sniper and on_ground then
                cmd.in_attack2 = true
            end
            
            if hitchance_check(angle, position, hitchance, max_seed) then
                local recoil_scale = cvar.weapon_recoil_scale:float() or 1.0
                cmd.view_angles = angle - (me.m_aimPunchAngle * recoil_scale)
                cmd.in_attack = true
                target_found = true
            end
        end)
    end)
end

local misc_other_group = ui.find("Miscellaneous", "Main", "Other")

if misc_other_group then
    local quick_switch_group = misc_other_group:create("quick switch")
    
    local quick_switch_enabled = quick_switch_group:switch("Quick Switch", false)
    
    local weapon_actions = ui.find("Miscellaneous", "Main", "Other", "Weapon Actions")
    local sv_infinite_ammo = cvar.sv_infinite_ammo
    
    local function override_auto_pistols()
        if quick_switch_enabled:get() then
            if weapon_actions then
                weapon_actions:override("Auto Pistols")
            end
        else
            if weapon_actions then
                weapon_actions:override()
            end
        end
    end
    
    local function switch_weapons()
        utils.console_exec("slot3; slot2; slot1")
    end
    
    local function on_grenade_thrown(event)
        if not quick_switch_enabled:get() then return end
        
        local local_player = entity.get_local_player()
        if not local_player then return end
        
        local thrower = entity.get(event.userid, true)
        if local_player ~= thrower then return end
        
        local net = utils.net_channel()
        local rtt = net.latency[0] or 0
        
        utils.execute_after(rtt * 1.4, switch_weapons)
    end
    
    local function on_weapon_fire(event)
        if not quick_switch_enabled:get() then return end
        
        if event.weapon ~= "weapon_taser" then return end
        
        if sv_infinite_ammo and sv_infinite_ammo:int() == 1 then return end
        
        local local_player = entity.get_local_player()
        if not local_player then return end
        
        local shooter = entity.get(event.userid, true)
        if local_player ~= shooter then return end
        
        local net = utils.net_channel()
        local rtt = net.latency[0] or 0
        
        utils.execute_after(rtt * 1.4, switch_weapons)
    end
    
    quick_switch_enabled:set_callback(function()
        override_auto_pistols()
    end, true)
    
    events.grenade_thrown:set(on_grenade_thrown)
    events.weapon_fire:set(on_weapon_fire)
end

local world_other = ui.find("Visuals", "World", "Other")
if not world_other then return end

local indicator = world_other:switch("slowdown indicator", false)
local sub = indicator:create()

local accent = sub:color_picker("accent color", color(147, 190, 255))

local pos_x = sub:slider("pos_x", 0, render.screen_size().x, render.screen_size().x * 0.5 - 75)
local pos_y = sub:slider("pos_y", 0, render.screen_size().y, render.screen_size().y * 0.35)
pos_x:visibility(false)
pos_y:visibility(false)

local indicator_state = {
    hover = false,
    dragging = false,
    drag_offset = vector(0, 0),
    position = vector(pos_x:get(), pos_y:get()),
    animations = {
        base_alpha = 0,
        background_alpha = 0,
        death_fade = 1,
        velocity_modifier = 1
    }
}

local function lerp(current, target, speed)
    return current + (target - current) * math.min(globals.frametime * speed, 1)
end

local function handle_input()
    local menu_alpha = l_pui_0.get_alpha()
    if menu_alpha == 0 then return end
    
    local mouse_pos = l_pui_0.get_mouse_position()
    local mouse_down = common.is_button_down(1)
    local bar_w = 150
    local height = 23
    local padding = 6
    
    local is_hover = mouse_pos.x >= indicator_state.position.x - padding and
                     mouse_pos.x <= indicator_state.position.x + bar_w + padding and
                     mouse_pos.y >= indicator_state.position.y - padding and
                     mouse_pos.y <= indicator_state.position.y + height + padding
    
    indicator_state.hover = is_hover
    
    if mouse_down and is_hover and not indicator_state.dragging then
        indicator_state.dragging = true
        indicator_state.drag_offset = mouse_pos - indicator_state.position
    end
    
    if indicator_state.dragging then
        if mouse_down then
            local new_pos = mouse_pos - indicator_state.drag_offset
            new_pos.x = math.max(0, math.min(render.screen_size().x - bar_w, new_pos.x))
            new_pos.y = math.max(0, math.min(render.screen_size().y - height, new_pos.y))
            indicator_state.position = new_pos
            pos_x:set(new_pos.x)
            pos_y:set(new_pos.y)
        else
            indicator_state.dragging = false
        end
    end
end

local function render_indicator()
    if not indicator:get() then
        return
    end
    
    local menu_alpha = l_pui_0.get_alpha()
    local local_player = entity.get_local_player()
    
    if not local_player and menu_alpha == 0 then
        return
    end
    
    local is_alive = local_player and local_player:is_alive() or menu_alpha == 1
    local velocity_modifier = menu_alpha == 1 and 0.5 or (local_player and local_player.m_flVelocityModifier or 1)
    local death_target = is_alive and 1 or 0
    
    indicator_state.animations.death_fade = lerp(indicator_state.animations.death_fade, death_target, 10)
    
    local alpha_target = (indicator_state.dragging or menu_alpha > 0 or velocity_modifier < 1) and 255 or 0
    indicator_state.animations.base_alpha = lerp(indicator_state.animations.base_alpha, alpha_target * indicator_state.animations.death_fade, 10)
    
    if indicator_state.animations.base_alpha < 1 then
        return
    end
    
    indicator_state.animations.velocity_modifier = lerp(indicator_state.animations.velocity_modifier, velocity_modifier, 8)
    
    handle_input()
    
    local accent_color = (accent:get() or color(147, 190, 255)):alpha_modulate(indicator_state.animations.base_alpha)
    local text_color = color(255, 255, 255):alpha_modulate(indicator_state.animations.base_alpha)
    local bg_color = color(0, 0, 0):alpha_modulate(math.min(200, indicator_state.animations.base_alpha))
    
    local reduced_percent = math.floor((1 - indicator_state.animations.velocity_modifier) * 100)
    local text = string.format("Max velocity reduced by %d%%", reduced_percent)
    
    local bar_width = 150
    local bar_height = 6
    
    local hover_target = 0
    if indicator_state.hover and menu_alpha > 0 then
        hover_target = 0.3
    end
    if indicator_state.dragging then
        hover_target = 0.5
    end
    indicator_state.animations.background_alpha = lerp(indicator_state.animations.background_alpha, hover_target, 8)
    
    if indicator_state.animations.background_alpha > 0.01 then
        local bg_white = color(255, 255, 255, math.floor(indicator_state.animations.background_alpha * 40))
        local shadow_color = color(0, 0, 0, math.floor(indicator_state.animations.background_alpha * 20))
        local padding = 8
        local extra_height = 15 + bar_height + 2
        render.shadow(indicator_state.position - vector(padding, padding), 
                     indicator_state.position + vector(bar_width + padding, extra_height + padding), 
                     shadow_color, 20, 2, 4)
        render.rect(indicator_state.position - vector(padding, padding), 
                   indicator_state.position + vector(bar_width + padding, extra_height + padding), 
                   bg_white, 4)
        render.rect_outline(indicator_state.position - vector(padding, padding), 
                          indicator_state.position + vector(bar_width + padding, extra_height + padding), 
                          color(255, 255, 255, math.floor(indicator_state.animations.background_alpha * 60)), 1, 4)
    end
    
    render.text(1, indicator_state.position, text_color, nil, text)
    
    local bar_pos = indicator_state.position + vector(0, 15)
    local bar_end = bar_pos + vector(bar_width, bar_height)
    render.rect(bar_pos - 1, bar_end + 1, bg_color, 2)
    render.shadow(bar_pos - 1, bar_end + 1, accent_color, 25, 0, 3)
    
    local fill_width = bar_width * (1 - indicator_state.animations.velocity_modifier)
    render.rect(bar_pos + 1, bar_pos + vector(fill_width, bar_height) - 1, accent_color, 2)
end

events.render:set(render_indicator)

local misc_ingame_group = ui.find("Miscellaneous", "Main", "In-Game")

if misc_ingame_group then
    local clientside_nickname = misc_ingame_group:switch("clientside nickname", false)
    local nickname_sub = clientside_nickname:create()

    local nickname_input = nickname_sub:input("nickname", "advent")

    local was_applied = false
    local previous_name = nil

    local native_BaseLocalClient_base = ffi.cast("uintptr_t**", utils.opcode_scan("engine.dll", "A1 ? ? ? ? 0F 28 C1 F3 0F 5C 80 ? ? ? ? F3 0F 11 45 ? A1 ? ? ? ? 56 85 C0 75 04 33 F6 EB 26 80 78 14 00 74 F6 8B 4D 08 33 D2 E8 ? ? ? ? 8B F0 85 F6", 1))
    
    local player_info_t = ffi.typeof([[
        struct {
            int64_t         unknown;
            int64_t         steamID64;
            char            szName[128];
            int             userId;
            char            szSteamID[20];
            char            pad_0x00A8[0x10];
            unsigned long   iSteamID;
            char            szFriendsName[128];
            bool            fakeplayer;
            bool            ishltv;
            unsigned int    customfiles[4];
            unsigned char   filesdownloaded;
        }
    ]])
    
    local native_GetStringUserData = utils.get_vfunc(11, ffi.typeof("$*(__thiscall*)(void*, int, int*)", player_info_t))

    local function apply_nickname(nickname)
        local local_player = entity.get_local_player()
        if not local_player or not local_player:is_alive() then
            return
        end
        
        local native_BaseLocalClient = native_BaseLocalClient_base[0][0]
        if not native_BaseLocalClient then
            return
        end
        
        local native_UserInfoTable = ffi.cast("void***", native_BaseLocalClient + 21184)[0]
        if not native_UserInfoTable then
            return
        end
        
        local data = native_GetStringUserData(native_UserInfoTable, local_player:get_index() - 1, nil)
        if not data then
            return
        end
        
        local current_name = ffi.string(data[0].szName)
        
        if nickname ~= current_name and previous_name == nil then
            previous_name = current_name
        end
        
        ffi.copy(data[0].szName, nickname, #nickname + 1)
    end

    local function reset_nickname()
        if previous_name then
            apply_nickname(previous_name)
            previous_name = nil
        else
            apply_nickname(panorama.MyPersonaAPI.GetName())
        end
    end

    local function on_net_update()
        if not clientside_nickname:get() then
            return
        end
        
        local chosen_nick = nickname_input:get():sub(1, 32)
        
        if #chosen_nick == 0 then
            if was_applied then
                was_applied = false
                reset_nickname()
            end
            return
        else
            was_applied = true
            apply_nickname(chosen_nick)
        end
    end
    
    clientside_nickname:set_callback(function()
        if clientside_nickname:get() then
            events.net_update_start:set(on_net_update)
            events.net_update_end:set(on_net_update)
            events.shutdown:set(reset_nickname)
        else
            events.net_update_start:unset(on_net_update)
            events.net_update_end:unset(on_net_update)
            events.shutdown:unset(reset_nickname)
            reset_nickname()
        end
    end)
end
