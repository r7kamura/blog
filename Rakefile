require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Open local blog server on the browser"
task :open do
  `open http://localhost:9292/index.html`
end
