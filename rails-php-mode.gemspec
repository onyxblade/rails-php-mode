Gem::Specification.new do |gem|
  gem.authors       = ['mizuhashi']
  gem.email         = ["cichol@live.cn"]
  gem.summary       = ""
  gem.description   = "Turn your Rails app into a PHP app in one line."
  gem.homepage      = "http://github.com/CicholGricenchos/rails-php-mode"
  gem.license       = "MIT"
  gem.files         = ['lib/rails-php-mode.rb']
  gem.name          = "rails-php-mode"
  gem.require_paths = ["lib"]
  gem.version       = "0.1"
  gem.add_dependency 'rails', '>= 4.2.5', '< 5.0'
end