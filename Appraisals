appraisals = [
  "6.1.7.8",
  "7.0.8.4",
  "7.1.3.4"
]

appraisals.each do |rails_version|
  %w(4.0 5.0).each do |redis_version|
    appraise "activesupport-#{rails_version}-redis-#{redis_version}" do
      gem "redis", "~> #{redis_version}"
      gem "activesupport", rails_version
      gem "activerecord", rails_version
    end
  end
end
