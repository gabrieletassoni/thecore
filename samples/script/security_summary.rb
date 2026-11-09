# frozen_string_literal: true

# Lists the findings of GitLab CE's SAST and Secret Detection reports and exits 1 when
# there are any, or when a report is missing. On CE those jobs stay green whatever they
# find and there is no Security Dashboard, so the security-summary CI job runs this to
# make findings visible (see CLAUDE.md "Security scanning").
#
#   ruby script/security_summary.rb gl-sast-report.json gl-secret-detection-report.json
require "json"

missing = ARGV.reject { |path| File.exist?(path) }
missing.each do |path|
  puts "#{path}: missing. Did its scanner fail, or did GitLab refuse to store its artifacts?"
end

total = (ARGV - missing).sum do |path|
  findings = JSON.parse(File.read(path)).fetch("vulnerabilities", [])
  puts "#{path}: #{findings.size} findings"
  findings.each do |f|
    location = f["location"] || {}
    puts "  #{f['severity']}\t#{f['name'] || f['description']}\t#{location['file']}:#{location['start_line']}"
  end
  findings.size
end

puts "#{total} findings"
exit(total.zero? && missing.empty? ? 0 : 1)
