require "selenium-webdriver"
require "spec_helper"
include RSpec::Expectations

describe("ObjDownloadDua", type: :feature) do

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
  
  it "test_obj_download_dua" do
    @driver.get(@base_url + "/")
    @driver.find_element(:link, "Login").click
    @driver.find_element(:id, "login").send_keys "testuser01"
    @driver.find_element(:id, "password").send_keys "testuser01"
    @driver.find_element(:css, "div.grid_8.prefix_2 > form > div.right_field > input[name=\"commit\"]").click
    @driver.find_element(:link, "Demo Merritt").click
    @driver.find_element(:css, "tr.odd > td > a").click
    @driver.find_element(:name, "commit").click
    
    @driver.find_element(:id, "accept")
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
