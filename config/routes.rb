MrtDashboard::Application.routes.draw do
  resource 'users', as: 'account'

  # User authentication
  # ------------------------------------------------
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

  # UI navigation rules
  # ------------------------------------------------
  root(to: 'home#index')

  # obsolete?
  #  get('show/view/*id' => 'show#view')
  #  get('show/*id'      => 'show#show')

  # pattern of URL is http://merritt.cdlib.org/mode/collectionid|objectid[/versionid[/fileid]]
  # where mode is an underlying action:
  # ------------------------------------------------
  #   a: add
  #   d: download
  #   u: download (user friendly)
  #   m: metadata (landing page)
  #   s: search
  #
  #   m/ark... can route to either collection or object depending on the constraint
  get('m/:group' => 'collection#index',
      :constraints => CollectionConstraint.new)
  get('s/:group' => 'collection#search_results')
  get('a/:group' => 'object#add')

  get('m/:object' => 'object#index')
  get('m/:object/:version' => 'version#index')

  get('home/choose_collection' => 'home#choose_collection')
  get('user/update' => 'user#update')
  get('collection/search_results' => 'collection#search_results')
  get('api/:group/local_id_search' => 'collection#local_id_search')
  get('version/index' => 'version#index')

  # All downloads should favor the following endpoint
  get('api/presign-file/:object/:version/*file' => 'file#presign', :format => false, :as => 'presign_file')

  # Presigned object download
  get('api/assemble-obj/:object' => 'object#presign', :format => false, :as => 'presign_obj')
  get('api/assemble-version/:object/:version' => 'version#presign', :format => false, :as => 'presign_version')
  get('api/presign-obj-by-token/:token' => 'application#presign_obj_by_token', :format => false, :as => 'presign_obj_by_token')

  # TODO: clients should not need this endopoint
  get('api/get-storage-key-file/:object/:version/*file' => 'file#storage_key', :format => false, :as => 'storage_key_file')

  # API object info
  get('api/object_info/:object' => 'object#object_info', :format => false)


  # General error handling
  get('application/render_unavailable' => 'application#render_unavailable')

  # collction summary actions
  get('collection/object_count' => 'collection#object_count')
  get('collection/version_count' => 'collection#version_count')
  get('collection/file_count' => 'collection#file_count')
  get('collection/total_size' => 'collection#total_size')
  get('collection/billable_size' => 'collection#billable_size')

  # Object modification
  post('object/ingest' => 'object#ingest')
  post('object/update' => 'object#update')
  post('object/mint' => 'object#mint')
  post('object/upload' => 'object#upload')
  post('user/update' => 'user#update')

  # Deprecate the following actions
  get('d/:object' => 'object#download')
  get('d/:object/:version' => 'version#download')
  get('d/:object/:version/*file' => 'file#download', :format => false)

  get('u/:object' => 'object#download_user')
  get('u/:object/:version' => 'version#download_user')

  get('dm/:object' => 'object#download_manifest')

  # Atom feed rules
  # ------------------------------------------------
  get('object/recent(.:format)' => 'object#recent')

  # obsolete?
  get('feeds/recent' => 'feeds#recent')

end
