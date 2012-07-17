class DuaMailer < ActionMailer::Base

  default :from => APP_CONFIG['dua_email_from']

  def dua_email(dua_hsh, hsh)
    debugger
    @hsh = {'body' => ''}.merge(hsh)
     mail( :to            => "#{@hsh['to_email']}",
           :subject       => "Merritt DUA acceptance: " + dua_hsh['Title'],
           :reply_to      => dua_hsh["Notification"])
  end
end
