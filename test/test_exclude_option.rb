# frozen_string_literal: true

require "test_helper"
require "open3"

class TestExcludeOption < Minitest::Test
  def run_calltally(path, options = "")
    cmd = "ruby -I lib exe/calltally #{path} #{options}"
    stdout, stderr, _ = Open3.capture3(cmd)
    stderr.empty? ? stdout : "#{stdout}#{stderr}"
  end

  def test_with_exclude_removes_directory
    output = run_calltally("test/samples", "-n 10 -x exclude_test --include-nil-receiver")

    refute_match(/bar_method/, output, "bar_method should be excluded")
    refute_match(/fetch_data/, output, "fetch_data should be excluded")
    refute_match(/handle/, output, "handle should be excluded")

    assert_match(/times|positive|zero|tap|upcase|fetch|merge/, output, "methods from other files should be shown")
  end

  def test_exclude_adds_to_defaults
    output_without = run_calltally("test/samples", "-v")
    output_with = run_calltally("test/samples", "-x exclude_test -v")

    assert_match(/Scan targets: 4 files/, output_without, "should scan 4 files normally")
    assert_match(/Scan targets: 2 files/, output_with, "should scan 2 files when excluded")
  end

  def test_multiple_excludes
    output = run_calltally("test/samples", "-n 10 -x exclude_test,advanced_variables --include-nil-receiver")

    refute_match(/bar_method/, output, "exclude_test/bar.rb methods should be excluded")
    refute_match(/fetch_data/, output, "exclude_test/bar.rb methods should be excluded")
    refute_match(/positive\?/, output, "advanced_variables.rb methods should be excluded")

    assert_match(/User\.find|User\.where|Post\.published/, output, "basic_calls.rb methods should be shown")
  end
end
