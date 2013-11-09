desc "Publish"
task :publish do
  sh "git checkout master"
  sh "bundle exec middleman build"
  sh "cd build"
  sh "git add --all"
  sh "git commit -m 'Update'"
  sh "git push"
  sh "cd .."
end
