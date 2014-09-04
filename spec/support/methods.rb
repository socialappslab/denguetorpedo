
def sign_in(user)
  visit root_path
  fill_in "username", :with => user.username
  fill_in "password", :with => user.password
  click_button "Entrar"
end

def sign_out(user)
  visit logout_path
end
