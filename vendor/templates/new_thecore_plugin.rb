# GEMFILE
gem 'thecore', path: '../../thecore_project/thecore'

# GEMSPEC
gsub_file "#{@name}.gemspec", 's.add_dependency', '# s.add_dependency'
gsub_file "#{@name}.gemspec", 's.add_development_dependency', '# s.add_development_dependency'

gsub_file "#{@name}.gemspec", 's.homepage', "s.homepage = 'https://www.taris.it' #"
gsub_file "#{@name}.gemspec", 's.summary', "s.summary = 'Thecorized #{@name}' #"
gsub_file "#{@name}.gemspec", 's.description', "s.description = 'Thecorized #{@name} full description.' #"

inject_into_file "#{@name}.gemspec", before: /^end/ do
  "  s.add_dependency 'thecore'
"
end

# Run bundle
run "bundle install"

# then run thecorize_plugin generator
run "rails g thecorize_plugin #{@name}"
