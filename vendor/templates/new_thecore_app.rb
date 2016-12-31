#remove the index.html
remove_file 'public/index.html'

# Selecting the gems needed
current_gem_user = run "bundle config www.taris.it", capture: true
# Set for the current user (/Users/iltasu/.bundle/config): "bah"
credentials = current_gem_user.match(/^[\s\t]*Set for the current user .*: "(.*)"/)[1] rescue nil

if credentials.blank? || yes? "Credentials already set, do you want to change them?", :red
  username = ask "Please provide your username: ", :red
  password = ask "Please provide your password: ", :red
  credentials = "#{username}:#{password}"
  run "bundle config www.taris.it '#{credentials}'"
end

add_source "https://www.taris.it/gems-repo" do
  output = run "gem search ^thecore$ -ra --source https://www.taris.it/gems-repo", capture: true
  versions = output.match(/^[\s\t]*thecore \((.*)\)/)[1].split(", ") rescue []
  unless versions.empty?
    answer = ask "Which version of thecore do you want to use?", :red, limited_to: versions.push("cancel")
    answer = "1" if answer == "cancel"
  end
  gem 'thecore', "~> #{answer.split(".").first}" # , path: '../../thecore_project/thecore'

  all_gems_in_source = run "gem search .* -r --source https://www.taris.it/gems-repo", capture: true
  # Getting all the gem names in the previous serach
  gems = all_gems_in_source.scan(/^[\s\t]*(.*) \(.*\)/).flatten
  gems.each do |a_gem|
    gem a_gem if a_gem != 'thecore' && yes?("Would you like to use the gem '#{a_gem}' for this project?", :red)
  end
# GEMFILE
end

# Run bundle
run "bundle"

# then run thecorize_plugin generator
rails_command "g thecorize_app #{@name}"

# DB
rails_command "db:create"
rails_command "db:migrate"
