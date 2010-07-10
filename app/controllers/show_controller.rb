require 'rdf'

class ShowController < ApplicationController
  def show
    @info = UriInfo.new("http://#{params[:id]}")
  end
end
