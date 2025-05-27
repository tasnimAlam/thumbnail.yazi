--- @since 25.2.26

local get_target_directory = ya.sync(function()
	local current_pane = cx.active.current
	local hovered_item = current_pane.hovered

	if hovered_item and hovered_item.cha.is_dir then
		-- If a directory is hovered, use its path
		return tostring(hovered_item.url)
	else
		-- Otherwise, use the current working directory of the pane
		return tostring(current_pane.cwd)
	end
end)

return {
	entry = function()
		ya.mgr_emit("escape", { visual = true })

		local target_dir = get_target_directory()

		if not target_dir then
			return ya.notify({
				title = "Swayimg Gallery",
				content = "Could not determine target directory.",
				level = "error",
				timeout = 5,
			})
		end

		-- Run swayimg in the target directory
		local status, err = Command("swayimg"):arg("--gallery"):arg(target_dir):spawn():wait()

		if not status or not status.success then
			ya.notify({
				title = "Swayimg Gallery",
				content = string.format("Failed to open %s", status and status.code or err),
				level = "error",
				timeout = 5,
			})
		end
	end,
}
