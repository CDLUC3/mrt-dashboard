require "selenium-webdriver"
require "spec_helper"
include RSpec::Expectations

describe("SearchAndMenuLinksSpec", type: :feature) do

  before(:each) do
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "http://localhost:3000/"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 30
    @verification_errors = []
  end
  
  after(:each) do
    @driver.quit
    @verification_errors.should == []
  end
  
  it "search_menu_links_permanent_links_spec" do

    #search and menu links test
    @driver.get(@base_url + "/")
    @driver.find_element(:link, "Login").click
    @driver.find_element(:id, "login").send_keys "testuser01"
    @driver.find_element(:id, "password").send_keys "testuser01"
    @driver.find_element(:css, "div.grid_8.prefix_2 > form > div.right_field > input[name=\"commit\"]").click
    @driver.find_element(:link, "Home").click
    @driver.find_element(:link, "Demo Merritt").click
    @driver.find_element(:link, "Collection home").click
    @driver.find_element(:link, "Add object").click
    (@driver.find_element(:css, "h2").text).should == "Add Object"
    @driver.find_element(:xpath, "//ul[@id='menu-1']/li[3]/a").click # click on "Change collection"
    @driver.find_element(:link, "Demo Merritt").click
    @driver.find_element(:name, "commit").click
    @driver.find_element(:id, "terms").send_keys "Shirin"
    @driver.find_element(:name, "commit").click
    verify { element_present?(:xpath, "//td[2]").should be_true }

    #permanent links test
    @driver.find_element(:link, "Collection: Demo Merritt").click
    @driver.find_element(:css, "tr.odd > td > a").click
    @driver.find_element(:link, "Version 1").click
    @driver.find_element(:css, "div.value > a").click
    @driver.find_element(:xpath, "//div[6]/div/a[3]").click
    @driver.find_element(:css, "div.value > a").click
    
    @driver.find_element(:css, "BODY").text.should_not =~ /Error/i
    @driver.find_element(:css, "BODY").text.should_not =~ /We\'re sorry/
  end
  
  def element_present?(how, what)
    @driver.find_element(how, what)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end
  
  def alert_present?()
    @driver.switch_to.alert
    true
  rescue Selenium::WebDriver::Error::NoAlertPresentError
    false
  end
  
  def verify(&blk)
    yield
  rescue ExpectationNotMetError => ex
    @verification_errors << ex
  end
  
  def close_alert_and_get_its_text(how, what)
    alert = @driver.switch_to().alert()
    alert_text = alert.text
    if (@accept_next_alert) then
      alert.accept()
    else
      alert.dismiss()
    end
    alert_text
  ensure
    @accept_next_alert = true
  end
end
