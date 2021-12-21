appraisals = [
  "6.0.4.4",
  "6.1.4.4",
  "7.0.0"
]

appraisals.insert(0, "5.2.6") if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("3.0.0")

appraisals.each do |rails_version|
  appraise "activesupport-#{rails_version}" do
    gem "activesupport", rails_version
    gem "activerecord", rails_version
  end
end
