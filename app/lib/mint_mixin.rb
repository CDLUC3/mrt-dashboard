module MintMixin
  def mint_params_from(params)
    {
      'profile' => params[:profile],
      'erc' => params[:erc],
      'file' => Tempfile.new('restclientbug'),
      'responseForm' => params[:responseForm]
    }.reject { |_k, v| v.blank? }
  end
end
