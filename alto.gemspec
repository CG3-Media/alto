require_relative "lib/alto/version"

Gem::Specification.new do |spec|
  spec.name        = "alto"
  spec.version     = Alto::VERSION
  spec.authors     = [ "Corey Griffin" ]
  spec.email       = [ "iamcoreyg@gmail.com" ]
  spec.homepage    = "https://github.com/coreygriffin/alto"
  spec.summary     = "A mountable Rails engine that replicates core Canny.io-style feedback functionality"
  spec.description = "Alto is a Rails engine that provides ticket submission, commenting, voting, and status management functionality similar to Canny.io, designed to be easily integrated into existing Rails applications."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/coreygriffin/alto"
  spec.metadata["changelog_uri"] = "https://github.com/coreygriffin/alto/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.1", "< 9.0"
  spec.add_dependency "kaminari", "~> 1.2"

  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "rails-controller-testing", "~> 1.0"
end
