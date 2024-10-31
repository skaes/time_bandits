appraisals = [
  "6.1.7.10",
  "7.0.8.6",
  "7.1.5",
]

if RUBY_VERSION >= "3.1"
  appraisals << "7.2.2"
end

appraisals.each do |rails_version|
  %w(4.0 5.0).each do |redis_version|
    appraise "activesupport-#{rails_version}-redis-#{redis_version}" do
      gem "redis", "~> #{redis_version}"
      gem "activesupport", rails_version
      gem "activerecord", rails_version
    end
  end
end
