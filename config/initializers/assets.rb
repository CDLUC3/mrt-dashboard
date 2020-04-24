Rails.application.config.assets.paths << Rails.root.join('node_modules')

Rails.application.config.assets.precompile += %w[
  jquery_ujs.js,
  jquery.js
 ]
