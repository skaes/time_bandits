appraisals = [
  "6.1.7.10",
  "7.0.8.7",
  "7.1.5.1",
]

if RUBY_VERSION >= "3.1"
  appraisals << "7.2.2.1"
end

if RUBY_VERSION >= "3.2"
  appraisals << "8.0.2"
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
