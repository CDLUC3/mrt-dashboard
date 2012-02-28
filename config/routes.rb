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

  match 'guest_login', :to => 'user_sessions#guest_login', :as => :guest_login, :via => :post

  # pattern of URL is http://merritt.cdlib.org/mode/collectionid|objectid[/versionid[/fileid]]
  # where mode is an underlying action:
  # a: add
  # d: download
  # m: metadata (landing page)
  # s: search  
  match('m/:collection' => 'collection#index')
  match('m/:object' => 'collection#index')
  
  match('d/:object' => 'object#download')
  match('d/:object/:version' => 'version#download')
  match('d/:object/:version/:file' => 'file#display')

  match('s/:collection' => 'collection#search_results')
  match('a/:collection' => 'object#add')

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
end
