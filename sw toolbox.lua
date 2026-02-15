local pui = require("neverlose/pui")

pui.colors.warn = color("#BABD5B");
pui.sidebar("\vsw\r toolbox", "\aFFFFFFFF\f<code>")

-- 辅助函数
_DEBUG = false;
_DISABLE_UI_EVENTS = false;

local v12 = nil;
local v18 = nil;

-- XOR
v12 = function(...)
    local v4 = "b1 c8 9a 05 4f 0e 3c 64";
    local v19 = table.concat({ ... });
    local v20 = #v19;
    local v21 = #v4;
    local v22 = ffi.new("char[?]", v20 + 1);
    local v23 = ffi.new("char[?]", v21 + 1);
    ffi.copy(v22, v19);
    ffi.copy(v23, v4);
    for v24 = 0, v20 - 1 do
        v22[v24] = bit.bxor(v22[v24], v23[v24 % v21]);
    end;
    return ffi.string(v22, v20);
end;

v18 = function(v35, ...)
    if not v35 then
        error("");
    end;
end;

-- 数值限制
local function v56(v53, v54, v55)
    return math.max(v54, math.min(v55, v53));
end;

-- 数值映射
local function v63(v57, v58, v59, v60, v61, v62)
    if v62 == true then v57 = v56(v57, v58, v59); end
    return v60 + (v57 - v58) * (v61 - v60) / (v59 - v58);
end;

-- 事件回调处理
local function v102(v91, v92, v93, v94, ...)
    local l_v93_0 = v93;
    if l_v93_0 == nil then l_v93_0 = true; end
    v18(type(v91) == "userdata", "invalid userdata");
    v18(type(v92) == "function", "invalid callback type");
    v18(type(l_v93_0) == "boolean", "invalid state type");
    local v96 = {};
    if l_v93_0 == true then
        if type(v91.set_callback) == "function" then
            v96 = { v91:set_callback(v92, ...) };
        elseif type(v91.set) == "function" then
            v96 = { v91:set(v92, ...) };
        end;
    elseif type(v91.unset_callback) == "function" then
        v96 = { v91:unset_callback(v92, ...) };
    elseif type(v91.unset) == "function" then
        v96 = { v91:unset(v92, ...) };
    end;
    return unpack(v96);
end;

local no_fall_damage_state = false;
local fast_ladder_state = false;
local super_toss_state = false;
local grenade_warning_state = false;
local grenade_warning_data = {};
local grenade_warning_pred_pos = nil;
local mp_friendlyfire = cvar.mp_friendlyfire;
local visualize_exploits_state = false;
local visualize_exploits_color = color(255,0,0,255);
local visualize_exploits_thickness = 0.35;
local keep_transparency_state = false;
local keep_transparency = { transparency = 255 };
local no_blood_state = false;
local violence_ablood = cvar.violence_ablood;
local violence_hblood = cvar.violence_hblood;
local violence_agibs = cvar.violence_agibs;
local violence_hgibs = cvar.violence_hgibs;
local blood_original_values = {
    ablood = nil,
    hblood = nil,
    agibs = nil,
    hgibs = nil
};

-- 存储子元素引用的变量
local visualize_exploits_color_picker = nil;
local visualize_exploits_thickness_slider = nil;
local keep_transparency_scale_slider = nil;

