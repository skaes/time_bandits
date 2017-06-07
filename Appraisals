[
  "4.1.16",
  "4.2.8",
  "5.0.3",
  "5.1.1",
].each do |rails_version|
  appraise "activesupport-#{rails_version}" do
    gem "activesupport", rails_version
    gem "activerecord", rails_version
  end
end
