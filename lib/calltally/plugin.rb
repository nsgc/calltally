# frozen_string_literal: true

module Calltally
  module Plugin
    @handlers = {}

    class << self
      def register(ext, &block)
        @handlers[ext] = block
      end

      def handle(path, src, cfg)
        if (handler = @handlers[File.extname(path)])
          handler.call(path, src, cfg)
        end
      end

      def registered_exts
        @handlers.keys
      end
    end
  end
end
