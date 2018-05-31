require 'rails_helper'

describe ObjectController do

  # TODO: ditto for update, or shared examples
  describe :ingest do
    describe 'request' do
      it 'posts the argument to the ingest service as a multipart form'
      it 'forwards the response from the ingest service'
    end

    describe 'restrictions' do
      it 'returns 401 when user not logged in'
      it "returns 400 when file parameter is not a #{ActionDispatch::Http::UploadedFile} or similar"
      it "returns 404 when user doesn't have write permission"
    end

    describe 'filename' do
      it 'sets the filename based on the provided filename'
      it "sets the filename based on the provided #{ActionDispatch::Http::UploadedFile} or similar"
    end

    describe 'submitter' do
      it 'sets the submitter based on the provided submitter parameter'
      it 'sets the submitter based on the current user'
    end
  end

  describe :mint do
    it 'requires a user'
    it 'requires the user to have write permissions on the current submission profile'
    it 'posts a mint request'
    it 'forwards the response from the minting service'
  end

  describe :index do
    it 'prevents index view without read permission'
  end

  describe :download do
    it 'prevents download without permissions'
    it 'prevents download when download size exceeded'
    it "redirects to #{LostorageController} when sync download size exceeded"
    it 'streams the object as a zipfile'
  end

  describe :downloadUser do
    it 'prevents download without permissions'
    it "streams the object's producer files as a zipfile"
  end

  describe :downloadManifest do
    it 'prevents download without permissions'
    it 'streams the manifest as XML'
  end

  describe :async do
    it 'fails when object is too big for any download'
    it 'fails when object is too small for asynchronous download'
    it 'succeeds when object is the right size for synchronous download'
  end

  describe :upload do
    it 'redirects and displays an error when no file provided'
    it 'posts an update to the ingest service'
    it 'sets the batch ID for display'
  end

  describe :recent do
    it '404s cleanly when collection does not exist'
    it 'gets the list of objects'
  end

  describe :mk_httpclient do
    it 'configures and returns an HTTP client'
  end

end
