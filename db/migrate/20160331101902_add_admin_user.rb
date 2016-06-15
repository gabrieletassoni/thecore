class AddAdminUser < ActiveRecord::Migration
  Dir['../../app/models/*.rb'].each do |f|
    require f
  end

  def change
    puts "Temporary admin account, please change password when testing is finished."
    User.reset_column_information
    u = User.new(
        username: "admin",
        email: "admin@example.com",
        password: "1234",
        password_confirmation: "1234",
        admin: true
    )
    # u.skip_confirmation!
    u.save!
  end
end
