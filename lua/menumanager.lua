Hooks:PostHook(MenuManager, "_node_selected", "CustomOSTF:Nodes", function(self, menu_name, node)
	if type(node) == "table" and node._parameters.name == "main" then
		DelayedCalls:Add("CustomOSTF_warningmessage", 0.5, function()
			if CustomOST.warning_message ~= "OK" then
				local menu_options = {}
				menu_options[#menu_options+1] = {text = "OK", is_cancel_button = true}
				local message = ""
				if CustomOST.warning_message == "removal" then
					message = "Track was removed, BeardLib will create an error in the logs, but the removed file should not appear in your tracks list.\n\nRestart the game or load into a heist to properly apply xml file changes."
				elseif CustomOST.warning_message == "addition" then
					message = "New track(s) added, but currently used xml file is outdated - new track(s) will not appear in the music list.\n\nRestart the game or load into a heist to properly apply xml file changes."
				else
					message = "This message should never appear."
				end
				local menu = QuickMenu:new("CustomOSTF", message, menu_options)
				menu:Show()
				CustomOST.warning_message = "OK"
			end
		end)
	end
end)
