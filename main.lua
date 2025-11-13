--- @since 25.2.26

-- Common image extensions
local IMAGE_EXTENSIONS = {
	jpg = true, jpeg = true, png = true, gif = true, bmp = true,
	webp = true, svg = true, ico = true, tiff = true, tif = true,
	heic = true, heif = true, avif = true, jxl = true
}

local function is_image_file(filename)
	local ext = filename:match("%.([^%.]+)$")
	if ext then
		return IMAGE_EXTENSIONS[ext:lower()] or false
	end
	return false
end

local get_image_files = ya.sync(function()
	local current_pane = cx.active.current
	local hovered_item = current_pane.hovered
	local target_dir

	if hovered_item and hovered_item.cha.is_dir then
		-- If a directory is hovered, use its path
		target_dir = tostring(hovered_item.url)
	else
		-- Otherwise, use the current working directory of the pane
		target_dir = tostring(current_pane.cwd)
	end

	-- Get all files from the current pane (respects filters)
	local files = current_pane.window
	local image_files = {}

	for _, file in ipairs(files) do
		if not file.cha.is_dir then
			local filename = tostring(file.url)
			if is_image_file(filename) then
				table.insert(image_files, filename)
			end
		end
	end

	return target_dir, image_files
end)

return {
	entry = function()
		ya.mgr_emit("escape", { visual = true })

		local target_dir, image_files = get_image_files()

		if not target_dir then
			return ya.notify({
				title = "Swayimg Gallery",
				content = "Could not determine target directory.",
				level = "error",
				timeout = 5,
			})
		end

		if #image_files == 0 then
			return ya.notify({
				title = "Swayimg Gallery",
				content = "No image files found in the target directory.",
				level = "warn",
				timeout = 5,
			})
		end

		-- Build command with all filtered image files
		local cmd = Command("swayimg"):arg("--gallery")
		for _, image_file in ipairs(image_files) do
			cmd = cmd:arg(image_file)
		end

		local status, err = cmd:spawn():wait()

		if not status or not status.success then
			ya.notify({
				title = "Swayimg Gallery",
				content = string.format("Failed to open gallery: %s", status and status.code or err),
				level = "error",
				timeout = 5,
			})
		end
	end,
}
