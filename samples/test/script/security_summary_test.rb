# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "open3"
require "tmpdir"

# script/security_summary.rb turns the JSON reports of GitLab CE's SAST and Secret
# Detection jobs, which stay green whatever they find, into a readable list and a
# failing exit status (see CLAUDE.md "Security scanning"). Plain Minitest, no app boot:
# `bin/rails test` runs it with the rest, `ruby test/script/security_summary_test.rb` alone.
class SecuritySummaryTest < Minitest::Test
  SCRIPT = File.expand_path("../../script/security_summary.rb", __dir__)

  def run_summary(*reports)
    Dir.mktmpdir do |dir|
      paths = reports.each_with_index.map do |report, i|
        path = File.join(dir, "report#{i}.json")
        File.write(path, JSON.generate(report)) if report
        path
      end
      Open3.capture2e(RbConfig.ruby, SCRIPT, *paths)
    end
  end

  def finding(severity, name, file, line)
    { "severity" => severity, "name" => name, "location" => { "file" => file, "start_line" => line } }
  end

  def test_no_findings_exits_zero
    output, status = run_summary({ "vulnerabilities" => [] })

    assert status.success?
    assert_includes output, "0 findings"
  end

  def test_findings_from_every_report_are_listed_and_fail
    sast = { "vulnerabilities" => [ finding("High", "SQL injection", "app/models/a.rb", 12) ] }
    secrets = { "vulnerabilities" => [ finding("Critical", "RSA private key", "config/key.pem", 1) ] }

    output, status = run_summary(sast, secrets)

    assert_equal false, status.success?
    assert_includes output, "High"
    assert_includes output, "SQL injection"
    assert_includes output, "app/models/a.rb:12"
    assert_includes output, "config/key.pem:1"
    assert_includes output, "2 findings"
  end

  def test_missing_report_fails
    # A scanner job that ran but whose report never reached this job (failed scanner,
    # artifacts not uploaded) must not look like a clean scan.
    output, status = run_summary(nil, { "vulnerabilities" => [] })

    assert_equal false, status.success?
    assert_includes output, "missing"
  end
end
