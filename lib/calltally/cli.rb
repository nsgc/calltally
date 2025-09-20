# frozen_string_literal: true

require "optparse"
require "yaml"

module Calltally
  class CLI
    def self.start(argv) = new.run(argv)

    def run(argv)
      sub = argv.first
      return print_help if %w[-h --help help].include?(sub)

      case sub
      when "scan" then run_scan(argv.drop(1))
      when nil then run_scan(argv)  # Default to scan when no command specified
      else
        # If first arg doesn't look like a command, treat as scan with path
        if sub.start_with?("-") || File.exist?(sub) || sub == "."
          run_scan(argv)
        else
          warn "Unknown command: #{sub}"
          print_help

          exit 1
        end
      end
    end

    def print_help
      puts <<~USAGE
        calltally #{Calltally::VERSION}
        Usage:
          calltally [PATH] [options]  # Defaults to scan command
          calltally scan [PATH] [options]

        Commands:
          scan    Scan a directory (default PATH='.') and summarize method usage. (default)

        Options (scan):
          --profile PROFILE        auto(default)|rails|default
          -d, --dirs x,y           Directories to include
          -x, --exclude x,y        Path parts to exclude
          -n, --top N              Show top N (default: 100)
          -v, --verbose
          --mode MODE              Output mode:
                                   - pairs (default): receiver-method pairs
                                   - methods: method names only
                                   - receivers: receiver names only
          --receivers x,y          Filter by receiver constants (e.g. User,Group)
          --methods x,y            Filter by method names (e.g. where,find)
          --include-nil-receiver   Count calls without constant receiver (as '(no recv)')
          --split-variables        Show variable names (e.g. '(var:user)' instead of '(var)')
          --only-locals            Show only local variable receivers
          --only-ivars             Show only instance variable receivers
          --only-cvars             Show only class variable receivers
          --only-gvars             Show only global variable receivers
          --only-constants         Show only constant receivers
          --only-results           Show only method results receivers
          --[no-]skip-operators    Skip operator methods like +, -, ==, [] (default: true)
          --plugins x,y            Enable plugins (e.g., erb for calltally-erb)
          --format F               table(default)|json|csv
          -o, --output PATH        Write result to file instead of STDOUT
          --config PATH            Use a specific .calltally.yml
          -h, --help
      USAGE
    end

    def run_scan(argv)
      base_dir = "."
      cli_opts = {}
      config_override = nil

      opts = OptionParser.new do |opt|
        opt.on("--profile PROFILE") { |v| cli_opts["profile"] = v }
        opt.on("-d x,y", "--dirs x,y", Array) { |v| cli_opts["dirs"] = v }
        opt.on("-x x,y", "--exclude x,y", Array) { |v| cli_opts["exclude"] = v }
        opt.on("-n N", "--top N", Integer) { |v| cli_opts["top"] = v }
        opt.on("-v", "--verbose") { cli_opts["verbose"] = true }
        opt.on("--mode MODE", [:pairs, :methods, :receivers]) { |v| cli_opts["mode"] = v.to_s }
        opt.on("--receivers x,y", Array) { |v| cli_opts["receivers"] = v }
        opt.on("--methods x,y", Array) { |v| cli_opts["methods"] = v }
        opt.on("--include-nil-receiver") { cli_opts["include_nil_receiver"] = true }
        opt.on("--split-variables") { cli_opts["split_variables"] = true }
        opt.on("--only-locals") { (cli_opts["receiver_types"] ||= []) << "locals" }
        opt.on("--only-ivars") { (cli_opts["receiver_types"] ||= []) << "ivars" }
        opt.on("--only-cvars") { (cli_opts["receiver_types"] ||= []) << "cvars" }
        opt.on("--only-gvars") { (cli_opts["receiver_types"] ||= []) << "gvars" }
        opt.on("--only-constants") { (cli_opts["receiver_types"] ||= []) << "constants" }
        opt.on("--only-results") { (cli_opts["receiver_types"] ||= []) << "results" }
        opt.on("--[no-]skip-operators") { |v| cli_opts["skip_operators"] = v }
        opt.on("--plugins x,y", Array) { |v| cli_opts["plugins"] = v }
        opt.on("--format F", [:table, :json, :csv]) { |v| cli_opts["format"] = v.to_s }
        opt.on("-o PATH", "--output PATH") { |v| cli_opts["output"] = v }
        opt.on("--config PATH") { |v| config_override = v }
        opt.on("-h", "--help") { puts opt; exit }
      end

      if argv.first && !argv.first.start_with?("-")
        base_dir = argv.shift
      end

      opts.parse!(argv)

      if config_override && File.file?(config_override)
        yaml = YAML.load_file(config_override) || {}
        yaml.each { |k, v| cli_opts[k.to_s] = v unless cli_opts.key?(k.to_s) }
      end

      config = Calltally::Config.load(base_dir: base_dir, cli_opts: cli_opts)

      mode, rows = Calltally::Scanner.new(base_dir: base_dir, config: config).scan

      out = config["output"] ? File.open(config["output"], "w") : $stdout
      begin
        case config["format"]
        when "json" then Calltally::Formatter.print_json(mode: mode, data: rows, io: out)
        when "csv"  then Calltally::Formatter.print_csv(mode: mode, data: rows, io: out)
        else             Calltally::Formatter.print_table(mode: mode, data: rows, io: out)
        end
      ensure
        out.close if out.is_a?(File)
      end
    end
  end
end
