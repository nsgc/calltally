# frozen_string_literal: true

require "yaml"
require "set"

module Calltally
  class Config
    DEFAULTS = {
      "profile" => "auto",              # auto|rails|default
      "dirs" => %w[.],
      "exclude" => %w[spec test vendor node_modules tmp log .git .bundle],
      "top" => 100,
      "verbose" => false,
      "mode" => "pairs",                # pairs|methods|receivers
      "receivers" => nil,               # ["User","Group"]
      "methods" => nil,                 # ["where","find"]
      "include_nil_receiver" => false,
      "split_variables" => false,      # Show variable names vs grouping
      "receiver_types" => nil,          # ["locals", "ivars", "constants"] etc.
      "skip_operators" => true,
      "format" => "table",              # table|json|csv
      "output" => nil
    }.freeze

    RAILS_DIR_PRESET = %w[app lib config].freeze

    def self.load(base_dir:, cli_opts:)
      config = DEFAULTS.dup

      path = File.join(base_dir, ".calltally.yml")
      if File.file?(path)
        yaml = YAML.load_file(path) || {}
        yaml.each { |k, v| config[k.to_s] = v }
      end

      cli_opts.compact.each { |k, v| config[k.to_s] = v }

      config["profile"] = resolve_profile(base_dir, config["profile"])

      if config["profile"] == "rails"
        config["dirs"] = RAILS_DIR_PRESET if config["dirs"] == DEFAULTS["dirs"]
      end

      config["receivers"] = to_set_or_nil(config["receivers"])
      config["methods"]   = to_set_or_nil(config["methods"]&.map(&:to_s))
      config
    end

    def self.resolve_profile(base_dir, desired)
      return desired unless desired == "auto"

      gemfile_path = File.join(base_dir, "Gemfile")
      if File.file?(gemfile_path) && File.read(gemfile_path).include?("rails")
        "rails"
      else
        "default"
      end
    end

    def self.to_set_or_nil(v)
      case v
      when nil then nil
      when Set then v
      when Array then Set.new(v)
      else Set.new([v])
      end
    end
  end
end
