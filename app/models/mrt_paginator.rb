require 'will_paginate/finders/base'

module MrtPaginator
  include WillPaginate::Finders::Base

  protected
  def wp_query(options, pager, args, &block)
    find_options = options.except(:count).update(:offset => pager.offset, :limit => pager.per_page) 
    pager.replace(self.find(find_options))
    unless pager.total_entries
      pager.total_entries = wp_count(options)
    end
  end
  
  def wp_count(options)
    self.count(options.except(:count, :order))
  end
end
