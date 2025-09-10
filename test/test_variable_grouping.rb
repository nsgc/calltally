# frozen_string_literal: true

require "test_helper"

class TestVariableGrouping < Minitest::Test
  def setup
    @base_dir = File.expand_path("samples", __dir__)
  end

  def test_default_groups_all_variables
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true
        # split_variables is false by default
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # All local variables should be grouped as (var)
    assert results["(var).name"] > 0, "Should group all local variables as (var)"
    assert results["(var).email"] > 0, "Should group all local variables as (var)"
    assert results["(var).active?"] > 0, "Should group all local variables as (var)"

    # All instance variables should be grouped as (ivar)
    assert results["(ivar).title"] > 0, "Should group all instance variables as (ivar)"
    assert results["(ivar).content"] > 0, "Should group all instance variables as (ivar)"

    # Should not have specific variable names
    refute results.key?("(var:user).name"), "Should not have specific variable names"
    refute results.key?("(var:u).active?"), "Should not have specific variable names"
    refute results.key?("(ivar:@post).title"), "Should not have specific instance variable names"
  end

  def test_split_variables_shows_names
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "split_variables" => true
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should have specific variable names
    assert results["(var:user).name"] > 0, "Should have specific variable name 'user'"
    assert results["(var:user).email"] > 0, "Should have specific variable name 'user'"
    assert results["(var:u).active?"] > 0, "Should have specific variable name 'u'"

    # Should have specific instance variable names
    assert results["(ivar:@post).title"] > 0, "Should have specific instance variable name '@post'"
    assert results["(ivar:@post).content"] > 0, "Should have specific instance variable name '@post'"

    # Should not have grouped format
    refute results.key?("(var).name"), "Should not have grouped format"
    refute results.key?("(ivar).title"), "Should not have grouped format"
  end

  def test_grouped_variables_aggregate_counts
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true
        # split_variables is false by default
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # The count should aggregate all variable accesses
    # In basic_calls.rb we have user.name, user.email, users.each (which has u inside)
    # All should be counted under (var)
    assert results["(var).name"] >= 1, "Should have aggregated count for .name"
    assert results["(var).email"] >= 1, "Should have aggregated count for .email"
  end
end
