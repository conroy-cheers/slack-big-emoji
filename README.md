# Slack Big Emoji

Slack Big Emoji is a ruby command-line tool (see support) that helps out with the generation of big emojis to a Slack team.

See [What's a Big Emoji?](#whats-a-big-emoji) for more information.

## Support

About images:

- Tool can process static image files (png, jpg, jpeg) and animated GIFs.
- Images must be square or hold a w/h ratio of 1.0, this is going to be validated.
- GIF output is generated tile-by-tile to preserve animation. The tool fails if any output GIF exceeds 128KB; use `--tile-size`, `--gif-colors`, and `--gif-optimize` to reduce size.

## Usage

First, locate a square image and run:

```
nix run . -- liarliar.jpg
```

The script will resize and crop the image into tiles. Uploading to Slack is no longer supported (the old uploader depended on `mechanize`).

You can also run `slack-big-emoji --help` for more options.


## What's a Big Emoji?

Big emojis are a set of multiple emojis combined in a grid that together displays a big image.


> — Probably you: What?
>
> — Me, probably: Why not?
>
> — You: I mean, what's a Slack Big Emoji?

A Bigger Emoji™.

With this tool you'll be able to turn this Jim Carrey snapshot from the movie Liar Liar:

![Picture of Jim Carrey's teeth in the movie "Liar Liar"](https://user-images.githubusercontent.com/1270156/27774411-73333d40-5f57-11e7-933e-751dbc178617.jpg)

Into a set of emoji codes like this one:

```
:liarliar00::liarliar01::liarliar02::liarliar03::liarliar04:
:liarliar05::liarliar06::liarliar07::liarliar08::liarliar09:
:liarliar10::liarliar11::liarliar12::liarliar13::liarliar14:
:liarliar15::liarliar16::liarliar17::liarliar18::liarliar19:
:liarliar20::liarliar21::liarliar22::liarliar23::liarliar24:
```

Once posted in Slack will look like this (mobile looks shitty, tho):

![](https://user-images.githubusercontent.com/1270156/27774488-935d2850-5f58-11e7-8417-944b1251a3da.png)

## Advanced Installation & Usage

This gem can be used from an application too, add this line to your Gemfile:

```ruby
gem 'slack-big-emoji'
```

And then execute:

```ruby
$ bundle install
```

For example, this is the minimal setup for a command-line tool:

```ruby
require 'slack-big-emoji'
# require 'slack-big-emoji/cli'

# Sets up option parser coming from ARGV
cli = SlackBigEmoji::CLI.new(ARGV)

# Converter takes as args the file and conversion options
emoji = SlackBigEmoji::Converter.new(cli.options)
emoji.convert

# The uploader takes care to upload a folder full of images
uploader = SlackBigEmoji::Uploader.new(emoji.output_filename)
uploader.upload_emojis

# The CLI generates a grid based on the output filename,
# this is the grid to be used in Slack to see the full emoji
cli.emoji_grid(emoji.output_filename)
```

Further documentation can be read in code.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kinduff/slack-big-emoji. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
