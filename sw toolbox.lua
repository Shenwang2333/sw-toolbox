_DEBUG = true
local math = math or _G.math

local gradient = require("neverlose/gradient")

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
