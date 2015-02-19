require 'rubygems'
require 'rake'
require 'rake/testtask'
begin # Ruby 1.8 vs 1.9 fuckery
  require 'rake/rdoctask'
rescue Exception
  require 'rdoc/task'
end
require 'fileutils'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

class Project
  def initialize args
    @name = args[:name]
    @description = args[:description]
    @version = args[:version]
  end

  def name
    return @name
  end

  def description
    return @description
  end

  def version
    return @version
  end
end

@project = Project.new(
    :name=>"deploytool",
    :description=>"deployment tool",
    :version=>"1.0.#{ENV['BUILD_NUMBER']}"
)

task :default do
  sh "rake -s -T"
end

desc "Remove build directory, etc."
task :clean do
  FileUtils.rmtree( "build"  )
  FileUtils.rmtree( "config" )
  if ( File.exists?("app_under_test.properties") )
    FileUtils.rm( "app_under_test.properties" )
  end
end

desc "Make build directories"
task :setup do
  File.open( "app_under_test.properties", "w" ) do |f|
    f.write( "application=JavaHttpRef\n" )
    f.write( "version=1.0.18\n" )
    f.write( "type=jar\n" )
  end
  FileUtils.makedirs( "build/db" )
  FileUtils.makedirs( "build/artifacts" )
  FileUtils.cp( "JavaHttpRef-1.0.18.jar", "build/artifacts" )
  FileUtils.makedirs( "config/JavaHttpRef" )
  File.open( "config/JavaHttpRef/config.properties", "w" ) do |f|
    f.write( "port=2003\n" )
  end
end

desc "Deploys the debian package to the test environment"
task :deploy_package => [:package] do
  `scp build/#{@project.name}.deb root@stag-dep-002.stag.net.local:`
  `ssh root@stag-dep-002.stag.net.local dpkg -i #{@project.name}.deb`
  `ssh root@stag-dep-002.stag.net.local service mcollective restart`

  `scp build/#{@project.name}.deb root@stag-dep-001.stag.net.local:`
  `ssh root@stag-dep-001.stag.net.local dpkg -i #{@project.name}.deb`
  `ssh root@stag-dep-001.stag.net.local service mcollective restart`
end

desc "Create Debian package"
task :package do
  require 'rubygems'
  require 'fpm'
  require 'fpm/program'
  FileUtils.mkdir_p( "build/package/opt/deploytool/" )
  FileUtils.cp_r( "lib", "build/package/opt/deploytool/" )
  FileUtils.cp_r( "bin", "build/package/opt/deploytool/" )

  arguments = [
    "-p", "build/#{@project.name}_#{@project.version}.deb" ,
    "-n" ,"#{@project.name}" ,
    "-v" ,"#{@project.version}" ,
    "-m" ,"David Ellis <david.ellis@timgroup.com>" ,
    "-d", "libnet-ssh2-ruby",
    "-d", "libnet-scp-ruby",
    "-a", 'all' ,
    "-t", 'deb' ,
    "-s", 'dir' ,
    "--description", "#{@project.description}" ,
    "--url", 'http://seleniumhq.org' ,
    "-C" ,'build/package'
  ]

  raise "problem creating debian package " unless FPM::Program.new.run(arguments) == 0
end

task :test => [:setup]
Rake::TestTask.new { |t|
  t.pattern = 'test/**/*_test.rb'
}

desc "Run specs"
RSpec::Core::RakeTask.new(:spec => ["ci:setup:rspec"]) do |t|
end
task :spec => [:test]

desc "Setup, package, test, and upload"
task :build  => [:setup,:package,:test]

desc "Run lint (Rubocop)"
task :lint do
  sh "/var/lib/gems/1.9.1/bin/rubocop --require rubocop/formatter/checkstyle_formatter "\
     "--format RuboCop::Formatter::CheckstyleFormatter --out tmp/checkstyle.xml"
end
