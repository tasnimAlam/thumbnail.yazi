--- @since 26.8.15

-- Common image extensions
local IMAGE_EXTENSIONS = {
	jpg = true, jpeg = true, png = true, gif = true, bmp = true,
	webp = true, svg = true, ico = true, tiff = true, tif = true,
	heic = true, heif = true, avif = true, jxl = true
}

-- Common video extensions. swayimg cannot decode video, so these are shown
-- through a still frame extracted by ffmpegthumbnailer.
local VIDEO_EXTENSIONS = {
	mp4 = true, mkv = true, webm = true, mov = true, avi = true,
	wmv = true, flv = true, m4v = true, mpg = true, mpeg = true,
	ts = true, m2ts = true, ["3gp"] = true, ogv = true
}

local function extension_of(filename)
	local ext = filename:match("%.([^%.]+)$")
	return ext and ext:lower() or nil
end

local function is_image_file(filename)
	local ext = extension_of(filename)
	return ext ~= nil and IMAGE_EXTENSIONS[ext] or false
end

local function is_video_file(filename)
	local ext = extension_of(filename)
	return ext ~= nil and VIDEO_EXTENSIONS[ext] or false
end

local get_media_files = ya.sync(function()
	local current_pane = cx.active.current
	local hovered_item = current_pane.hovered
	local files = current_pane.files
	local selected_items = cx.active.selected

  -- Full URLs to image files or directories
	local target_urls = {}
	-- Full URLs to video files, thumbnailed before being handed to swayimg
	local video_urls = {}
	local selection_kind = nil

	-- Order of operations
	-- 1. Selections
	-- 2. Hovered if is_dir
	-- 3. Current working directory respecting filters

	if #selected_items > 0 then
		-- Something was selected
		for _, item in pairs(selected_items) do
			-- Get the Urls as strings to selected items
			local url = tostring(item)
			if is_video_file(url) then
				table.insert(video_urls, url)
			else
				-- Images and directories go to swayimg untouched
				-- ponytail: directories are passed through as-is, so swayimg only
				-- finds the images inside them. Expand with fs.read_dir if videos
				-- inside a selected/hovered directory ever need thumbnails too.
				table.insert(target_urls, url)
			end
			selection_kind = "selection"
		end
	elseif hovered_item and hovered_item.cha.is_dir then
		-- If a directory is hovered, get string url
		table.insert(target_urls, tostring(hovered_item.url))
			selection_kind = "hover"
	else
		-- Get all image and video files from the current pane (respects filters)
		for _, file in ipairs(files) do
			if not file.cha.is_dir then
				local filename = tostring(file.url)
				if is_image_file(filename) then
					table.insert(target_urls, filename)
				elseif is_video_file(filename) then
					table.insert(video_urls, filename)
				end
			end
		end
		selection_kind = "folder"
	end

	return target_urls, video_urls, selection_kind
end)

local function cache_dir()
	local base = os.getenv("XDG_CACHE_HOME")
	if not base or base == "" then
		base = string.format("%s/.cache", os.getenv("HOME"))
	end
	return string.format("%s/thumbnail.yazi", base)
end

-- Where the still frame for `video_path` lives. The modification time is part of
-- the hash so a re-encoded file invalidates its own thumbnail. The basename is
-- kept as a prefix so swayimg's gallery labels stay readable.
local function thumbnail_path(dir, video_path)
	local cha = fs.cha(Url(video_path))
	local mtime = cha and cha.mtime or 0
	local basename = video_path:match("([^/]+)$") or video_path
	local stem = basename:match("^(.*)%.[^%.]+$") or basename
	return string.format("%s/%s-%s.jpg", dir, stem, ya.hash(video_path .. mtime))
end

-- Returns the thumbnails for `video_urls`, generating the missing ones.
local function build_thumbnails(video_urls)
	local dir = cache_dir()
	fs.create("dir_all", Url(dir))

	local thumbnails, pending = {}, {}
	for _, video_url in ipairs(video_urls) do
		local thumbnail = thumbnail_path(dir, video_url)
		table.insert(thumbnails, thumbnail)
		if not fs.cha(Url(thumbnail)) then
			table.insert(pending, { source = video_url, output = thumbnail })
		end
	end

	if #pending == 0 then
		return thumbnails
	end

	ya.notify({
		title = "Swayimg Gallery",
		content = string.format("Generating %d video thumbnail(s)...", #pending),
		level = "info",
		timeout = 3,
	})

	-- Spawn everything first, then wait, so generation runs in parallel
	for _, job in ipairs(pending) do
		job.child = Command("ffmpegthumbnailer")
			:arg({ "-i", job.source, "-o", job.output, "-s", "512" })
			:stdout(Command.NULL)
			:stderr(Command.NULL)
			:spawn()
	end
	for _, job in ipairs(pending) do
		local status = job.child and job.child:wait()
		if not (status and status.success) then
			-- ffmpegthumbnailer leaves an empty file behind when it gives up on a
			-- file, so clear it: an empty .jpg would break swayimg's gallery and
			-- would otherwise be cached as a valid thumbnail forever.
			fs.remove("file", Url(job.output))
		end
	end

	-- Drop the ones that failed, rather than handing swayimg a missing path
	local existing = {}
	for _, thumbnail in ipairs(thumbnails) do
		if fs.cha(Url(thumbnail)) then
			table.insert(existing, thumbnail)
		end
	end
	return existing
end

return {
	entry = function()
		ya.emit("escape", { visual = true })

		local media_files, video_files, selection_kind = get_media_files()

		if #media_files == 0 and #video_files == 0 then
			return ya.notify({
				title = "Swayimg Gallery",
				content = "No image or video files found in the " .. selection_kind,
				level = "warn",
				timeout = 5,
			})
		end

		for _, thumbnail in ipairs(build_thumbnails(video_files)) do
			table.insert(media_files, thumbnail)
		end

		-- Build command with all filtered image files
		local cmd = Command("swayimg"):arg("--gallery")
		for _, media_file in ipairs(media_files) do
			cmd = cmd:arg(media_file)
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