-- No Fall Damage
local function no_fall_damage_init()
    local l_sv_gravity_0 = cvar.sv_gravity;
    local v165 = utils.get_vfunc(76, "float*(__thiscall*)(void*)");
    local v166 = utils.get_vfunc(77, "float*(__thiscall*)(void*)");
    
    local function v173(v167, v168, v169)
        local v170 = nil; local v171 = nil;
        v170 = v165(v167[0]);
        v171 = v166(v167[0]);
        v170 = vector(v170[0], v170[1], v170[2]);
        v171 = vector(v171[0], v171[1], 54);
        local v172 = utils.trace_hull(v168, v168 - vector(0, 0, v169), v170, v171, v167, 1);
        return v172.fraction < 1 and not v172.start_solid and not v172.all_solid and v172.plane.normal.z >= 0.69999999, v172;
    end;
    
    local function v181(v174, v175)
        local l_tickinterval_0 = globals.tickinterval;
        local v177 = l_sv_gravity_0:float() * l_tickinterval_0 * 0.5;
        local l_v174_0 = v174;
        local v179 = 0; local v180 = 0;
        while l_v174_0 > 11 do
            v179 = v175 - v177;
            v180 = l_tickinterval_0 * v179;
            v175 = v179 - v177;
            l_v174_0 = l_v174_0 + v180;
        end;
        return v175 <= -580 and l_v174_0 >= 9;
    end;
    
    local function v192(v182)
        if not no_fall_damage_state then return; end
        local v183 = entity.get_local_player();
        if v183 == nil then return; end
        local v184 = bit.band(v183.m_fFlags, 1) == 1;
        if v183.m_MoveType == 2 and not v184 then
            local v185 = v183:get_origin();
            if bit.band(v183.m_fFlags, 2) == 0 then v185.z = v185.z + 9; end
            local v186, v187 = v173(v183, v185, 1000);
            if v186 then
                local v188 = v187.fraction * 1000;
                local l_z_0 = v183.m_vecVelocity.z;
                if l_z_0 >= 0 or v188 >= 11 then
                    if not v181(v188, l_z_0) then return; end
                    v182.in_duck = 1;
                    v182.in_jump = 0;
                elseif l_z_0 < -580 and v188 > 9 then
                    v182.in_jump = 1;
                    v182.in_duck = 0;
                end;
            end;
        end;
    end;
    
    v102(events.createmove, v192, true, true);
end;

local function no_fall_damage_enabled(state)
    if type(state) == "boolean" then
        no_fall_damage_state = state;
        return;
    else
        return no_fall_damage_state;
    end;
end;

-- Fast Ladder
local function fast_ladder_init()
    local function v274(v265)
        if not fast_ladder_state then return; end
        if v265.sidemove ~= 0 or v265.forwardmove == 0 then return; end
        local v266 = entity.get_local_player();
        if v266 == nil then return; end
        if v266.m_MoveType ~= 9 or bit.band(v266.m_fFlags, 1) == 1 then return; end
        local v267 = v266:get_player_weapon();
        if v267 == nil then return; end
        local l_m_fThrowTime_0 = v267.m_fThrowTime;
        if l_m_fThrowTime_0 ~= nil and l_m_fThrowTime_0 > 0 then return; end
        local l_m_vecLadderNormal_0 = v266.m_vecLadderNormal;
        if l_m_vecLadderNormal_0:normalize() == 0 then return; end
        local l_view_angles_0 = v265.view_angles;
        local v271 = l_m_vecLadderNormal_0:angles();
        local v272 = v265.forwardmove > 0;
        local v273 = math.normalize_yaw(l_view_angles_0.y - v271.y) <= 0;
        if l_view_angles_0.x - v271.x > 45 then v272 = not v272; end
        v265.in_back = v272 and 1 or 0;
        v265.in_forward = v272 and 0 or 1;
        if v273 then
            v265.in_moveleft = v272 and 1 or 0;
            v265.in_moveright = v272 and 0 or 1;
        else
            v265.in_moveleft = v272 and 0 or 1;
            v265.in_moveright = v272 and 1 or 0;
        end;
        l_view_angles_0.x = 89;
        l_view_angles_0.y = v271.y + (v273 and 90 or -90);
    end;
    
    v102(events.createmove, v274, true, true);
end;

local function fast_ladder_enabled(state)
    if type(state) == "boolean" then
        fast_ladder_state = state;
        return;
    else
        return fast_ladder_state;
    end;
end;

