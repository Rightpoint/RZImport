
namespace :test do
  
  task :install do
    sh("brew update && brew upgrade xctool") rescue nil
  end
  
  task :iOS do
    run_tests('iOS Tests', 'iphonesimulator')
  end
  
  task :OSX do
    run_tests('OSX Tests', 'macosx')
  end
  
end

task :test do
  Rake::Task['test:iOS'].invoke
  Rake::Task['test:OSX'].invoke
end

task :default => 'test'

private

def run_tests(scheme, sdk)
  sh("xctool -workspace RZAutoImport.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' clean test") rescue nil
end