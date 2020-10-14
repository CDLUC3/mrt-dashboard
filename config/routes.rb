MrtDashboard::Application.routes.draw do
  resource 'users', as: 'account'

  get('object/recent(.:format)' => 'object#recent')
  get('feeds/recent'  => 'feeds#recent')
  get('show/view/*id' => 'show#view')
  get('show/*id'      => 'show#show')
  root(to: 'home#index')
  get('login' => 'user_sessions#login',
      :as => :login,
      :constraints => { method: 'GET' })
  post('login' => 'user_sessions#login_post',
       :as => :login_post,
       :constraints => { method: 'POST' })
  get('logout' => 'user_sessions#logout',
      :as => :logout)
  match('guest_login' => 'user_sessions#guest_login',
        :as => :guest_login,
        via: %i[get post])

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
  get('m/:object' => 'object#index')
  get('m/:object/:version' => 'version#index')
  get('d/:object' => 'object#download')
  get('d/:object/:version' => 'version#download')
  get('d/:object/:version/*file' => 'file#download', :format => false)
  get('api/presign-file/:object/:version/*file' => 'file#presign', :format => false, :as => 'presign_file')
  get('api/get-storage-key-file/:object/:version/*file' => 'file#storage_key', :format => false, :as => 'storage_key_file')
  get('api/assemble-version/:object/:version' => 'version#presign', :format => false, :as => 'presign_version')
  get('api/assemble-obj/:object' => 'object#presign', :format => false, :as => 'presign_obj')
  get('api/presign-obj-by-token/:token' => 'application#presign_obj_by_token', :format => false, :as => 'presign_obj_by_token')
  get('u/:object' => 'object#download_user')
  get('u/:object/:version' => 'version#download_user')
  get('dm/:object' => 'object#download_manifest')
  get('s/:group' => 'collection#search_results')
  get('a/:group' => 'object#add')

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))', via: %i[get post]

  get('application/render_unavailable' => 'application#render_unavailable')
  post('object/ingest' => 'object#ingest')
  post('object/update' => 'object#update')
  post('object/mint' => 'object#mint')
  post('object/upload' => 'object#upload')

  get('home/choose_collection' => 'home#choose_collection')
  post('user/update' => 'user#update')
  get('user/update' => 'user#update')
  get('collection/object_count' => 'collection#object_count')
  get('collection/version_count' => 'collection#version_count')
  get('collection/file_count' => 'collection#file_count')
  get('collection/total_size' => 'collection#total_size')
  get('collection/billable_size' => 'collection#billable_size')
  get('collection/search_results' => 'collection#search_results')
  get('version/index' => 'version#index')

end
