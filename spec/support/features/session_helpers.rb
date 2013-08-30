module Features
  
  module SessionHelpers
    
    def logs_in_with(email, password)
      visit login_path
      fill_in "login", :with => email
      fill_in "password", :with => password
      click_button "Login"
    end

    def logs_in_with_my_credentials
      visit login_path
      fill_in "login", :with => "to fill with username"
      fill_in "password", :with => "to fill with password"
      click_button "Login"
    end

  end
end