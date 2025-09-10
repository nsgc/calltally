# Sample file with class variables and global variables

class CounterService
  @@total_count = 0

  def increment
    @@total_count += 1
    @@total_count.times { |i| puts i }
    @@total_count.positive?
  end

  def self.reset_counter
    @@total_count = 0
    @@total_count.zero?
  end
end

# Global variables usage
$debug_mode = true
$app_config = { env: 'development' }

class Logger
  def log(message)
    return unless $debug_mode

    $debug_mode.tap { puts "Debug is on" }
    $app_config[:env].upcase
    $app_config.fetch(:logger, 'default')
  end

  def self.configure
    $app_config ||= {}
    $app_config.merge!(logger: 'custom')
  end
end

# Mixed usage
def process_data
  @@total_count ||= 0
  $global_result = @@total_count * 2

  $global_result.positive? ? 'success' : 'failure'
end
