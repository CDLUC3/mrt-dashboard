class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'

  def store
    return Mrt::Sparql::Store.new('http://localhost:8080/sparql/')
  end
end
