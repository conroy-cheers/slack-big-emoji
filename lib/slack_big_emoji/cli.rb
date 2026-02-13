require 'optparse'

module SlackBigEmoji
  class CLI
    attr_accessor :options

    def initialize(args)
      @options = parse(args)
    end

    def parse(args)
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: slack-big-emoji [options] FILE"
        opts.version = SlackBigEmoji::VERSION

        opts.on( '-f', '--file-name=NAME', 'Output filename.' ) do |val|
          options[:output_filename] = val
        end

        opts.on( '-o', '--output-dir=NAME', 'Output directory.' ) do |val|
          options[:output_dir] = val
        end

        options[:silent] = false
        opts.on( '-s', '--silent', 'Silent or quiet mode.' ) do
          options[:silent] = true
        end

        opts.on( '-w', '--width=NAME', 'Image width.' ) do |val|
          options[:width] = val
        end

        opts.on( '--tile-size=PX', Integer, 'Tile size in pixels (default: 128). Smaller can help keep GIFs under Slack limits.' ) do |val|
          options[:tile_size] = val
        end

        opts.on( '--gif-colors=N', Integer, 'GIF palette colors (2-256, default: 256). Lower reduces size.' ) do |val|
          options[:gif_colors] = val
        end

        opts.on( '--gif-dither=METHOD', 'GIF dithering method (default: None).' ) do |val|
          options[:gif_dither] = val
        end

        options[:gif_optimize] = false
        opts.on( '--gif-optimize', 'Optimize GIF frames (may reduce size).' ) do
          options[:gif_optimize] = true
        end

        opts.on( '--max-gif-bytes=BYTES', Integer, 'Fail if any output GIF exceeds BYTES (default: 131072). Use 0 to disable.' ) do |val|
          options[:max_gif_bytes] = val
        end

        options[:convert_only] = true
        opts.on( '-c', '--convert-only', 'Convert image but do not upload (default).' ) do
          options[:convert_only] = true
        end

        opts.on_tail( '-h', '--help', 'Show this message' ) do
          puts opts
          exit
        end
      end
      opts.parse! # removes switches destructively, but not non-options


      file = args.first # ARGV args only - no options

      # validates input to be one image file
      abort "Error: Missing input file" unless file
      abort "Just specify one file" if args.count > 1
      abort "Use a valid image file (png, jpeg, jpg, gif)" if (file =~ /.\.(png|jpeg|jpg|gif)$/i).nil?

      options[:file] = file

      options
    end

    def emoji_grid(file_name)
      (@options[:width].to_i * @options[:width].to_i).times do |i|
        puts "" if i % @options[:width].to_i == 0 && i != 0
        print ":#{file_name}#{("%02d" % i)}:"
      end
      puts # madrs
    end

    def log(*msg)
      unless @options[:silent]
        if msg.size == 1
          puts msg
        else
          printf "%-20s %s\n", msg.first, msg.last
        end
      end
    end
  end
end