-- Super Toss
local function super_toss_init()
    local function v354(v350)
        local v351 = v350:get_weapon_info();
        if v351 == nil then return; end
        local l_m_flThrowStrength_0 = v350.m_flThrowStrength;
        if l_m_flThrowStrength_0 == nil then return; end
        l_m_flThrowStrength_0 = l_m_flThrowStrength_0 * 0.7 + 0.3;
        return v56(v351.throw_velocity * 0.9, 15, 750) * l_m_flThrowStrength_0;
    end;
    
    local function v366(v355, v356, v357, v358)
        local v359 = entity.get_local_player();
        if v359 == nil then return; end
        local v360 = v359:get_player_weapon();
        if v360 == nil then return; end
        if v360.m_flThrowStrength == nil then return; end
        local v361 = vector():angles(vector(v357.x, v357.y));
        local v362 = v356:length();
        local v363 = v361:dot(-v356:normalized());
        local v364 = ((math.sqrt(25 * v363 * v363 * v362 * v362 + 16 * v355 * v355 - 25 * v362 * v362) - 5 * v362 * v363) * 0.25 * v361 - v356 * 1.25) * (1 / v355);
        if v364.y == 0 and v364.x == 0 then
            if v364.z <= 0 then v357.x = 90; else v357.x = 270; end
        elseif v364.x ~= v364.x or v364.y ~= v364.y or v364.z ~= v364.z then
            return;
        else
            local v365 = v364:angles();
            v357.x = v365.x;
            v357.y = v365.y;
        end;
    end;
    
    local function v377(v367)
        if not super_toss_state then return; end
        local v368 = entity.get_local_player();
        if v368 == nil then return; end
        local v369 = v368:get_player_weapon();
        if v369 == nil then return; end
        local v370 = v354(v369);
        if v370 == nil then return; end
        local v371 = to_ticks(v369.m_fThrowTime or 0);
        local _, v373 = rage.exploit:get(true);
        local v374 = v371 - v373 - v368.m_nTickBase;
        if v374 <= -1 and -to_ticks(1) < v374 then v367.in_speed = true; end
        local v376 = v368:simulate_movement();
        v376:think();
        v366(v370, v376.velocity:clone(), v367.view_angles, v367.move_yaw);
    end;
    
    v102(events.createmove, v377, true, true);
end;

local function super_toss_enabled(state)
    if type(state) == "boolean" then
        super_toss_state = state;
        return;
    else
        return super_toss_state;
    end;
end;

