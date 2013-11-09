desc "Publish"
task :publish do
  sh "bundle exec middleman build"
  sh "cd build"
  sh "git add --all"
  sh "git commit -m 'Update'"
  sh "git push"
  sh "cd .."
end
