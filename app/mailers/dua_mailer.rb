class DuaMailer < ActionMailer::Base
  default from: APP_CONFIG['dua_email_from']

  #:nocov:
  def dua_email(args)
    @to, @title, @name, @affiliation, @collection, @object, @terms = 
      args[:to], args[:title], args[:name], args[:affiliation], args[:collection], args[:object], args[:terms]
    mail(to: args[:to],
         cc: args[:cc],
         subject: "Merritt DUA acceptance: #{args[:title]}",
         reply_to: args[:reply_to])
  end
  #:nocov:
end
