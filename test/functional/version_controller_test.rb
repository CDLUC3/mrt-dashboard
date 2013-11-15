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
    assert_select(HTML::Selector.new("div.key:content(version number:) + div.value"), 
                  :text=>"1")
    assert_select(HTML::Selector.new("div.key:content(title:) + div.value"), 
                  :text=>"Fairs and Markets&nbsp;")
    assert_select(HTML::Selector.new("div.key:content(creator:) + div.value"), 
                  :text=>"Dorothea Lange&nbsp;")
    assert_select(HTML::Selector.new("div.key:content(date:) + div.value"), 
                  :text=>"ca. 1954&nbsp;")
    assert_select(HTML::Selector.new("div.key:content(local id:) + div.value"), 
                  :text=>"ark:/13030/ft4b69n700&nbsp;")
    assert_select(HTML::Selector.new("div.key:content(object primary identifier:) + div.value"), 
                  :text=>"ark:/99999/fk40k2sqf")
  end
end
