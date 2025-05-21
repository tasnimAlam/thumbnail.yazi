# Thumbnail yazi

Display thumbnails in yazi 

## Installation

```sh
ya pack -a tasnimAlam/thumbnail.yazi
```

## Usage

Add this to your `~/.config/yazi/keymap.toml`:

```toml
[[manager.prepend_keymap]]
on   = [ "<C-t>" ]
run  = 'plugin thumbnail'
desc = "Open current directory in Swayimg gallery"
```

## License

This plugin is MIT-licensed. For more information check the [LICENSE](LICENSE) file.
