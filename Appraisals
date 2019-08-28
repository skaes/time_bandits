[
  "4.1.16",
  "4.2.8",
  "4.2.9",
  "4.2.11.1",
  "5.0.3",
  "5.0.4",
  "5.0.7",
  "5.0.7.2",
  "5.1.1",
  "5.1.2",
  "5.1.5",
  "5.1.7",
  "5.2.0",
  "5.2.3",
  "6.0.0"
].each do |rails_version|
  next if RUBY_VERSION >= "2.4.0" && rails_version < "4.2.8"
  appraise "activesupport-#{rails_version}" do
    gem "activesupport", rails_version
    gem "activerecord", rails_version
  end
end
