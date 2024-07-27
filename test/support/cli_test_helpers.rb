# frozen_string_literal: true

module CLITestHelpers
  private

  def capture_io_and_exit_status
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
  end
end

Minitest::Test.include(CLITestHelpers)
