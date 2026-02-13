require 'mini_magick'
require 'tmpdir'
require_relative 'uploader'

module SlackBigEmoji
  class ConversionError < StandardError; end
  class SizeLimitError < ConversionError; end

  class Converter
    attr_accessor :image, :file_name, :ratio, :file_resize_spec, :tile_width, :crop_size, :output_dir, :output_filename, :output_path, :output_ext, :width, :height, :frame_width, :frame_height, :canvas_width, :canvas_height

    def initialize(options={})
      @options = options
      @image = ::MiniMagick::Image.open(options[:file])
      @file_name = File.basename(options[:file], ".*")
      @output_ext = gif?(options[:file]) ? 'gif' : 'png'

      @tile_size = (options[:tile_size].to_i > 0) ? options[:tile_size].to_i : 128
      @gif_colors = options[:gif_colors].to_i
      @gif_colors = 256 if @gif_colors <= 0
      @gif_colors = 2 if @gif_colors < 2
      @gif_colors = 256 if @gif_colors > 256
      @gif_dither = options[:gif_dither].to_s.strip
      @gif_dither = "None" if @gif_dither.empty?
      @gif_optimize = !!options[:gif_optimize]
      @max_gif_bytes = options.key?(:max_gif_bytes) ? options[:max_gif_bytes].to_i : (128 * 1024)

      if @output_ext == 'gif'
        @frame_width, @frame_height = identify_first_pair(@image, "%w %h")
        @canvas_width, @canvas_height = identify_first_pair(@image, "%W %H")
        if @canvas_width.to_i > 0 && @canvas_height.to_i > 0
          @width = @canvas_width
          @height = @canvas_height
        else
          @width = @frame_width
          @height = @frame_height
        end
      else
        @width, @height = identify_first_pair(@image, "%w %h")
        @frame_width = @width
        @frame_height = @height
        @canvas_width = @width
        @canvas_height = @height
      end

      @ratio = @width.to_f / @height.to_f
      if not options[:width].to_i > 0
        options[:width] = '5'
      end
      @file_resize_spec = (@tile_size * options[:width].to_i).to_s + 'x' + (@tile_size * options[:width].to_i).to_s
      @tile_width = 5
      @crop_size = "#{@tile_size}x#{@tile_size}"
      @output_dir = options[:output_dir] || @file_name
      @output_filename = options[:output_filename] || @file_name
      @output_path = "#{@output_dir}/#{@output_filename}%02d.#{@output_ext}"
    end

    def valid?
      @width.to_i > 0 && @height.to_i > 0 && @width == @height
    end

    def convert
      Dir.mkdir(@output_dir) unless File.exist?(@output_dir)
      if @output_ext == 'gif'
        convert_gif_tiles
      else
        convert_static_tiles
      end
    end

    private

    def gif?(path)
      File.extname(path.to_s).downcase == '.gif'
    end

    def identify_first_pair(image, format)
      fmt = format.end_with?("\n") ? format : "#{format}\n"
      out = image.identify { |b| b.format(fmt) }.to_s
      first = out.lines.first.to_s.strip
      w, h = first.split(/\s+/, 3).first(2).map { |v| v.to_i }
      [w, h]
    end

    def square_resize_spec
      "#{@file_resize_spec}^"
    end

    def enforce_gif_size_limit!(path)
      return unless @output_ext == 'gif'
      return if @max_gif_bytes.to_i <= 0

      bytes = File.size(path)
      return if bytes <= @max_gif_bytes

      File.delete(path) if File.exist?(path)
      raise SizeLimitError, "GIF tile exceeds Slack's 128KB limit: #{File.basename(path)} is #{bytes} bytes (limit #{@max_gif_bytes}). Try reducing `--tile-size` or `--gif-colors` (or enable `--gif-optimize`)."
    end

    def convert_static_tiles
      convert_opts = [
        "-resize", square_resize_spec,
        "-gravity", "center",
        "-extent", @file_resize_spec,
        "-crop", @crop_size,
      ]
      ::MiniMagick.convert do |convert|
        convert << @image.path
        convert.merge! convert_opts
        convert << @output_path
      end
    end

    def convert_gif_tiles
      tiles_per_side = (@file_resize_spec.split('x').first.to_i / @tile_size)
      tile_count = tiles_per_side * tiles_per_side

      Dir.mktmpdir("slack-big-emoji-gif") do |tmpdir|
        full_path = File.join(tmpdir, "full.miff")
        palette_path = File.join(tmpdir, "palette.png")

        ::MiniMagick.convert do |convert|
          convert << @image.path
          convert << "-coalesce"
          convert << "+repage"
          convert << "-resize" << square_resize_spec
          convert << "-gravity" << "center"
          convert << "-background" << "none"
          convert << "-extent" << @file_resize_spec
          convert << "-gravity" << "NorthWest"
          convert << "+repage"
          convert << full_path
        end

        ::MiniMagick.convert do |convert|
          convert << full_path
          convert << "-append"
          convert << "-alpha" << "on"
          convert << "-colors" << @gif_colors.to_s
          convert << "-unique-colors"
          convert << palette_path
        end

        tile_count.times do |i|
          x = (i % tiles_per_side) * @tile_size
          y = (i / tiles_per_side) * @tile_size
          geometry = "#{@crop_size}+#{x}+#{y}"
          output_file = "#{@output_dir}/#{@output_filename}#{('%02d' % i)}.gif"

          ::MiniMagick.convert do |convert|
            convert << full_path
            convert << "-gravity" << "NorthWest"
            convert << "-crop" << geometry
            convert << "+repage"
            convert << "-alpha" << "on"
            convert << "-layers" << "OptimizeTransparency" if @gif_optimize
            convert << "-dither" << @gif_dither
            convert << "-remap" << palette_path
            convert << output_file
          end

          enforce_gif_size_limit!(output_file)
        end
      end
    end
  end
end
