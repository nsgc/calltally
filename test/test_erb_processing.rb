# frozen_string_literal: true

require "test_helper"

class TestERBProcessing < Minitest::Test
  def setup
    @base_dir = File.expand_path("samples", __dir__)
  end

  def test_erb_files_detected_when_enabled
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_erb" => true
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should detect ERB template method calls
    assert (results["(ivar).name"] || 0) > 0, "Should detect @user.name from ERB"
    assert (results["(ivar).email"] || 0) > 0, "Should detect @user.email from ERB"
    assert (results["(ivar).active?"] || 0) > 0, "Should detect @user.active? from ERB"
    assert (results["(ivar).each"] || 0) > 0, "Should detect @posts.each from ERB"
    assert (results["(result).strftime"] || 0) > 0, "Should detect .strftime from ERB"
  end

  def test_erb_files_ignored_when_disabled
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_erb" => false
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should not have ERB-specific calls (only from .rb files)
    erb_calls = results.keys.select { |k| k.include?("strftime") }
    assert erb_calls.empty?, "Should not have ERB-specific calls when disabled: #{erb_calls}"
  end

  def test_erb_processing_handles_complex_templates
    # This tests that our ERB processing can handle various ERB constructs
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "methods",
        "include_erb" => true
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    methods = rows.map { |m, c| m }.to_set

    # Should detect various method types from ERB
    assert methods.include?("name"), "Should detect instance variable methods"
    assert methods.include?("each"), "Should detect iteration methods"
    assert methods.include?("strftime"), "Should detect chained method calls"
  end
end