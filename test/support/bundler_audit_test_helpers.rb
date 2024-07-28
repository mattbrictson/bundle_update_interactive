# frozen_string_literal: true

require "bundler"
require "bundler/audit"
require "bundler/audit/scanner"

module BundlerAuditTestHelpers
  private

  def mock_vulnerable_gems(*gem_names)
    vulnerable_gems = gem_names.flatten.map { |name| Gem::Specification.new(name) }
    audit_report = mock(vulnerable_gems: vulnerable_gems)
    scanner = mock(report: audit_report)

    Bundler::Audit::Database.expects(:update!)
    Bundler::Audit::Scanner.expects(:new).returns(scanner)
  end
end

Minitest::Test.include(BundlerAuditTestHelpers)
