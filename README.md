# Thumbnail yazi

Display thumbnails in yazi 

## Demo
![Demo](demo.gif)

## Requirements

- **Yazi >= 26.8.15** — the plugin uses APIs added in that release and does nothing on older versions.
- **A Wayland session.** The gallery is [swayimg](https://github.com/artemsen/swayimg), which is
  Wayland-only, so this plugin does not work under X11.
- [swayimg](https://github.com/artemsen/swayimg)
- [ffmpegthumbnailer](https://github.com/dirkvdb/ffmpegthumbnailer) (only needed for video files)

## Installation

```sh
ya pkg add tasnimAlam/thumbnail
```

## Usage

Add this to your `~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = [ "<C-t>" ]
run  = 'plugin thumbnail'
desc = "Open current directory in Swayimg gallery"
```

Video files are included in the gallery as a still frame extracted by
`ffmpegthumbnailer` and cached under `$XDG_CACHE_HOME/thumbnail.yazi`. swayimg
cannot play video, so opening a video's tile shows that still frame, not the video.

## License

This plugin is MIT-licensed. For more information check the [LICENSE](LICENSE) file.
