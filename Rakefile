require 'spec/rake/spectask'
require 'rake/gempackagetask' 

task :default => :spec

Spec::Rake::SpecTask.new do |t|
  t.ruby_opts = ['-rtest/unit']
  t.spec_files = FileList['spec/*_spec.rb']
end

gemspec = Gem::Specification.new do |s| 
  s.name = "cosy" 
  s.summary = "Compact Sequencing Syntax" 
  s.description= "A domain specific language for sequencing events in time" 
  s.version = "0.0.1" 
  s.author = "Adam Murray" 
  s.email = "adam@compusition.com" 
  s.homepage = "http://compusition.com" 
  s.platform = Gem::Platform::RUBY 
  s.required_ruby_version = '>=1.8' 
  s.rubyforge_project = 'cosy'
  s.files = Dir['**/**'] 
  s.executables = [ 'cosy' ] 
  s.test_files = Dir["spec/spec*.rb"] 
  s.has_rdoc = false 
  
  s.add_dependency 'treetop',  '>= 1.2'
  s.add_dependency 'midilib',  '>= 1.2'
  s.add_dependency 'midiator', '>= 0.3.0'
  s.add_dependency 'gamelan',  '>= 0.3'
  s.add_dependency 'osc',      '>= 0.1.4'
end 
Rake::GemPackageTask.new(gemspec).define 

