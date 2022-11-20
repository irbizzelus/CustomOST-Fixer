if not CustomOST then
	_G.CustomOST = {}
	CustomOST.track_names = {}
	CustomOST.activetracks = {}
	CustomOST.newtracks = {}
	CustomOST.warning_message = "OK"
	CustomOST._path = ModPath
end

-- Function to get all possible tracks in the specified folder
function CustomOST:load_tracks()
    if file.DirectoryExists("mods/CustomOST_Fixer/CustomOSTTracks/") then
        -- Load all tracks directories
        local tracks_dirs = file.GetDirectories("mods/CustomOST_Fixer/CustomOSTTracks/")

        for _, dir in pairs(tracks_dirs) do

            -- Prepare the vars to load the track
            dir = dir .. "/"
            local track_json_file = nil
            local track_xml_file = nil

            -- Get the track definition file type
            if file.FileExists("mods/CustomOST_Fixer/CustomOSTTracks/" .. dir .. "track.txt") then
                track_json_file = "mods/CustomOST_Fixer/CustomOSTTracks/" .. dir .. "track.txt"
            elseif file.FileExists("mods/CustomOST_Fixer/CustomOSTTracks/" .. dir .. "track.json") then
                track_json_file = "mods/CustomOST_Fixer/CustomOSTTracks/" .. dir .. "track.json"
            elseif file.FileExists("mods/CustomOST_Fixer/CustomOSTTracks/" .. dir .. "main.xml") then
                track_xml_file = "mods/CustomOST_Fixer/CustomOSTTracks/" .. dir .. "main.xml"
            end

            if track_json_file then
                CustomOST:create_track_from_json(track_json_file, "mods/CustomOST_Fixer/CustomOSTTracks/" .. dir)
            elseif track_xml_file then
                CustomOST:create_track_from_xml(track_xml_file, "mods/CustomOST_Fixer/CustomOSTTracks/" .. dir)
            else
                log("[CustomOSTF]Cannot load the track mod " .. dir .. " track definition file does not exists")
            end

        end

        -- Load all simple tracks; might use this later, but probably not since creating a heist track with only 1 file is imposible'ish with beardlib. if i figure out how to make this track have a _skip_play functionality it might work
		--[[
        local tracks_files = file.GetFiles("mods/CustomOST_Fixer/CustomOSTTracks/")

        for _, track_file in pairs(tracks_files) do
            if track_file:match("^.+(%..+)$") == ".ogg" or track_file:match("^.+(%..+)$") == ".OGG" then
                CustomOST:create_track_from_ogg(track_file, "mods/CustomOST_Fixer/CustomOSTTracks/")
            end
        end]]
		
		-- end our xml file
		local fixer_xml_file = io.open(CustomOST._path.."main.xml", 'a+')
		if fixer_xml_file then
			io.output(fixer_xml_file)
			io.write('</table>',"\n")
			io.close(fixer_xml_file)
		end
    else
        log("[CustomOSTF]Custom tracks directory 'mods/CustomOST_Fixer/CustomOSTTracks/' was not found! No tracks were added.")
    end
end


-- Create a new track from a json file and the directory of this file
function CustomOST:create_track_from_json (track_file, dir)
    -- Load the track config JSON
    local f = io.open(track_file, "r")
    local track_json_string = f:read("*all")
    f:close()

    local valid, track_table = pcall(function () return json.decode(track_json_string) end)
    if valid then
        if track_table and type(track_table) == "table" then
            track_table.dir = dir
            track_table.fade_duration = track_table.fade_duration or nil
            self:_add_standard_track(track_table)
        end
    else
        log(track_file .. " JSON file is malformed")
        return nil
    end
end

