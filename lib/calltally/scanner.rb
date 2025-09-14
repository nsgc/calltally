# frozen_string_literal: true

require "find"
require "calltally/prism_visitor"

module Calltally
  class Scanner
    def initialize(base_dir:, config:)
      @base_dir = File.expand_path(base_dir)
      @config   = config
    end

    def scan
      files = collect_paths
      warn_verbose "Scan targets: #{files.size} files"
      files.first(10).each { |file| warn_verbose " - #{file}" }

      pair_counts     = Hash.new(0)
      method_counts   = Hash.new(0)
      receiver_counts = Hash.new(0)

      visitor = PrismVisitor.new(@config, pair_counts, method_counts, receiver_counts)

      files.each do |path|
        begin
          src    = read_source(path)
          result = ::Prism.parse(src)
          if (root = result.value)
            visitor.visit(root)
          else
            warn_verbose "Prism.parse returned nil: #{path}"
          end
        rescue => e
          warn "Error: #{path}: #{e.class}: #{e.message}"
        end
      end

      top = Integer(@config["top"])
      mode_sym = @config["mode"].to_s.downcase.to_sym

      case mode_sym
      when :pairs
        rows = pair_counts.sort_by { |(_, _), c| -c }.first(top).map { |(r, m), c| [r, m, c] }
      when :methods
        rows = method_counts.sort_by { |_, c| -c }.first(top).map { |m, c| [m, c] }
      when :receivers
        rows = receiver_counts.sort_by { |_, c| -c }.first(top).map { |r, c| [r, c] }
      else
        raise ArgumentError, "Unknown mode: #{@config['mode']}"
      end

      [mode_sym, rows]
    end

    private

    def warn_verbose(msg)
      return unless @config && @config["verbose"]
      warn(msg)
    end

    def collect_paths
      exts = %w[.rb .ru .rake]

      files = []
      @config["dirs"].each do |dir|
        absolute_path = File.expand_path(dir, @base_dir)
        next unless Dir.exist?(absolute_path)

        Find.find(absolute_path) do |path|
          next if File.directory?(path)
          next unless exts.include?(File.extname(path))
          next if excluded?(path)

          files << path
        end
      end

      files.uniq
    end

    def excluded?(path)
      rel = path.sub(@base_dir + "/", "")
      @config["exclude"].any? { |ex| rel.include?("/#{ex}/") || File.basename(rel).start_with?("#{ex}.") }
    end

    def read_source(path)
      src = File.binread(path)
      src.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
    end
  end
end
