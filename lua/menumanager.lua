Hooks:PostHook(MenuManager, "_node_selected", "CustomOSTF:Nodes", function(self, menu_name, node)
	if type(node) == "table" and node._parameters.name == "main" then
		DelayedCalls:Add("CustomOSTF_warningmessage", 0.5, function()
			if #CustomOST.warning_message == 1 then
				if CustomOST.warning_message[1] == "COST_not_removed" then
					local menu_options = {}
					menu_options[#menu_options+1] = {text = "OK", is_cancel_button = true}
					local message = "Original Custom OST mod folder was not removed during installation. Please refer to COSTF modworkshop's mod page for installation instructions to avoid issues."
					local menu = QuickMenu:new("COST Fixer Error Reporter", message, menu_options)
					menu:Show()
					CustomOST.warning_message = {"OK"}
				elseif CustomOST.warning_message[1] ~= "OK" then
					local menu_options = {}
					menu_options[#menu_options+1] = {text = "OK", is_cancel_button = true}
					local message = "This error message should never appear. Current single error message code: " .. CustomOST.warning_message[1]
					local menu = QuickMenu:new("COST Fixer Error Reporter", message, menu_options)
					menu:Show()
					CustomOST.warning_message = {"OK"}
				end
			elseif #CustomOST.warning_message >= 2 then
				local menu_options = {}
				menu_options[#menu_options+1] = {text = "OK", is_cancel_button = true}
				local message = ""
				-- removal/additon messages happen for every track, so to avoid message duplication, only print them once
				-- every other error is folder/file specific so they are printed for each track/file error that happens
				local removalNotified = false
				local additionNotified = false
				for i = 1, #CustomOST.warning_message do
					if CustomOST.warning_message[i] == "OK" then
						--nothing
					elseif CustomOST.warning_message[i] == "removal" then
						if removalNotified == false then
							message = message .. "Track folder(s) removed, BeardLib will create an error in the logs, but the removed file should not appear in your tracks list.\nRestart the game or load into a heist to properly apply xml file changes.\n\n"
							removalNotified = true
						end
					elseif CustomOST.warning_message[i] == "addition"  then
						if additionNotified == false then
							message = message .. "New track(s) added, but currently used xml file is outdated - new track(s) will not appear in the music list.\nRestart the game or load into a heist to properly apply xml file changes.\n\n"
							additionNotified = true
						end
					elseif CustomOST.warning_message[i] == "incompleteModFolder"  then
						message = message .. "Music folder is missing track definition file: '" .. CustomOST.additonalErrorString .. "'\n\n"
					elseif CustomOST.warning_message[i] == "missingCOSTF_folder"  then
						message = message .. "Custom tracks directory 'mods/CustomOST_Fixer/CustomOSTTracks/' was not found! No tracks were added.\n\n"
					elseif CustomOST.warning_message[i] == "jsonFileError"  then
						message = message .. "Track definition file (JSON/TXT) is malformed or corrupted: '" .. CustomOST.additonalErrorString .. "'\n\n"
					elseif CustomOST.warning_message[i] == "xmlFileError"  then
						message = message .. "Track definition file (XML) is malformed or corrupted: '" .. CustomOST.additonalErrorString .. "'\n\n"
					elseif CustomOST.warning_message[i] ~= nil then
						message = message .. "This line should never appear. Warning message code:" .. CustomOST.warning_message[i] .. "\n\n"
					end
				end
				local menu = QuickMenu:new("COST Fixer Error Reporter", message, menu_options)
				menu:Show()
				CustomOST.warning_message = {"OK"}
			else
				log("[COSTF] Warning message is somehow less then 1. WTF?")
			end
		end)
	end
end)
