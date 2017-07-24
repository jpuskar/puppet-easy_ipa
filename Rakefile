require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "pkg/**/*.pp"]

# Forsake support for Puppet 2.6.2 for the benefit of cleaner code.
# http://puppet-lint.com/checks/class_inherits_from_params_class/
PuppetLint.configuration.send('disable_class_inherits_from_params_class')

desc "Run all tests"
task :default => [:lint, :validate, :spec]
