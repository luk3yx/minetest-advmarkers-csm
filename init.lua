--
-- Minetest advmarkers CSM
--
-- Needs the https://github.com/Billy-S/kingdoms_game/tree/master/mods/marker
--  mod to be able to display HUD elements
--

advmarkers = {}

-- Get the mod storage
local storage = minetest.get_mod_storage()

-- Convert positions to/from strings
local function pos_to_string(pos)
    if type(pos) == 'table' then
        pos = minetest.pos_to_string(vector.round(pos))
    end
    if type(pos) == 'string' then
        return pos
    end
end

local function string_to_pos(pos)
    if type(pos) == 'string' then
        pos = minetest.string_to_pos(pos)
    end
    if type(pos) == 'table' then
        return vector.round(pos)
    end
end

-- Set the HUD position
local hud_id
function advmarkers.set_hud_pos(pos, title)
    pos = string_to_pos(pos)
    if not pos then return end

    -- Fall back to /mrkr if hud_add doesn't exist (Minetest 0.4).
    if not minetest.localplayer or not minetest.localplayer.hud_add or
            not minetest.localplayer.hud_change then
        minetest.run_server_chatcommand('mrkr', tostring(pos.x) .. ' ' ..
            tostring(pos.y) .. ' ' .. tostring(pos.z))
    end

    if not title then
        title = pos.x .. ', ' .. pos.y .. ', ' .. pos.z
    end
    if hud_id then
        minetest.localplayer:hud_change(hud_id, 'name', title)
        minetest.localplayer:hud_change(hud_id, 'world_pos', pos)
    else
        hud_id = minetest.localplayer:hud_add({
            hud_elem_type = 'waypoint',
            name          = title,
            text          = 'm',
            number        = 0x00ffff,
            world_pos     = pos
        })
    end
    minetest.display_chat_message('Waypoint set to ' ..
        minetest.colorize('#00ffff', title))
    return true
end

-- Add a waypoint
function advmarkers.set_waypoint(pos, name)
    pos = pos_to_string(pos)
    if not pos then return end
    storage:set_string('marker-' .. tostring(name), pos)
    return true
end
advmarkers.set_marker = advmarkers.set_waypoint

-- Delete a waypoint
function advmarkers.delete_waypoint(name)
    storage:set_string('marker-' .. tostring(name), '')
end
advmarkers.delete_marker = advmarkers.delete_waypoint

-- Get a waypoint
function advmarkers.get_waypoint(name)
    return string_to_pos(storage:get_string('marker-' .. tostring(name)))
end
advmarkers.get_marker = advmarkers.get_waypoint

-- Rename a waypoint and re-interpret the position.
function advmarkers.rename_waypoint(oldname, newname)
    oldname, newname = tostring(oldname), tostring(newname)
    local pos = advmarkers.get_waypoint(oldname)
    if not pos or not advmarkers.set_waypoint(pos, newname) then return end
    if oldname ~= newname then
        advmarkers.delete_waypoint(oldname)
    end
    return true
end
advmarkers.rename_marker = advmarkers.rename_waypoint

-- Display a waypoint
function advmarkers.display_waypoint(name)
    return advmarkers.set_hud_pos(advmarkers.get_waypoint(name), name)
end
advmarkers.display_marker = advmarkers.display_waypoint

-- Export waypoints
function advmarkers.export(raw)
    local s = storage:to_table().fields
    if raw == 'M' then
        s = minetest.compress(minetest.serialize(s))
        s = 'M' .. minetest.encode_base64(s)
    elseif not raw then
        s = minetest.compress(minetest.write_json(s))
        s = 'J' .. minetest.encode_base64(s)
    end
    return s
end

