MrtDashboard::Application.routes.draw do
  resource 'users', :as => 'account'

  match('object/recent(.:format)'  => 'object#recent')
  match('feeds/recent'  => 'feeds#recent')
  match('show/view/*id' => 'show#view')
  match('show/*id'      => 'show#show')
  root(:to => "home#index")
  match('login'         => 'user_sessions#login',
        :as             => :login,
        :constraints    => {:method => 'GET'})
  match('login'         => 'user_sessions#login_post',
        :as             => :login_post,
        :constraints    => {:method => 'POST'})
  match('logout'        => 'user_sessions#logout',
        :as             => :logout)

  match('guest_login'   => 'user_sessions#guest_login', 
         :as            => :guest_login)

  # pattern of URL is http://merritt.cdlib.org/mode/collectionid|objectid[/versionid[/fileid]]
  # where mode is an underlying action:
  # a: add
  # d: download
  # m: metadata (landing page)
  # s: search 
   
  # m/ark... can route to either collection or object depending on the constraint
  match('m/:group' => 'collection#index',
        :constraints => CollectionConstraint.new)
  match('m/:object' => 'object#show')
  match( 'm/:group/:version' => 'version#index')#, :constraints => {:group => /ark(%3A|:)(%2F|\/).+/i})
  match('d/:object' => 'object#download')
  match('d/:object/:version' => 'version#download')
  match('d/:object/:version/:file' => 'file#display' , :constraints => {:file => /.+/i})
  match('s/:group' => 'collection#search_results')
  match('a/:group' => 'object#add')

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
end
