class MrtSolr
  def initialize(args={})
    if args[:q] then
      @q = args[:q]
    elsif args[:doc] then
      @doc = args[:doc]
    end
    @rsolr = RSolr.connect(:url => SOLR_SERVER)
  end

  def doc
    @doc ||= @rsolr.get('select', :params => {:q => "type:#{solr_type} and #{@q}" })['response']['docs'][0]
  end

  def self.bulk_loader(klass, q)
    rsolr = RSolr.connect(:url => SOLR_SERVER)
    return rsolr.get('select', :params => {:q => q})['response']['docs'].map {|d| klass.new(:doc=>d) }
  end
end

