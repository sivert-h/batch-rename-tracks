-------- Scythe stuff --------

local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")


-------- Main code --------

function replace(trackname, old_str, new_str, use_re, clear_name)
    if clear_name then
        return ""
    elseif use_re then
        -- Some code here that handles regular expressions
        reaper.MB("Regular Expressions hasn't been implemented yet :)", "Sorry!", 0)
        return trackname
    else
        return trackname:gsub(old_str, new_str)
    end
end

function trim(trackname, from_beginning, from_end, trim_range, range_from, range_to, count_from_end)
    if from_beginning ~= 0 then
        trackname = string.sub(trackname, from_beginning + 1,  -1)
    end
    if from_end ~= 0 then
        trackname = string.sub(trackname, 1, -from_end - 1)
    end
    if trim_range then
        if count_from_end then
            -- Probably ugly, but reversing the string, processing, then reversing back
            trackname = string.reverse(trackname)
            local keep_to = string.sub(trackname, 1, range_from-1)
            local keep_from = string.sub(trackname, range_to+1, -1)
            trackname = keep_to..keep_from
            trackname = string.reverse(trackname)
        else
            local keep_to = string.sub(trackname, 1, range_from-1)
            local keep_from = string.sub(trackname, range_to, -1)
            trackname = keep_to..keep_from
        end
    end
    return trackname
end

function add_fix(trackname, prefix, insert, insert_index, suffix)
    if insert ~= "" then
        trackname = string.sub(trackname, 1, insert_index) .. insert .. string.sub(trackname, insert_index+1, -1)
    end
    if prefix ~= "" then
        trackname = prefix .. trackname
    end
    if suffix ~= "" then
        trackname = trackname .. suffix
    end
    return trackname
end

function numbering(trackname, position, number_index, number, separator, atoz)
    if atoz then
        number = string.char(number + 64) -- Just converts a digit to a character, adding 64 means "1" starts at "A"
    end
    if position == 1 then -- Drop down menu "End"
        trackname = trackname .. separator .. number
    elseif position == 2 then -- Drop down menu "Beginning"
        trackname = number .. separator .. trackname
    elseif position == 3 then -- Drop down menu "At Index"
        trackname = string.sub(trackname, 1, number_index) .. separator .. number .. string.sub(trackname, number_index+1, -1)
    end
    return trackname
end

function main()
    reaper.Undo_BeginBlock()

    local sel_tracks_count = reaper.CountSelectedTracks(0)
    if sel_tracks_count == 0 then
        reaper.ShowMessageBox("No tracks selected", "Error", 0)
    else
        for i = 0, sel_tracks_count - 1 do
            local track = reaper.GetSelectedTrack(0, i)
            local _, trackname = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false) -- Get name

            if GUI.Val("chk_replace")[1] then -- Replace selected
                local find_str, replace_str = GUI.Val("txt_find"), GUI.Val("txt_replace")
                local clear_name, use_re = GUI.Val("chk_clear_name")[1], GUI.Val("chk_regex")[1]
                trackname = replace(trackname, find_str, replace_str, use_re, clear_name)
            end

            if GUI.Val("chk_trim")[1] then -- Trim selected
                local from_beginning, from_end = tonumber(GUI.Val("txt_from_beginning")), tonumber(GUI.Val("txt_from_end"))
                local range_from, range_to = tonumber(GUI.Val("txt_range_from")), tonumber(GUI.Val("txt_range_to"))
                local trim_range, count_from_end = GUI.Val("chk_range")[1], GUI.Val("chk_count_from_end")[1]
                trackname = trim(trackname, from_beginning, from_end, trim_range, range_from, range_to, count_from_end)
            end

            if GUI.Val("chk_add")[1] then -- Add selected
                local prefix, suffix = GUI.Val("txt_prefix"), GUI.Val("txt_suffix")
                local insert, insert_index = GUI.Val("txt_insert"), GUI.Val("txt_numbering_index")
                trackname = add_fix(trackname, prefix, insert,insert_index, suffix)
            end

            if GUI.Val("chk_numbering")[1] then -- Numbering selected
                local position = GUI.Val("mnu_position")
                local number_index = GUI.Val("txt_numbering_index")
                local starting_number, increment = tonumber(GUI.Val("txt_starting_number")), tonumber(GUI.Val("txt_increment"))
                local atoz = GUI.Val("chk_use_a_z")[1]
                local number_of_places = GUI.Val("txt_number_of_places")
                local separator = GUI.Val("txt_separator")

                local number = tostring(starting_number + i * increment)
                trackname = numbering(trackname, position, number_index, number, separator, atoz)
            end
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", trackname, true) -- Change name
        end
    end
    reaper.Undo_EndBlock("Batch Rename", 0)
