# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "datoki"
  spec.version       = `cat VERSION`
  spec.authors       = ["da99"]
  spec.email         = ["i-hate-spam-1234567@mailinator.com"]
  spec.summary       = %q{A gem to manage PGsql records.}
  spec.description   = %q{
    My way of dealing with postgresql 9.3+ databases.
  }
  spec.homepage      = "https://github.com/da99/datoki"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |file|
    file.index('bin/') == 0 && file != "bin/#{File.basename Dir.pwd}"
  }
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry"           , "> 0.9"
  spec.add_development_dependency "bundler"       , "> 1.5"
  spec.add_development_dependency "bacon"         , "> 1.0"
  spec.add_development_dependency "Bacon_Colored" , "> 0.1"

  spec.add_runtime_dependency "sequel", '> 4.12'
  spec.add_runtime_dependency "pg", '>= 0.17'
end
