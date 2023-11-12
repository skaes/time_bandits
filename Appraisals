appraisals = [
  "6.0.6.1",
  "6.1.7.6",
  "7.0.8",
  "7.1.0",
  "7.1.1"
]

appraisals.insert(0, "5.2.8.1") if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("3.0.0")

appraisals.each do |rails_version|
  %w(4.0 5.0).each do |redis_version|
    appraise "activesupport-#{rails_version}-redis-#{redis_version}" do
      gem "redis", "~> #{redis_version}"
      gem "activesupport", rails_version
      gem "activerecord", rails_version
    end
  end
end
