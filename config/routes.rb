MrtDashboard::Application.routes.draw do
  resource 'users', as: 'account'

  get('object/recent(.:format)' => 'object#recent')
  get('feeds/recent'  => 'feeds#recent')
  get('show/view/*id' => 'show#view')
  get('show/*id'      => 'show#show')
  root(to: 'home#index')
  get('login'         => 'user_sessions#login',
      :as             => :login,
      :constraints    => { method: 'GET' })
  post('login'         => 'user_sessions#login_post',
       :as             => :login_post,
       :constraints    => { method: 'POST' })
  get('logout'        => 'user_sessions#logout',
      :as             => :logout)
  match('guest_login' => 'user_sessions#guest_login',
        :as => :guest_login,
        via: [:get, :post])

  # pattern of URL is http://merritt.cdlib.org/mode/collectionid|objectid[/versionid[/fileid]]
  # where mode is an underlying action:
  # a: add
  # async: trigger async download?
  # d: download
  # u: download (user friendly)
  # m: metadata (landing page)
  # s: search

  # m/ark... can route to either collection or object depending on the constraint
  get('m/:group' => 'collection#index',
      :constraints => CollectionConstraint.new)
  get('s/:group' => 'collection#search_results')
  get('async/:object' => 'object#async')
  get('async/:object/:version' => 'version#async')
  get('asyncd/:object' => 'lostorage#direct')
  get('asyncd/:object/:version' => 'lostorage#direct')
  get('m/:object' => 'object#index')
  get('m/:object/:version' => 'version#index')
  get('d/:object' => 'object#download')
  get('d/:object/:version' => 'version#download')
  get('d/:object/:version/*file' => 'file#download', :format => false)
  get('u/:object' => 'object#downloadUser')
  get('u/:object/:version' => 'version#downloadUser')
  get('dm/:object' => 'object#downloadManifest')
  get('s/:group' => 'collection#search_results')
  get('a/:group' => 'object#add')

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))', via: [:get, :post]

end
