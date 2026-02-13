require 'logger'

module SlackBigEmoji
  class Uploader
    def initialize(dir)
      @dir = dir
    end
    attr_reader :dir

    def upload_emojis
      raise NotImplementedError, "Uploader removed (mechanize dependency dropped). Run with -c/--convert-only to skip uploading."
    end
  end
end
