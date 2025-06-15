# Thumbnail yazi

Display thumbnails in yazi 

## Demo
![Demo](demo.gif)

## Requirements
[swayimg](https://github.com/artemsen/swayimg)

## Installation

```sh
ya pack -a tasnimAlam/thumbnail
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
