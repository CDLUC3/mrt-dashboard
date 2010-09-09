require 'ftools'
require 'rdf'

class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_object

  def index
    @stored_object = @object[Mrt::Object['hasStoredObject']].first
    @versions = @stored_object[Mrt::Object['versionSeq']].first.to_list
    #files for current version
    @files = @versions[@versions.length-1][Mrt::Version.hasFile]
    @files.delete_if {|file| file[RDF::DC.identifier].to_s[0..10].eql?('system/mrt-')}
    @files.sort! {|x,y| File.basename(x[RDF::DC.identifier].to_s.downcase) <=> File.basename(y[RDF::DC.identifier].to_s.downcase)}
    @total_size = @stored_object[Mrt::Object.totalActualSize].to_s.to_i
    
  end
end
