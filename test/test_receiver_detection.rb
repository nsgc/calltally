# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestReceiverDetection < Minitest::Test
  def setup
    @base_dir = File.expand_path("samples", __dir__)
  end

  def test_class_method_receivers
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Test class method calls
    assert results["User.find"] > 0, "Should detect User.find"
    assert results["User.where"] > 0, "Should detect User.where"
    assert results["Post.published"] > 0, "Should detect Post.published"
  end

  def test_instance_variable_receivers
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "split_variables" => true  # Enable to test with variable names
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Test instance variable receivers with split_variables enabled
    assert results["(ivar:@post).title"] > 0, "Should detect @post.title as instance variable"
    assert results["(ivar:@post).content"] > 0, "Should detect @post.content as instance variable"
  end

  def test_local_variable_receivers
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true,
        "split_variables" => true  # Enable to test with variable names
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Test local variable receivers with split_variables enabled
    assert results["(var:user).name"] > 0, "Should detect user.name as local variable"
    assert results["(var:user).email"] > 0, "Should detect user.email as local variable"
  end

  def test_self_receivers
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Test self receivers
    assert results["(self).status="] > 0, "Should detect self.status= as self receiver"
    assert results["(self).save"] > 0, "Should detect self.save as self receiver"
  end

  def test_no_receiver_with_class_context
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Test no receiver calls (should include class context)
    assert results["Book#.validate"] > 0, "Should detect validate in Book class as Book#.validate"
    assert results["Book#.before_save"] > 0, "Should detect before_save in Book class as Book#.before_save"
    assert results["Book#.helper_method"] > 0, "Should detect helper_method in Book class as Book#.helper_method"
  end

  def test_chained_method_calls
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => true
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Chained calls - first call keeps original receiver, subsequent calls are (result)
    assert results["User.active"] > 0, "Should detect User.active in chain"
    assert results["(result).where"] > 0, "Should detect where as result in chain"
    assert results["(result).limit"] > 0, "Should detect limit as result in chain"
  end

  def test_without_include_nil_receiver_flag
    cfg = Calltally::Config.load(
      base_dir: @base_dir,
      cli_opts: {
        "dirs" => [@base_dir],
        "mode" => "pairs",
        "include_nil_receiver" => false
      }
    )

    scanner = Calltally::Scanner.new(base_dir: @base_dir, config: cfg)
    _, rows = scanner.scan

    # Convert to hash for easier assertion
    results = rows.map { |r, m, c| ["#{r}.#{m}", c] }.to_h

    # Without the flag, no receiver calls should not appear with #
    refute results.key?("#.validate"), "Should not include #.validate without flag"
    refute results.key?("#.before_save"), "Should not include #.before_save without flag"
  end
end