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
	local files = current_pane.files
	local selected_items = cx.active.selected

  -- Full URLs to image files or directories
	local target_urls = {}
	local selection_kind = nil

	-- Order of operations
	-- 1. Selections
	-- 2. Hovered if is_dir
	-- 3. Current working directory respecting filters

	if #selected_items > 0 then
		-- Something was selected
		for _, item in pairs(selected_items) do
			-- Get the Urls as strings to selected items
			table.insert(target_urls, tostring(item))
			selection_kind = "selection"
		end
	elseif hovered_item and hovered_item.cha.is_dir then
		-- If a directory is hovered, get string url
		table.insert(target_urls, tostring(hovered_item.url))
			selection_kind = "hover"
	else
		-- Get all image files from the current pane (respects filters)
		for _, file in ipairs(files) do
			if not file.cha.is_dir then
				local filename = tostring(file.url)
				if is_image_file(filename) then
					table.insert(target_urls, filename)
				end
			end
		end
		selection_kind = "folder"
	end

	return target_urls, selection_kind
end)

return {
	entry = function()
		ya.mgr_emit("escape", { visual = true })

		local image_files, selection_kind = get_image_files()

		if #image_files == 0 then
			return ya.notify({
				title = "Swayimg Gallery",
				content = "No image files found in the " .. selection_kind,
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