end


-------- Window settings --------

local window = GUI.createWindow({
    name = "Batch Rename Tracks",
    w = 320,
    h = 868,
})


-------- GUI Elements --------

X_INDENT_1 = 12
X_INDENT_2 = 104
X_INDENT_3 = 148
X_OFFSET = 28
Y_OFFSET = 12
Y_GRID = 28
W_BIG = 180
W_SMALL = 88


layer = GUI.createLayer({name = "Layer"})

layer:addElements( GUI.createElements(
-------- Replace --------
  {
    name = "chk_replace",
    type = "Checklist",
    x = X_INDENT_1,
    y = Y_OFFSET,
    h = 32,
    caption = "",
    options = {"Replace"},
    selectedOptions = {true},
    frame = false
},
{
    name = "txt_find",
    type = "Textbox",
    x = X_INDENT_2,
    y = Y_OFFSET + Y_GRID * 1,
    w = W_BIG,
    caption = "Find:         ",
    retval = "",
    frame = false
},
{
    name = "txt_replace",
    type = "Textbox",
    x = X_INDENT_2,
    y = Y_OFFSET + Y_GRID * 2,
    w = W_BIG,
    caption = "Replace:   ",
    retval = "",
    frame = false
},
{
    name = "chk_clear_name",
    type = "Checklist",
    x = X_INDENT_1 + X_OFFSET,
    y = Y_OFFSET + Y_GRID * 3,
    h = 32,
    caption = "",
    options = {"Clear Existing Name"},
    frame = false
},
{
    name = "chk_regex",
    type = "Checklist",
    x = X_INDENT_1 + X_OFFSET,
    y = Y_OFFSET + Y_GRID * 4,
    h = 32,
    caption = "",
    options = {"Regular Expressions"},
    frame = false
},
{
    name = "lbl_spacer1",
    type = "Label",
    x = 0,
    y = Y_OFFSET + Y_GRID * 5,
    caption = string.rep('_', 60)
},
-------- Trim --------
{
    name = "chk_trim",
    type = "Checklist",
    x = X_INDENT_1,
    y = Y_OFFSET + Y_GRID * 6,
    h = 32,
    caption = "",
    options = {"Trim"},
    selectedOptions = {true},
    frame = false
},
{
    name = "txt_from_beginning",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 7,
    w = W_SMALL,
    caption = "From Beginning:   ",
    retval = "0",
    frame = false
},
{
    name = "txt_from_end",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 8,
    w = W_SMALL,
    caption = "From End:              ",
    retval = "0",
    frame = false
},
{
    name = "chk_range",
    type = "Checklist",
    x = X_INDENT_1 + X_OFFSET,
    y = Y_OFFSET + Y_GRID * 9,
    h = 32,
    caption = "",
    options = {"Range"},
    frame = false
},
{
    name = "txt_range_from",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 10,
    w = W_SMALL,
    caption = "From:           ",
    retval = "0",
    frame = false
},
{
    name = "txt_range_to",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 11,
    w = W_SMALL,
    caption = "To:                ",
    retval = "0",
    frame = false
},
{
    name = "chk_count_from_end",
    type = "Checklist",
    x = X_INDENT_1 + X_OFFSET * 2,
    y = Y_OFFSET + Y_GRID * 12,
    h = 32,
    caption = "",
    options = {"Count From End"},
    frame = false
},
{
    name = "lbl_spacer2",
    type = "Label",
    x = 0,
    y = Y_OFFSET + Y_GRID * 13,
    caption = string.rep('_', 60)
},
-------- Add --------
{
    name = "chk_add",
    type = "Checklist",
    x = X_INDENT_1,
    y = Y_OFFSET + Y_GRID * 14,
    h = 32,
    caption = "",
    options = {"Add"},
    selectedOptions = {true},
    frame = false
},
{
    name = "txt_prefix",
    type = "Textbox",
    x = X_INDENT_2,
    y = Y_OFFSET + Y_GRID * 15,
    w = W_BIG,
    caption = "Prefix:       ",
    retval = "",
    frame = false
},
{
    name = "txt_insert",
    type = "Textbox",
    x = X_INDENT_2,
    y = Y_OFFSET + Y_GRID * 16,
    w = W_BIG,
    caption = "Insert:       ",
    retval = "",
    frame = false
},
{
    name = "txt_insert_index",
    type = "Textbox",
    x = X_INDENT_2 + 16,
    y = Y_OFFSET + Y_GRID * 17,
    w = W_SMALL,
    caption = "At Index: ",
    retval = "0",
    frame = false
},
{
    name = "txt_suffix",
    type = "Textbox",
    x = X_INDENT_2,
    y = Y_OFFSET + Y_GRID * 18,
    w = W_BIG,
    caption = "Suffix:      ",
    retval = "",
    frame = false
},
{
    name = "lbl_spacer3",
    type = "Label",
    x = 0,
    y = Y_OFFSET + Y_GRID * 19,
    caption = string.rep('_', 60)
},
-------- Numbering --------
{
    name = "chk_numbering",
    type = "Checklist",
    x = X_INDENT_1,
    y = Y_OFFSET + Y_GRID * 20,
    h = 32,
    caption = "",
    options = {"Numbering"},
    selectedOptions = {false},
    frame = false
},
{
    name = "mnu_position",
    type = "Menubox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 21,
    w = W_SMALL,
    caption = "Position:                 ",
    options = {"End", "Beginning", "At Index"},
    frame = false
},
{
    name = "txt_numbering_index",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 22,
    w = W_SMALL,
    caption = "Index:                      ",
    retval = "0",
    frame = false
},
{
    name = "txt_starting_number",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 23,
    w = W_SMALL,
    caption = "Starting Number:  ",
    retval = "1",
    frame = false
},
{
    name = "txt_number_of_places",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 24,
    w = W_SMALL,
    caption = "Number of Places:",
    retval = "0",
    frame = false
},
{
    name = "txt_increment",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 25,
    w = W_SMALL,
    caption = "Increment:              ",
    retval = "1",
    frame = false
},
{
    name = "txt_separator",
    type = "Textbox",
    x = X_INDENT_3,
    y = Y_OFFSET + Y_GRID * 26,
    w = W_SMALL,
    caption = "Separator:              ",
    retval = "",
    frame = false
},
{
    name = "chk_use_a_z",
    type = "Checklist",
    x = X_INDENT_1 + X_OFFSET,
    y = Y_OFFSET + Y_GRID * 27,
    h = 32,
    caption = "",
    options = {"Use A..Z"},
    frame = false
},
{
    name = "lbl_spacer4",
    type = "Label",
    x = 0,
    y = Y_OFFSET + Y_GRID * 28,
    caption = string.rep('_', 60)
},
-------- Buttons --------
{
    name = "btn_quit",
    type = "Button",
    x = 88,
    y = Y_OFFSET + Y_GRID * 29,
    w = 100,
    caption = "Quit",
    func = function () Scythe.quit = true end
},
{
    name = "btn_apply",
    type = "Button",
    x = 204,
    y = Y_OFFSET + Y_GRID * 29,
    w = 100,
    caption = "Apply",
    func = main
}
))


window:addLayers(layer)

window:open()
GUI.Main()