function CustomOST:create_track_from_xml (track_file, dir)
    -- Load the track config
    local f = io.open(track_file, "r")
    local track_xml_string = f:read("*all")
    f:close()

    local valid, track_xml_table = pcall(function () return ScriptSerializer:from_custom_xml(track_xml_string) end)
    if valid then

        -- Prepare the localizations array
        local locs_table = {}

        -- Interate in the XML structure to find all localizations
        for k, v in pairs(track_xml_table) do
            if type(k) == "number" and type(v) == "table" then
                if v._meta == "Localization" then
                    local directory = (v.directory and dir .. v.directory .. "/") or dir
                    local loc_json_file = directory .. v.default
                    
                    -- Load the loc json file
                    if file.FileExists(loc_json_file) then
                        local f_loc = io.open(loc_json_file, "r")
                        local loc_json_string = f_loc:read("*all")
                        f_loc:close()

                        local valid, loc_json_table = pcall(function () return json.decode(loc_json_string) end)
                        if valid then
                            for loc_k, loc_v in pairs(loc_json_table) do locs_table[loc_k] = loc_v end
                        else
                            log("Localization file " .. loc_json_file .. " is malformed")
                            return nil
                        end
                    else
                        log("Localization file " .. loc_json_file .. " is missing or unreadable")
                        return nil
                    end
                end
            end
        end

		local _beard_lib_event_trad = {
			setup = "setup",
			control = "control",
			anticipation = "buildup",
			assault = "assault"
		}
        -- Prepare the tracks tables array
        local tracks_tables = {}

        -- Iterate in the XML structure to find all tracks
        for k, v in pairs(track_xml_table) do
            if type(k) == "number" and type(v) == "table" then
                if v._meta == "HeistMusic" then
                    local new_track_table = {}

                    new_track_table.id = v.id
                    new_track_table.name = locs_table["menu_jukebox_" .. v.id]
                    new_track_table.volume = v.volume
                   --new_track_table.fade_duration = COSTConfig.default_fade_duration
                    new_track_table.dir = (v.directory and dir .. v.directory .. "/") or dir
                    new_track_table.events = {
                        setup = {},
                        control = {},
                        buildup = {},
                        assault = {}
                    }

                    for ev_k, ev_v in pairs(v) do
                        if type(ev_k) == "number" and type(ev_v) == "table" then
                            if ev_v._meta == "event" then
                                local event = _beard_lib_event_trad[ev_v.name]
                                new_track_table.events[event].start_file = ev_v.start_source
                                new_track_table.events[event].file = ev_v.source
                                new_track_table.events[event].volume = ev_v.volume

                                new_track_table.events[event].alt = ev_v.alt_source
                                new_track_table.events[event].alt_start = ev_v.alt_start_source
                                new_track_table.events[event].alt_chance = ev_v.alt_chance
                            end
                        end
                    end

                    table.insert(tracks_tables, new_track_table)
                end
            end
        end

        -- Add all tracks to the manager
        for _, track_table in pairs(tracks_tables) do
            self:_add_standard_track(track_table)
        end

    else
        log(track_file .. " XML file is malformed")
        return nil
    end
end

