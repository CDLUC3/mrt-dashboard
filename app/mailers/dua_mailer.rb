class DuaMailer < ActionMailer::Base
  default from: APP_CONFIG['dua_email_from']

  # :nocov:
  def dua_email(args)
    @to = args[:to]
    @title = args[:title]
    @name = args[:name]
    @affiliation = args[:affiliation]
    @collection = args[:collection]
    @object = args[:object]
    @terms = args[:terms]
    mail(to: @to, cc: args[:cc], subject: "Merritt DUA acceptance: #{@title}", reply_to: args[:reply_to])
  end
  # :nocov:
end
