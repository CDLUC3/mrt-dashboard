require 'test_helper'

class VersionControllerTest < ActionController::TestCase
  test "version 0 redirects to latest" do
    get(:index, {:object => "ark:/99999/fk40k2sqf", :version=>0}, {:uid => "anonymous"})
    assert_redirected_to(:action => :index, :object => "ark:/99999/fk40k2sqf", :version=>1)
  end

  test "version 0 download redirects to latest" do
    get(:download, {:object => "ark:/99999/fk40k2sqf", :version=>0}, {:uid => "anonymous"})
    assert_redirected_to(:action => :download, :object => "ark:/99999/fk40k2sqf", :version=>1)
  end

  test "index" do
    get(:index, {:object => "ark:/99999/fk40k2sqf", :version=>1}, {:uid => "anonymous"})
    assert_response(:success)
  end
end
