# frozen_string_literal: true

require "json"
begin
  require "csv"
rescue LoadError
  # CSV is optional for Ruby 3.4+
end

module Calltally
  module Formatter
    module_function

    def print_table(mode:, data:, io: $stdout)
      case mode
      when :pairs
        name_w  = (data.map { |receiver, method, _| "#{receiver}.#{method}".length }.max || 0)
        count_w = (data.map { |_, _, count| count.to_s.length }.max || 1)

        data.each { |receiver, method, count|
          io.puts "#{count.to_s.rjust(count_w)}  #{(receiver + "." + method).ljust(name_w)}"
        }
      when :methods, :receivers
        name_w  = (data.map { |name, _| name.to_s.length }.max || 0)
        count_w = (data.map { |_, count| count.to_s.length }.max || 1)

        data.each { |name, count|
          io.puts "#{count.to_s.rjust(count_w)}  #{name.to_s.ljust(name_w)}"
        }
      end
    end

    def print_json(mode:, data:, io: $stdout)
      payload =
        case mode
        when :pairs
          { mode: "pairs", rows: data.map { |receiver, method, count| { receiver:, method:, count: } } }
        when :methods
          { mode: "methods", rows: data.map { |method, count| { method:, count: } } }
        when :receivers
          { mode: "receivers", rows: data.map { |receiver, count| { receiver:, count: } } }
        end

      io.puts JSON.pretty_generate(payload)
    end

    def print_csv(mode:, data:, io: $stdout)
      case mode
      when :pairs
        io.puts CSV.generate_line(%w[receiver method count])
        data.each { |receiver, method, count| io.puts CSV.generate_line([receiver, method, count]) }
      when :methods
        io.puts CSV.generate_line(%w[method count])
        data.each { |method, count| io.puts CSV.generate_line([method, count]) }
      when :receivers
        io.puts CSV.generate_line(%w[receiver count])
        data.each { |receiver, count| io.puts CSV.generate_line([receiver, count]) }
      end
    end
  end
end
