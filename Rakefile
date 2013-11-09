desc "Build and publish"
task :publish do
  sh "cd build"
  sh "git add --all"
  sh "git commit -m 'Update'"
  sh "git push"
  sh "cd .."
end
