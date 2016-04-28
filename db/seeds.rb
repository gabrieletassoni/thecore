puts "Temporary admin account, please change password when testing is finished."
u = User.new(
    username: "admin",
    email: "admin@example.com",
    password: "1234",
    password_confirmation: "1234",
    admin: true
)
# u.skip_confirmation!
u.save!
