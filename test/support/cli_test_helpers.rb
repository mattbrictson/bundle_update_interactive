# frozen_string_literal: true

require "stringio"

module CLITestHelpers
  private

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

Minitest::Test.include(CLITestHelpers)