-- probably will never use, buuuuuuuuut leave it just in case. needs more work
--[[
-- Create a new simple track from an OGG file
function CustomOST:create_track_from_ogg (track_file, dir)
    -- Init the track table to create the track after
    local simple_track_table = {}

    local actual_name = string.sub(track_file,1,string.len(track_file)-4)

    -- Try to get the volume
    local splited_volume = string.split(actual_name, "-")
	
    local volume_test = tonumber(splited_volume[#splited_volume])
    if volume_test ~= nil then
        simple_track_table.volume = volume_test
        splited_volume[#splited_volume] = nil
        track_name = table.concat(splited_volume, "-")
    end
	
    local track_id = table.concat(string.split(string.lower(track_name), "_"))

    -- Get the simple track main parameters
    simple_track_table.id = "custom_ost_simple_" .. track_id
    simple_track_table.name = track_name
    simple_track_table.dir = dir
    simple_track_table.file = track_file

    -- Load the simple track buffer
    self:_add_simple_track(simple_track_table)
end]]

-- Function to add a standard track to the manager
function CustomOST:_add_standard_track(track_table)
    local id = track_table.id
	-- if track id begins with a number music doenst load correctly, so we add a letter prefix
	if type(tonumber(string.sub(id,1,1))) == "number" then
		id = "COSTF_"..id
	end
    local name = track_table.name
    local volume = track_table.volume or 1
    local context = "heist"
    if track_table.context == "stealth" then
        context = "stealth"
    end
	
	if context == "heist" then
		-- have to cut directory string bcuz BeardLib allready knows that we are in mods/CustomOST_Fixer/
		local dir = string.sub(track_table.dir,22,string.len(track_table.dir))

		if not CustomOST.FirstTrackDone then
		
			local loc_file = io.open(CustomOST._path.."loc/en.txt", 'r')
			if loc_file then
				for k, v in pairs(json.decode(loc_file:read('*all')) or {}) do
					if not CustomOST.activetracks[v] then
						CustomOST.activetracks[v] = true
					end
				end
			end
			io.close(loc_file)
		
			local fixer_xml_file = io.open(CustomOST._path.."main.xml", 'w+')
			if fixer_xml_file then
				io.output(fixer_xml_file)
				-- begining of the file, overwrites file completely
				io.write('<table name="CustomOSTF">',"\n")
				io.write('<Localization directory="loc" default="en.txt"/>',"\n")
				io.write('<AssetUpdates id="irbizzelus/CustomOST-Fixer" provider="github" release="true" version="1.0"/>',"\n")
				CustomOST.FirstTrackDone = true
				io.close(fixer_xml_file)
			end
		end
		
		local fixer_xml_file = io.open(CustomOST._path.."main.xml", 'a+')
		if fixer_xml_file then
			io.output(fixer_xml_file)
			-- begining of a track
			io.write('<HeistMusic id="'..id..'" volume="'..volume..'" directory="'..dir..'"> ',"\n")
			local start_file = ""
			local eventvolume = ""
			local alt = ""
			local alt_start = ""
			local alt_chance = ""
			local defaultweight = 'weight="10"'
			
			for event, params in pairs(track_table.events) do
				if track_table.events[event].start_file then
					start_file = 'start_source="'..track_table.events[event].start_file..'"'
				else
					start_file = ""
				end
				
				-- <track> parameters
				if track_table.events[event].volume then
					eventvolume = 'volume="'..(track_table.events[event].volume or "1")..'"'
				else
					eventvolume = ""
				end
				if track_table.events[event].alt then
					alt = 'source="'..track_table.events[event].alt..'"'
				else
					alt = ""
				end
				if track_table.events[event].alt_start then
					alt_start = 'start_source="'..track_table.events[event].alt_start..'"'
				else
					alt_start = ""
				end
				if track_table.events[event].alt_chance then
					alt_chance = 'weight="'..(track_table.events[event].alt_chance * 10)..'"'
				else
					alt_chance = ""
				end

				if event == "buildup" then
					io.write(string.format('<event name="anticipation" %s>',eventvolume) ,"\n")
				elseif event == "stealth" then
					io.write(string.format('<event name="setup" %s >',eventvolume) ,"\n")
				else
					io.write(string.format('<event name="'..event..'" %s >',eventvolume) ,"\n")
				end
				io.write(string.format('<track source="'..track_table.events[event].file..'" %s %s/>',start_file,defaultweight) ,"\n")
				if track_table.events[event].alt then
					io.write(string.format('<track %s %s %s/>',alt,alt_start,alt_chance) ,"\n")
				end
				io.write('</event>',"\n")
			end
			-- end of a track
			io.write('</HeistMusic>',"\n")
			io.close(fixer_xml_file)
		end
		
		CustomOST.track_names[id] = name
	end
end

CustomOST.load_tracks()

-- after tracks are loaded create en.txt file
local file = io.open(CustomOST._path.."loc/en.txt", 'w+')
if file then
	CustomOST.translations = {}
	for id, name in pairs(CustomOST.track_names) do
		CustomOST.translations["menu_jukebox_"..id] = CustomOST.track_names[id]
		CustomOST.translations["menu_jukebox_screen_"..id] = CustomOST.track_names[id]
	end
	file:write(json.encode(CustomOST.translations))
	file:close()
end

-- write down all track names from newely created file into a list to compare later
local loc_file_new = io.open(CustomOST._path.."loc/en.txt", 'r')
if loc_file_new then
	for k, v in pairs(json.decode(loc_file_new:read('*all')) or {}) do
		if not CustomOST.newtracks[v] then
			CustomOST.newtracks[v] = true
		end
	end
end
io.close(loc_file_new)

-- check for added files
for name, exists in pairs(CustomOST.newtracks) do
	if not CustomOST.activetracks[name] then
		CustomOST.warning_message = "addition"
	end
end

-- check for removed files
for name, exists in pairs(CustomOST.activetracks) do
	if not CustomOST.newtracks[name] then
		CustomOST.warning_message = "removal"
	end
end