-- Import waypoints
function advmarkers.import(s)
    if type(s) ~= 'table' then
        local ver = s:sub(1, 1)
        if ver ~= 'M' and ver ~= 'J' then return end
        s = minetest.decode_base64(s:sub(2))
        local success, msg = pcall(minetest.decompress, s)
        if not success then return end
        if ver == 'M' then
            s = minetest.deserialize(msg, true)
        else
            s = minetest.parse_json(msg)
        end
    end

    -- Iterate over waypoints to preserve existing ones and check for errors.
    if type(s) == 'table' then
        for name, pos in pairs(s) do
            if type(name) == 'string' and type(pos) == 'string' and
              name:sub(1, 7) == 'marker-' and minetest.string_to_pos(pos) and
              storage:get_string(name) ~= pos then
                -- Prevent collisions
                local c = 0
                while #storage:get_string(name) > 0 and c < 50 do
                    name = name .. '_'
                    c = c + 1
                end

                -- Sanity check
                if c < 50 then
                    storage:set_string(name, pos)
                end
            end
        end
        return true
    end
end

-- Get the waypoints formspec
local formspec_list = {}
local selected_name = false
function advmarkers.display_formspec()
    local formspec = 'size[5.25,8]' ..
                     'label[0,0;Waypoint list]' ..
                     'button_exit[0,7.5;1.3125,0.5;display;Display]' ..
                     'button[1.3125,7.5;1.3125,0.5;teleport;Teleport]' ..
                     'button[2.625,7.5;1.3125,0.5;rename;Rename]' ..
                     'button[3.9375,7.5;1.3125,0.5;delete;Delete]' ..
                     'textlist[0,0.75;5,6;marker;'

    -- Iterate over all the waypoints
    local selected = 1
    formspec_list = {}

    local waypoints = {}
    for name, _ in pairs(storage:to_table().fields) do
        if name:sub(1, 7) == 'marker-' then
            table.insert(waypoints, name:sub(8))
        end
    end
    table.sort(waypoints)

    for id, name in ipairs(waypoints) do
        if id > 1 then
            formspec = formspec .. ','
        end
        if not selected_name then
            selected_name = name
        end
        if name == selected_name then
            selected = id
        end
        formspec_list[#formspec_list + 1] = name
        formspec = formspec .. '##' .. minetest.formspec_escape(name)
    end

    -- Close the text list and display the selected waypoint position
    formspec = formspec .. ';' .. tostring(selected) .. ']'
    if selected_name then
        local pos = advmarkers.get_waypoint(selected_name)
        if pos then
            pos = minetest.formspec_escape(tostring(pos.x) .. ', ' ..
            tostring(pos.y) .. ', ' .. tostring(pos.z))
            pos = 'Waypoint position: ' .. pos
            formspec = formspec .. 'label[0,6.75;' .. pos .. ']'
        end
    else
        -- Draw over the buttons
        formspec = formspec .. 'button_exit[0,7.5;5.25,0.5;quit;Close dialog]' ..
            'label[0,6.75;No waypoints. Add one with ".add_mrkr".]'
    end

    -- Display the formspec
    return minetest.show_formspec('advmarkers-csm', formspec)
end

function advmarkers.get_chatcommand_pos(pos)
    if pos == 'h' or pos == 'here' then
        pos = minetest.localplayer:get_pos()
    elseif pos == 't' or pos == 'there' then
        if not advmarkers.last_coords then
            return false, 'No-one has used ".coords" and you have not died!'
        end
        pos = advmarkers.last_coords
    else
        pos = string_to_pos(pos)
        if not pos then
            return false, 'Invalid position!'
        end
    end
    return pos
end

local function register_chatcommand_alias(old, ...)
    local def = assert(minetest.registered_chatcommands[old])
    def.name = nil
    for i = 1, select('#', ...) do
        minetest.register_chatcommand(select(i, ...), table.copy(def))
    end
end

-- Open the waypoints GUI
minetest.register_chatcommand('mrkr', {
    params      = '',
    description = 'Open the advmarkers GUI',
    func = function(param)
        if param == '' then
            advmarkers.display_formspec()
        else
            local pos, err = advmarkers.get_chatcommand_pos(param)
            if not pos then
                return false, err
            end
            if not advmarkers.set_hud_pos(pos) then
                return false, 'Error setting the waypoint!'
            end
        end
    end
})

register_chatcommand_alias('mrkr', 'wp', 'wps', 'waypoint', 'waypoints')

-- Add a waypoint
minetest.register_chatcommand('add_mrkr', {
    params      = '<pos / "here" / "there"> <name>',
    description = 'Adds a waypoint.',
    func = function(param)
        local s, e = param:find(' ')
        if not s or not e then
            return false, 'Invalid syntax! See .help add_mrkr for more info.'
        end
        local pos = param:sub(1, s - 1)
        local name = param:sub(e + 1)

        -- Validate the position
        local pos, err = advmarkers.get_chatcommand_pos(pos)
        if not pos then
            return false, err
        end

        -- Validate the name
        if not name or #name < 1 then
            return false, 'Invalid name!'
        end

        -- Set the waypoint
        return advmarkers.set_waypoint(pos, name), 'Done!'
    end
})

register_chatcommand_alias('add_mrkr', 'add_wp', 'add_waypoint')

-- Set the HUD
minetest.register_on_formspec_input(function(formname, fields)
    if formname == 'advmarkers-ignore' then
        return true
    elseif formname ~= 'advmarkers-csm' then
        return
    end
    local name = false
    if fields.marker then
        local event = minetest.explode_textlist_event(fields.marker)
        if event.index then
            name = formspec_list[event.index]
        end
    else
        name = selected_name
    end

    if name then
        if fields.display then
            if not advmarkers.display_waypoint(name) then
                minetest.display_chat_message('Error displaying waypoint!')
            end
        elseif fields.rename then
            minetest.show_formspec('advmarkers-csm', 'size[6,3]' ..
                'label[0.35,0.2;Rename waypoint]' ..
                'field[0.3,1.3;6,1;new_name;New name;' ..
                minetest.formspec_escape(name) .. ']' ..
                'button[0,2;3,1;cancel;Cancel]' ..
                'button[3,2;3,1;rename_confirm;Rename]')
        elseif fields.rename_confirm then
            if fields.new_name and #fields.new_name > 0 then
                if advmarkers.rename_waypoint(name, fields.new_name) then
                    selected_name = fields.new_name
                else
                    minetest.display_chat_message('Error renaming waypoint!')
                end
                advmarkers.display_formspec()
            else
                minetest.display_chat_message(
                    'Please enter a new name for the marker.'
                )
            end
        elseif fields.teleport then
            minetest.show_formspec('advmarkers-csm', 'size[6,2.2]' ..
                'label[0.35,0.25;' .. minetest.formspec_escape(
                    'Teleport to a waypoint\n - ' .. name
                ) .. ']' ..
                'button[0,1.25;2,1;cancel;Cancel]' ..
                'button_exit[2,1.25;1,1;teleport_tpj;/tpj]' ..
                'button_exit[3,1.25;1,1;teleport_tpc;/tpc]' ..
                'button_exit[4,1.25;2,1;teleport_confirm;/teleport]')
        elseif fields.teleport_tpj then
            -- Teleport with /tpj
            local pos = advmarkers.get_waypoint(name)
            if pos and minetest.localplayer then
                local cpos = minetest.localplayer:get_pos()
                for _, dir in ipairs({'x', 'y', 'z'}) do
                    local distance = pos[dir] - cpos[dir]
                    minetest.run_server_chatcommand('tpj', dir .. ' ' ..
                        tostring(distance))
                end
            else
                minetest.display_chat_message('Error teleporting to waypoint!')
            end
        elseif fields.teleport_confirm or fields.teleport_tpc then
            -- Teleport with /teleport
            local pos = advmarkers.get_waypoint(name)
            local cmd
            if fields.teleport_confirm then
                cmd = 'teleport'
            else
                cmd = 'tpc'
            end
            if pos and minetest.localplayer then
                minetest.run_server_chatcommand(cmd,
                    pos.x .. ',' .. pos.y .. ',' .. pos.z)
            else
                minetest.display_chat_message('Error teleporting to waypoint!')
            end
        elseif fields.delete then
            minetest.show_formspec('advmarkers-csm', 'size[6,2]' ..
                'label[0.35,0.25;Are you sure you want to delete this waypoint?]' ..
                'button[0,1;3,1;cancel;Cancel]' ..
                'button[3,1;3,1;delete_confirm;Delete]')
        elseif fields.delete_confirm then
            advmarkers.delete_waypoint(name)
            selected_name = false
            advmarkers.display_formspec()
        elseif fields.cancel then
            advmarkers.display_formspec()
        elseif name ~= selected_name then
            selected_name = name
            advmarkers.display_formspec()
        end
    elseif fields.display or fields.delete then
        minetest.display_chat_message('Please select a waypoint.')
    end
    return true
end)

-- Auto-add waypoints on death.
minetest.register_on_death(function()
    if minetest.localplayer then
        local name = 'Death waypoint'
        local pos  = minetest.localplayer:get_pos()
        advmarkers.last_coords = pos
        advmarkers.set_waypoint(pos, name)
        minetest.display_chat_message('Added waypoint "' .. name .. '".')
    end
end)

-- Allow string exporting
minetest.register_chatcommand('mrkr_export', {
    params      = '[old]',
    description = 'Exports an advmarkers string containing all your markers.',
    func = function(param)
        local export
        if param == 'old' then
            export = advmarkers.export('M')
        else
            export = advmarkers.export()
        end
        minetest.show_formspec('advmarkers-ignore',
            'field[_;Your waypoint export string;' ..
            minetest.formspec_escape(export) .. ']')
    end
})

register_chatcommand_alias('mrkr_export', 'wp_export', 'waypoint_export')

-- String importing
minetest.register_chatcommand('mrkr_import', {
    params      = '<advmarkers string>',
    description = 'Imports an advmarkers string. This will not overwrite ' ..
        'existing markers that have the same name.',
    func = function(param)
        if advmarkers.import(param) then
            return true, 'Waypoints imported!'
        else
            return false, 'Invalid advmarkers string!'
        end
    end
})

register_chatcommand_alias('mrkr_export', 'wp_import', 'waypoint_import')

-- Upload waypoints to the advmarkers server-side mod.
minetest.register_chatcommand('mrkr_upload', {
    params      = '',
    description = 'Uploads all waypoints to this server\'s advmarkers storage.',
    func = function(param)
        local data = advmarkers.export()
        minetest.run_server_chatcommand('mrkr_import', data)
    end
})

register_chatcommand_alias('mrkr_export', 'wp_upload', 'waypoint_upload')

-- Chat channels .coords integration.
-- You do not need to have chat channels installed for this to work.
if not minetest.registered_on_receiving_chat_message then
    minetest.registered_on_receiving_chat_message =
        minetest.registered_on_receiving_chat_messages
end

table.insert(minetest.registered_on_receiving_chat_message, 1, function(msg)
    local s, e = msg:find('Current Position: %-?[0-9]+, %-?[0-9]+, %-?[0-9]+%.')
    if s and e then
        local pos = string_to_pos(msg:sub(s + 18, e - 1))
        if pos then
            advmarkers.last_coords = pos
        end
    end
end)

-- Add '.mrkrthere'
minetest.register_chatcommand('mrkrthere', {
    params      = '',
    description = 'Adds a (temporary) waypoint at the last ".coords" position.',
    func = function(param)
        if not advmarkers.last_coords then
            return false, 'No-one has used ".coords" and you have not died!'
        elseif not advmarkers.set_hud_pos(advmarkers.last_coords) then
            return false, 'Error setting the waypoint!'
        end
    end
})

minetest.register_chatcommand('clrmrkr', {
    params = '',
    description = 'Hides the displayed waypoint.',
    func = function(param)
        if hud_id then
            minetest.localplayer:hud_remove(hud_id)
            hud_id = nil
            return true, 'Hidden the currently displayed waypoint.'
        elseif not minetest.localplayer.hud_add then
            minetest.run_server_chatcommand('clrmrkr')
            return
        elseif not hud_id then
            return false, 'No waypoint is currently being displayed!'
        end
    end,
})

register_chatcommand_alias('clrmrkr', 'clear_marker', 'clrwp',
    'clear_waypoint')
