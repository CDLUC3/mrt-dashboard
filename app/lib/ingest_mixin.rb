module IngestMixin
  include HttpMixin

  def ingest_filename
    filename = params[:filename] || params[:file].original_filename
    # We found a case in which % in the original filename triggers an encoding error
    # Pull the filename from the POST header using a pattern match
    unless filename.valid_encoding?
      begin
        m = /filename="([^"]+)"/.match(params[:file].headers)
        filename = m[1] if m
      rescue StandardError
        # :nocov:
        filename = filename.encode('UTF-8', invalid: :replace, undef: :replace)
        # :nocov:
      end
    end
    filename
  end

  def ingest_params_from(params, current_user)
    filename = ingest_filename
    {
      'creator' => params[:creator],
      'date' => params[:date],
      'digestType' => params[:digestType],
      'digestValue' => params[:digestValue],
      'file' => params[:file].tempfile,
      'filename' => filename,
      'localIdentifier' => params[:localIdentifier],
      'notification' => params[:notification],
      'notificationFormat' => params[:notificationFormat],
      'primaryIdentifier' => params[:primaryIdentifier],
      'profile' => params[:profile],
      'note' => params[:note],
      'responseForm' => params[:responseForm],
      'DataCite.resourceType' => params['DataCite.resourceType'],
      'DC.contributor' => params['DC.contributor'],
      'DC.coverage' => params['DC.coverage'],
      'DC.creator' => params['DC.creator'],
      'DC.date' => params['DC.date'],
      'DC.description' => params['DC.description'],
      'DC.format' => params['DC.format'],
      'DC.identifier' => params['DC.identifier'],
      'DC.language' => params['DC.language'],
      'DC.publisher' => params['DC.publisher'],
      'DC.relation' => params['DC.relation'],
      'DC.rights' => params['DC.rights'],
      'DC.source' => params['DC.source'],
      'DC.subject' => params['DC.subject'],
      'DC.title' => params['DC.title'],
      'DC.type' => params['DC.type'],
      'submitter' => params['submitter'] || "#{current_user.login}/#{current_user.displayname}",
      'title' => params[:title],
      'synchronousMode' => params[:synchronousMode],
      'retainTargetURL' => params[:retainTargetURL],
      'type' => params[:type]
    }.reject { |_k, v| v.blank? }
  end

  def update_params_from(params, current_user)
    filename = ingest_filename
    {
      'creator' => params[:creator],
      'date' => params[:date],
      'digestType' => params[:digestType],
      'digestValue' => params[:digestValue],
      'file' => params[:file].tempfile,
      'filename' => filename,
      'localIdentifier' => params[:localIdentifier],
      'notification' => params[:notification],
      'notificationFormat' => params[:notificationFormat],
      'primaryIdentifier' => params[:primaryIdentifier],
      'profile' => params[:profile],
      'note' => params[:note],
      'responseForm' => params[:responseForm],
      'DataCite.resourceType' => params['DataCite.resourceType'],
      'DC.contributor' => params['DC.contributor'],
      'DC.coverage' => params['DC.coverage'],
      'DC.creator' => params['DC.creator'],
      'DC.date' => params['DC.date'],
      'DC.description' => params['DC.description'],
      'DC.format' => params['DC.format'],
      'DC.identifier' => params['DC.identifier'],
      'DC.language' => params['DC.language'],
      'DC.publisher' => params['DC.publisher'],
      'DC.relation' => params['DC.relation'],
      'DC.rights' => params['DC.rights'],
      'DC.source' => params['DC.source'],
      'DC.subject' => params['DC.subject'],
      'DC.title' => params['DC.title'],
      'DC.type' => params['DC.type'],
      'submitter' => "#{current_user.login}/#{current_user.displayname}",
      'title' => params[:title],
      'synchronousMode' => params[:synchronousMode],
      'retainTargetURL' => params[:retainTargetURL],
      'type' => params[:type]
    }.reject { |_k, v| v.blank? }
  end

  def upload_params_from(params, current_user, current_group)
    filename = ingest_filename
    {
      'file' => params[:file].tempfile,
      'type' => params[:object_type],
      'submitter' => "#{current_user.login}/#{current_user.displayname}",
      'filename' => filename,
      'profile' => current_group.submission_profile,
      'creator' => params[:author],
      'title' => params[:title],
      'primaryIdentifier' => params[:primary_id],
      'date' => params[:date],
      'localIdentifier' => params[:local_id], # local identifier necessary, nulls?
      'responseForm' => 'xml'
    }.reject { |_key, value| value.blank? }
  end

  def post_upload
    render status: 500, plain: 'current user not set' unless current_user && current_group
    ingest_params = upload_params_from(params, current_user, current_group)
    resp          = http_post(APP_CONFIG['ingest_service_update'], ingest_params)
    @doc          = Nokogiri::XML(resp.content) { |config| config.strict.noent.noblanks }
    @batch_id     = @doc.xpath('//bat:batchState/bat:batchID')[0].child.text
    @obj_count    = @doc.xpath('//bat:batchState/bat:jobStates').length
  end

  def render_upload_error(exobj)
    raise unless exobj.respond_to?(:response)

    @doc = Nokogiri::XML(exobj.response) { |config| config.strict.noent.noblanks }
    @description = "ingest: #{@doc.xpath('//exc:statusDescription')[0].child.text}"
    @error       = "ingest: #{@doc.xpath('//exc:error')[0].child.text}"
    render action: 'upload_error'
  end
end
