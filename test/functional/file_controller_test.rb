require 'test_helper'

class FileControllerTest < ActionController::TestCase
  include Encoder

  test "download file works" do
    get(:download, {:object => "ark:/99999/fk40k2sqf", :version=>1, :file=>"system/mrt-erc.txt"},
        {:uid => "anonymous"})
    assert(:success)
  end
  
  test "version 0 latest file redirects" do
    get(:download, {:object => "ark:/99999/fk40k2sqf", :version=>0, :file=>"system/mrt-erc.txt"},
        {:uid => "anonymous"})
    assert_redirected_to(:action => :download, :object => urlencode("ark:/99999/fk40k2sqf"), 
                         :version=>1, :file => urlencode("system/mrt-erc.txt"))
  end
end
