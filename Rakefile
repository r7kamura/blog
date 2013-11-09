task default: [:build, :publish]

desc "Build"
task :build do
  sh "bundle exec middleman build --clean"
end

desc "Publish"
task :publish do
  sh "cd build"
  sh "git add --all"
  sh "git commit -m 'Update'"
  sh "git push"
  sh "cd .."
end
