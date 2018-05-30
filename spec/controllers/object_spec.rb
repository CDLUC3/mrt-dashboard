require 'rails_helper'

describe ObjectController do

  # TODO: move these to the method tests
  describe 'filters' do
    describe 'permissions' do
      describe 'download permission' do
        it 'prevents object download without permissions'
        it 'prevents producer file download (:downloadUser) without permissions'
        it 'prevents manifest download without permissions'
        it 'prevents async download without permissions'
      end

      describe 'read permission' do
        it 'prevents index view without permission'
      end
    end

    describe 'size checks' do
      it 'prevents download when download size exceeded'
      it "redirects to #{LostorageController} when sync download size exceeded"
    end
  end

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

  describe 'pending' do
    it ':mint'
    it ':index'
    it ':download'
    it ':downloadUser'
    it ':downloadManifest'
    it ':async'
    it ':upload'
    it ':recent'
    it ':mk_httpclient'
  end

end
