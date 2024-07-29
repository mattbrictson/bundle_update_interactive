# frozen_string_literal: true

require "stringio"
require "tty/prompt/test"

module CLITestHelpers
  private

  # Patch Minitest's capture_io to make it compatible with TTY::Prompt
  def capture_io
    super do
      $stdout.extend(TTY::Prompt::StringIOExtensions) if $stdout.is_a?(StringIO)
      yield
    end
  end

  def capture_io_and_exit_status(stdin_data: "")
    orig_stdin = $stdin
    $stdin = StringIO.new(stdin_data)

    exit_status = nil
    stdout = +""
    stderr = +""

    out, err = capture_io do
      yield
    rescue SystemExit => e
      exit_status = e.status
    end

    stdout << out
    stderr << err

    [stdout, stderr, exit_status]
  ensure
    $stdin = orig_stdin
  end
end

Minitest::Test.prepend(CLITestHelpers)
