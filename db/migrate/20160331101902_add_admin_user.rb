class AddAdminUser < ActiveRecord::Migration[4.2]
  def up
    puts "Generating admin user"
    User.reset_column_information
    u=User.find_or_initialize_by(username: "admin")
    puts "Utente Admin: #{u.inspect}"
    u.email = "admin@example.com"
    psswd = SecureRandom.hex(5)
    puts "\tThecore admin password is:\n\n\t\t#{psswd}\n\n\tplease save it somewhere, securely."
    File.open('.passwords', 'w') do |f|
      f.write(psswd)
    end
    u.password = psswd
    u.password_confirmation = psswd
    u.admin = true
    # u.skip_confirmation!
    u.save
  end
end
