module IngestMixin
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def ingest_params_from(params, current_user)
    {
      'creator'               => params[:creator],
      'date'                  => params[:date],
      'digestType'            => params[:digestType],
      'digestValue'           => params[:digestValue],
      'file'                  => params[:file].tempfile,
      'filename'              => (params[:filename] || params[:file].original_filename),
      'localIdentifier'       => params[:localIdentifier],
      'notification'          => params[:notification],
      'notificationFormat'    => params[:notificationFormat],
      'primaryIdentifier'     => params[:primaryIdentifier],
      'profile'               => params[:profile],
      'note'                  => params[:note],
      'responseForm'          => params[:responseForm],
      'DataCite.resourceType' => params['DataCite.resourceType'],
      'DC.contributor'        => params['DC.contributor'],
      'DC.coverage'           => params['DC.coverage'],
      'DC.creator'            => params['DC.creator'],
      'DC.date'               => params['DC.date'],
      'DC.description'        => params['DC.description'],
      'DC.format'             => params['DC.format'],
      'DC.identifier'         => params['DC.identifier'],
      'DC.language'           => params['DC.language'],
      'DC.publisher'          => params['DC.publisher'],
      'DC.relation'           => params['DC.relation'],
      'DC.rights'             => params['DC.rights'],
      'DC.source'             => params['DC.source'],
      'DC.subject'            => params['DC.subject'],
      'DC.title'              => params['DC.title'],
      'DC.type'               => params['DC.type'],
      'submitter'             => (params['submitter'] || "#{current_user.login}/#{current_user.displayname}"),
      'title'                 => params[:title],
      'synchronousMode'       => params[:synchronousMode],
      'retainTargetURL'       => params[:retainTargetURL],
      'type'                  => params[:type]
    }.reject { |_k, v| v.blank? }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def update_params_from(params, current_user)
    {
      'creator'               => params[:creator],
      'date'                  => params[:date],
      'digestType'            => params[:digestType],
      'digestValue'           => params[:digestValue],
      'file'                  => params[:file].tempfile,
      'filename'              => (params[:filename] || params[:file].original_filename),
      'localIdentifier'       => params[:localIdentifier],
      'notification'          => params[:notification],
      'notificationFormat'    => params[:notificationFormat],
      'primaryIdentifier'     => params[:primaryIdentifier],
      'profile'               => params[:profile],
      'note'                  => params[:note],
      'responseForm'          => params[:responseForm],
      'DataCite.resourceType' => params['DataCite.resourceType'],
      'DC.contributor'        => params['DC.contributor'],
      'DC.coverage'           => params['DC.coverage'],
      'DC.creator'            => params['DC.creator'],
      'DC.date'               => params['DC.date'],
      'DC.description'        => params['DC.description'],
      'DC.format'             => params['DC.format'],
      'DC.identifier'         => params['DC.identifier'],
      'DC.language'           => params['DC.language'],
      'DC.publisher'          => params['DC.publisher'],
      'DC.relation'           => params['DC.relation'],
      'DC.rights'             => params['DC.rights'],
      'DC.source'             => params['DC.source'],
      'DC.subject'            => params['DC.subject'],
      'DC.title'              => params['DC.title'],
      'DC.type'               => params['DC.type'],
      'submitter'             => "#{current_user.login}/#{current_user.displayname}",
      'title'                 => params[:title],
      'synchronousMode'       => params[:synchronousMode],
      'retainTargetURL'       => params[:retainTargetURL],
      'type'                  => params[:type]
    }.reject { |_k, v| v.blank? }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def upload_params_from(params, current_user, current_group)
    {
      'file'              => params[:file].tempfile,
      'type'              => params[:object_type],
      'submitter'         => "#{current_user.login}/#{current_user.displayname}",
      'filename'          => params[:file].original_filename,
      'profile'           => current_group.submission_profile,
      'creator'           => params[:author],
      'title'             => params[:title],
      'primaryIdentifier' => params[:primary_id],
      'date'              => params[:date],
      'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
      'responseForm' => 'xml'
    }.reject { |_key, value| value.blank? }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

end
