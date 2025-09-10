# frozen_string_literal: true

require "test_helper"

class TestReceiverTypeFilters < Minitest::Test
  def setup
    @base_dir = File.expand_path("samples", __dir__)
  end

  def test_only_locals_filter
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "receiver_types" => ["locals"]
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should only have local variable receivers
    assert results["(var).name"] > 0, "Should include local variable receivers"
    assert results["(var).email"] > 0, "Should include local variable receivers"

    # Should not have other types
    refute results.key?("User.where"), "Should not include constant receivers"
    refute results.key?("(ivar).title"), "Should not include instance variable receivers"
    refute results.key?("#.validate"), "Should not include implicit receivers"
  end

  def test_only_ivars_filter
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "receiver_types" => ["ivars"]
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should only have instance variable receivers
    assert results["(ivar).title"] > 0, "Should include instance variable receivers"
    assert results["(ivar).content"] > 0, "Should include instance variable receivers"

    # Should not have other types
    refute results.key?("User.where"), "Should not include constant receivers"
    refute results.key?("(var).name"), "Should not include local variable receivers"
    refute results.key?("#.validate"), "Should not include implicit receivers"
  end

  def test_only_constants_filter
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "receiver_types" => ["constants"]
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should only have constant receivers
    assert results["User.where"] > 0, "Should include constant receivers"
    assert results["Post.published"] > 0, "Should include constant receivers"

    # Should not have other types
    refute results.key?("(var).name"), "Should not include local variable receivers"
    refute results.key?("(ivar).title"), "Should not include instance variable receivers"
    refute results.key?("#.validate"), "Should not include implicit receivers"
  end

  def test_multiple_receiver_types
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "receiver_types" => ["locals", "constants"]  # Both locals and constants
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should have both locals and constants
    assert results["(var).name"] > 0, "Should include local variable receivers"
    assert results["User.where"] > 0, "Should include constant receivers"

    # Should not have ivars
    refute results.key?("(ivar).title"), "Should not include instance variable receivers"
  end

  def test_no_filter_includes_all
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true
        # No receiver_types filter
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should have all types
    assert results["(var).name"] > 0, "Should include local variable receivers"
    assert results["(ivar).title"] > 0, "Should include instance variable receivers"
    assert results["User.where"] > 0, "Should include constant receivers"
    assert results["Book#.validate"] > 0, "Should include implicit receivers"
  end

  def test_only_cvars_filter
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "receiver_types" => ["cvars"]
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should only have class variable receivers
    assert results["(cvar).times"] > 0, "Should include class variable receivers"
    assert results["(cvar).positive?"] > 0, "Should include class variable receivers"
    assert results["(cvar).zero?"] > 0, "Should include class variable receivers"

    # Should not have other types
    refute results.key?("User.where"), "Should not include constant receivers"
    refute results.key?("(var).name"), "Should not include local variable receivers"
    refute results.key?("(ivar).title"), "Should not include instance variable receivers"
  end

  def test_only_gvars_filter
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "receiver_types" => ["gvars"]
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should only have global variable receivers
    assert results["(gvar).tap"] > 0, "Should include global variable receivers"
    assert results["(gvar).fetch"] > 0, "Should include global variable receivers"
    assert results["(gvar).positive?"] > 0, "Should include global variable receivers"

    # Should not have other types
    refute results.key?("User.where"), "Should not include constant receivers"
    refute results.key?("(var).name"), "Should not include local variable receivers"
    refute results.key?("(ivar).title"), "Should not include instance variable receivers"
  end

  def test_split_variables_with_cvars_and_gvars
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "split_variables" => true,
        "receiver_types" => ["cvars", "gvars"]
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Should have specific variable names with split_variables
    has_cvar = results.any? { |k, _| k.start_with?("(cvar:@@") }
    has_gvar = results.any? { |k, _| k.start_with?("(gvar:$") }

    assert has_cvar, "Should have specific class variable names"
    assert has_gvar, "Should have specific global variable names"
  end
end