-- Grenade Proximity Warning
local function grenade_warning_init()
    local he_icon = render.load_image_from_file("materials/panorama/images/icons/equipment/hegrenade.svg");
    local molly_icon = render.load_image_from_file("materials/panorama/images/icons/equipment/inferno.svg");
    local warn_font = render.load_font("Verdana Bold", vector(10, 11.6), "a");
    local color_danger = color("BE0000FF");
    local color_bg = color("000000D2");
    local color_mid = color("323232BE");
    local color_text = color("FFFFFFC8");
    local function world_to_screen(pos)
        return render.world_to_screen(pos);
    end;
    
    local function clamp_to_screen(screen_pos, margin)
        margin = margin or 50;
        if screen_pos.x < margin then screen_pos.x = margin; end
        if screen_pos.x > render.screen_size().x - margin then screen_pos.x = render.screen_size().x - margin; end
        if screen_pos.y < margin then screen_pos.y = margin; end
        if screen_pos.y > render.screen_size().y - margin then screen_pos.y = render.screen_size().y - margin; end
        return screen_pos;
    end;
    
    local function get_screen_pos(world_pos)
        local screen_pos = world_to_screen(world_pos);
        if screen_pos then
            return clamp_to_screen(screen_pos);
        end;
        return nil;
    end;
    
    local function get_size_by_distance(dist)
        dist = math.clamp(dist, 36, 200);
        local size = math.ceil(50 - (dist - 36) * 20 / 164);
        return v63(size, 30, 50, 0, 1);
    end;
    
    local function get_observer_pos()
        local local_player = entity.get_local_player();
        if local_player == nil then return; end
        return local_player:is_alive() and local_player:get_origin() or render.camera_position();
    end;
    
    local function draw_warning(pos, bg_color, color1, progress, size, icon, text)
        local circle_size = v63(size, 0, 1, 30, 50, true);
        local icon_size = vector(icon.width, icon.height);
        local text_pos = pos - icon_size * 0.5 - vector(0, 11);
        render.circle_gradient(pos, bg_color, bg_color:lerp(color1, 1), circle_size, 0, 1);
        render.circle_outline(pos, color_text, circle_size - 0.5, 0, progress, 2);
        render.texture(icon, text_pos, icon_size, color_text);
        render.text(warn_font, pos + vector(0, 15), color_text, "cs", text);
    end;
    
    local function should_show_for_entity(ent)
        if ent == nil then return true; end
        local is_enemy = ent:is_enemy();
        if is_enemy or ent == entity.get_local_player() then return true; end
        if not is_enemy and mp_friendlyfire:int() == 1 then return true; end
        return false;
    end;
    
    local function on_grenade_warning(data)
        grenade_warning_data[data.entity:get_index()] = {
            tick = globals.tickcount,
            entity = data.entity,
            origin = data.origin,
            closest_point = data.closest_point,
            type = data.type,
            damage = data.damage,
            expire_time = data.expire_time,
            icon = data.icon,
            path = data.path
        };
        return false;
    end;
    
    local function update_predicted_pos()
        local local_player = entity.get_local_player();
        if local_player == nil then return; end
        local sim = local_player:simulate_movement();
        sim:think(to_ticks(0.2));
        grenade_warning_pred_pos = sim.origin:clone();
    end;
    
    local function render_warning()
        if not grenade_warning_state then return; end
        local local_player = entity.get_local_player();
        if local_player == nil then return; end
        
        local current_tick = globals.tickcount;
        local player_health = local_player.m_iHealth;
        local observer_pos = get_observer_pos();
        
        if not local_player:is_alive() then
            grenade_warning_pred_pos = observer_pos;
        end;
        
        local pred_pos = grenade_warning_pred_pos or observer_pos;
        
        for idx, data in pairs(grenade_warning_data) do
            if math.abs(data.tick - current_tick) > 1 then
                grenade_warning_data[idx] = nil;
            elseif #data.path > 0 then
                local last_pos = data.path[#data.path];
                if last_pos ~= nil then
                    local dist_to_pred = pred_pos:dist(last_pos);
                    local dist_to_observer = observer_pos:dist(last_pos);
                    local screen_pos = get_screen_pos(last_pos);
                    
                    if screen_pos ~= nil then
                        local size = get_size_by_distance(dist_to_pred);
                        
                        if data.type == "Frag" and (data.damage > 0 or dist_to_pred < 350 or dist_to_observer < 350) then
                            local time_left = (data.expire_time - globals.curtime) / 1.5;
                            local damage_ratio = math.clamp(data.damage / math.min(50, player_health), 0, 1);
                            local fill_color = nil;
                            local danger_level = data.damage >= 1 and damage_ratio or 0;
                            
                            if danger_level < 0.01 then
                                fill_color = color_bg;
                            else
                                fill_color = color_mid:lerp(color_danger, v63(danger_level, 0, 0.5, 0, 1, true));
                            end;
                            
                            draw_warning(screen_pos, color_bg, fill_color, time_left, size, he_icon, tostring(data.damage));
                        end;
                        
                        if data.type == "Molly" then
                            local dist_in_feet = dist_to_observer / 12;
                            if dist_in_feet <= 34 then
                                local start_time = ffi.cast("float*", ffi.cast("uint32_t", data.entity[0]) + 728)[0];
                                local progress = v63(globals.curtime, start_time, data.expire_time, 1, 0, true);
                                local danger_color = dist_in_feet <= 12.5 and color_danger or color_bg;
                                draw_warning(screen_pos, color_bg, danger_color, progress, size, molly_icon, tostring(math.floor(dist_in_feet)));
                            end;
                        end;
                    end;
                end;
            end;
        end;
        
        entity.get_entities("CInferno", false, function(inferno)
            if not should_show_for_entity(inferno.m_hOwnerEntity) then return; end
            
            local origin = inferno:get_origin();
            local screen_pos = get_screen_pos(origin);
            if screen_pos == nil or inferno.m_nFireEffectTickBegin == nil then return; end
            
            local dist_to_observer = observer_pos:dist(origin) / 12;
            local start_time = to_time(inferno.m_nFireEffectTickBegin);
            local progress = (7 - math.clamp(globals.curtime - start_time, 0, 7)) / 7;
            local closest_dist = observer_pos:dist(origin);
            local closest_pos = origin;
            
            for i = 1, inferno.m_fireCount do
                local fire_pos = origin + vector(
                    inferno.m_fireXDelta[i],
                    inferno.m_fireYDelta[i],
                    inferno.m_fireZDelta[i]
                );
                local fire_dist = observer_pos:dist(fire_pos);
                if fire_dist <= closest_dist then
                    closest_dist = fire_dist;
                    closest_pos = fire_pos;
                end;
            end;
            
            if closest_pos ~= nil then
                local dist_in_feet = closest_dist / 12;
                if dist_to_observer <= 34 then
                    local size = get_size_by_distance(closest_dist);
                    local danger_color = dist_in_feet <= 12.5 and color_danger or color_bg;
                    local pos = get_screen_pos(closest_pos);
                    draw_warning(pos, color_bg, danger_color, progress, size, molly_icon, tostring(math.floor(dist_in_feet)));
                end;
            end;
        end);
    end;
    
    v102(events.render, render_warning, true, true);
    v102(events.createmove, update_predicted_pos, true, true);
    v102(events.grenade_warning, on_grenade_warning, true, true);
end;

local function grenade_warning_enabled(state)
    if type(state) == "boolean" then
        grenade_warning_state = state;
        return;
    else
        return grenade_warning_state;
    end;
end;

-- Visualize Exploits
local function visualize_exploits_init()
    local lagrecord = nil;
    pcall(function() lagrecord = require("neverlose/lagrecord"); end);
    if lagrecord == nil then return; end
    lagrecord = lagrecord ^ lagrecord.SIGNED;
    
    local edges = {
        {0,1}, {1,2}, {2,3}, {3,0},
        {5,6}, {6,7}, {1,4}, {4,8},
        {0,4}, {1,5}, {2,6}, {3,7},
        {5,8}, {7,8}, {3,4}
    };
    
    local function draw_bounding_box(ctx, offset, bbox, clr, thickness)
        if ctx == nil or offset == nil or bbox == nil then return; end
        if clr == nil then clr = color(); end
        if thickness == nil then thickness = 0.15; end
        
        local points = {
            bbox[1] + offset,
            bbox[2] + offset
        };
        
        local vertices = {
            vector(points[1].x, points[1].y, points[1].z),
            vector(points[1].x, points[2].y, points[1].z),
            vector(points[2].x, points[2].y, points[1].z),
            vector(points[2].x, points[1].y, points[1].z),
            vector(points[1].x, points[1].y, points[2].z),
            vector(points[1].x, points[2].y, points[2].z),
            vector(points[2].x, points[2].y, points[2].z),
            vector(points[2].x, points[1].y, points[2].z)
        };
        
        for _, edge in ipairs(edges) do
            if vertices[edge[1]] and vertices[edge[2]] then
                local v1 = vertices[edge[1]];
                local v2 = vertices[edge[2]];
                if v1:length2dsqr() > 0 and v2:length2dsqr() > 0 then
                    ctx:render(v1, v2, thickness, "lgw", clr);
                end;
            end;
        end;
    end;
    
    local function on_render_glow(ctx)
        if not visualize_exploits_state then return; end
        local local_player = entity.get_local_player();
        if local_player == nil or lagrecord == nil then return; end
        
        entity.get_players(true, false, function(player)
            if player:get_bbox().pos1 == nil then return; end
            local snapshot = lagrecord.get_snapshot(player);
            if snapshot == nil then return; end
            
            local no_entry = snapshot.command.no_entry;
            if no_entry.y > 0 then
                if local_player.m_hObserverTarget == player and local_player.m_iObserverMode == 5 then
                    return;
                end;
                local origin = snapshot.origin;
                draw_bounding_box(
                    ctx, 
                    origin.current, 
                    origin.volume, 
                    visualize_exploits_color, 
                    visualize_exploits_thickness * (no_entry.x / no_entry.y)
                );
            end;
        end);
    end;
    
    v102(events.render_glow, on_render_glow, true, true);
    
    local function on_update()
        pcall(lagrecord.set_update_callback, function(e) return e:is_enemy(); end);
    end;
    on_update();
end;

local function visualize_exploits_enabled(state, color_val, thickness_val)
    if type(state) == "boolean" then
        visualize_exploits_state = state;
        return;
    elseif type(color_val) == "userdata" then
        visualize_exploits_color = color_val:clone();
        return;
    elseif type(thickness_val) == "number" then
        visualize_exploits_thickness = thickness_val;
        return;
    else
        return visualize_exploits_state;
    end;
end;

-- Keep Model Transparency
local function keep_transparency_init()
    local function handler(transparency_value)
        local local_player = entity.get_local_player();
        if not local_player or not local_player:is_alive() then
            return transparency_value;
        elseif not keep_transparency_state then
            keep_transparency.transparency = 255;
            return transparency_value;
        else
            local weapon = local_player:get_player_weapon();
            if not weapon then
                return transparency_value;
            else
                local classname = weapon:get_classname() or "";
                if classname:find("Grenade") or classname:find("Flashbang") then
                    return transparency_value;
                else
                    local scale = keep_transparency_scale_slider and keep_transparency_scale_slider:get() or 10;
                    local is_scoped = local_player.m_bIsScoped or local_player.m_bResumeZoom;
                    
                    if is_scoped and keep_transparency.transparency > 60 then
                        keep_transparency.transparency = keep_transparency.transparency - scale;
                        if keep_transparency.transparency < 60 then
                            keep_transparency.transparency = 60;
                        end;
                    elseif not is_scoped and keep_transparency.transparency < 255 then
                        keep_transparency.transparency = keep_transparency.transparency + scale;
                        if keep_transparency.transparency > 255 then
                            keep_transparency.transparency = 255;
                        end;
                    end;
                    
                    return keep_transparency.transparency;
                end;
            end;
        end;
    end;
    
    events.localplayer_transparency(handler);
end;

local function keep_transparency_enabled(state)
    if type(state) == "boolean" then
        keep_transparency_state = state;
        return;
    else
        return keep_transparency_state;
    end;
end;

-- Remove Blood
local function save_original_blood_values()
    if blood_original_values.ablood == nil then
        blood_original_values.ablood = tonumber(violence_ablood:string()) or 1;
        blood_original_values.hblood = tonumber(violence_hblood:string()) or 1;
        blood_original_values.agibs = tonumber(violence_agibs:string()) or 1;
        blood_original_values.hgibs = tonumber(violence_hgibs:string()) or 1;
    end;
end;

local function set_blood_state(restore)
    if restore then
        if blood_original_values.ablood then
            violence_ablood:int(blood_original_values.ablood, true);
            violence_hblood:int(blood_original_values.hblood, true);
            violence_agibs:int(blood_original_values.agibs, true);
            violence_hgibs:int(blood_original_values.hgibs, true);
        end;
    else
        violence_ablood:int(0, true);
        violence_hblood:int(0, true);
        violence_agibs:int(0, true);
        violence_hgibs:int(0, true);
        cvar.r_cleardecals:call();
    end;
end;

local function no_blood_enabled(state)
    if type(state) == "boolean" then
        if state ~= no_blood_state then
            if state == false then
                set_blood_state(true);
            end;
            no_blood_state = state;
            if state == true then
                save_original_blood_values();
                set_blood_state(false);
            end;
        end;
        return;
    else
        return no_blood_state;
    end;
end;

--ui
local v1 = new_class():struct("references")({
}):struct("main")({
    init = function(v2)
        v2.groups = {
            main = pui.create("\v\239\138\189", "main", 1), 
            info = pui.create("\v\239\138\189", "Information", 2), 
            features = pui.create("\v\239\138\189", "Features"),
            visuals = pui.create("\v\239\138\189", "Visuals"),
            world = pui.create("\v\239\138\189", "World")
        };
        v2.elements = {
            warning = v2.groups.main:label("\a[warn]\239\129\177   \rthis project is completely paste"), 
            about = v2.groups.main:list("", "info", "features", "visuals", "world"), 
            author_github = v2.groups.info:label("\v\226\128\162    \a{Small Text}github: @Shenwang2333"), 
            author_bilibili = v2.groups.info:label("    \v\226\164\183  \a{Small Text}Author: @Shenwang2333"), 
            github_link = v2.groups.info:button("project github", function()
                panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://github.com/Shenwang2333/sw-toolbox");
            end, true),
            super_toss = v2.groups.features:switch("Super toss", false, "\194\183 Attempts to optimize the throw trajectory by automatically adjusting the aiming angle slightly downward and aiming differently to account for the movement speed or direction.\n\n\194\183 This is a 1:1 replica from \a95B806FFgamesense\aDEFAULT."),
            no_fall_damage = v2.groups.features:switch("No fall damage", false, "\194\183 Prevents fall damage by manipulating the player's velocity or position when falling from heights.\n\n\194\183 This is a 1:1 replica from \a95B806FFgamesense\aDEFAULT."),
            fast_ladder = v2.groups.features:switch("Fast ladder", false, "\194\183 Abuses the ladder movement mechanic and makes you move a little faster."),
            grenade_proximity_warning = v2.groups.visuals:switch("Grenade proximity warning", false, "\194\183 Shows a warning if there's a grenade in the immediate vicinity.\n\n\194\183 This is a 1:1 replica from \a95B806FFgamesense\aDEFAULT.\n\n\194\183 If you want to use this function, then do not forget to enable the Grenade Warning from Neverlose, which is located in World \194\187 Other \194\187 Grenade Proximity Warning"),
            visualize_exploits = v2.groups.visuals:switch("Visualize exploits", false, function(v3)
                local color_picker = v3:color_picker("color", color(255,0,0,255));
                local thickness_slider = v3:slider("thickness", 0, 100, 35, 1, "%");
                
                visualize_exploits_color_picker = color_picker;
                visualize_exploits_thickness_slider = thickness_slider;
                
                return {
                    exploits_color = color_picker,
                    thickness = thickness_slider
                };
            end),
            keep_model_transparency = v2.groups.visuals:switch("Keep model transparency", false, function(v4)
                local scale_slider = v4:slider("Fade Duration", 1, 20, 10, nil, function(val)
                    return val == 1 and "Smooth" or val == 10 and "GS" or val == 20 and "Default" or val.." ticks";
                end);
                keep_transparency_scale_slider = scale_slider;
                
                return {
                    scale = scale_slider
                };
            end),
            no_blood = v2.groups.world:switch("Remove blood")
        };

        -- 设置依赖
        v2.elements.author_github:depend({
            [1] = nil, 
            [2] = 1, 
            [1] = v2.elements.about
        });
        v2.elements.author_bilibili:depend({
            [1] = nil, 
            [2] = 1, 
            [1] = v2.elements.about
        });
        v2.elements.github_link:depend({
            [1] = nil, 
            [2] = 1, 
            [1] = v2.elements.about
        });
        v2.elements.super_toss:depend({
            [1] = nil, 
            [2] = 2, 
            [1] = v2.elements.about
        });
        v2.elements.no_fall_damage:depend({
            [1] = nil, 
            [2] = 2, 
            [1] = v2.elements.about
        });
        v2.elements.fast_ladder:depend({
            [1] = nil, 
            [2] = 2, 
            [1] = v2.elements.about
        });
        v2.elements.grenade_proximity_warning:depend({
            [1] = nil, 
            [2] = 3, 
            [1] = v2.elements.about
        });
        v2.elements.visualize_exploits:depend({
            [1] = nil, 
            [2] = 3, 
            [1] = v2.elements.about
        });
        v2.elements.keep_model_transparency:depend({
            [1] = nil, 
            [2] = 3, 
            [1] = v2.elements.about
        });
        v2.elements.no_blood:depend({
            [1] = nil, 
            [2] = 4, 
            [1] = v2.elements.about
        });

        -- 声明变量
        super_toss = v2.elements.super_toss;
        no_fall_damage = v2.elements.no_fall_damage;
        fast_ladder = v2.elements.fast_ladder;
        grenade_proximity_warning = v2.elements.grenade_proximity_warning;
        visualize_exploits = v2.elements.visualize_exploits;
        keep_model_transparency = v2.elements.keep_model_transparency;
        no_blood = v2.elements.no_blood;

        -- 功能回调
        v2.elements.super_toss:set_callback(function()
            super_toss_enabled(v2.elements.super_toss:get());
        end);
        
        v2.elements.no_fall_damage:set_callback(function()
            no_fall_damage_enabled(v2.elements.no_fall_damage:get());
        end);
        
        v2.elements.fast_ladder:set_callback(function()
            fast_ladder_enabled(v2.elements.fast_ladder:get());
        end);
        
        v2.elements.grenade_proximity_warning:set_callback(function()
            grenade_warning_enabled(v2.elements.grenade_proximity_warning:get());
        end);
        
        v2.elements.visualize_exploits:set_callback(function()
            local state = v2.elements.visualize_exploits:get();
            visualize_exploits_enabled(state);
            if state then
                -- 使用保存的引用而不是 get_children()
                if visualize_exploits_color_picker then
                    visualize_exploits_enabled(nil, visualize_exploits_color_picker:get());
                end;
                if visualize_exploits_thickness_slider then
                    visualize_exploits_enabled(nil, nil, visualize_exploits_thickness_slider:get() * 0.01);
                end;
            end;
        end);
        
        v2.elements.keep_model_transparency:set_callback(function()
            keep_transparency_enabled(v2.elements.keep_model_transparency:get());
        end);
        
        v2.elements.no_blood:set_callback(function()
            no_blood_enabled(v2.elements.no_blood:get());
        end);
    end
});

v1.main:init();

-- 初始化功能
no_fall_damage_init();
fast_ladder_init();
super_toss_init();
grenade_warning_init();
visualize_exploits_init();
keep_transparency_init();