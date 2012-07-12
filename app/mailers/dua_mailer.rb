class DuaMailer < ActionMailer::Base

  default :from => APP_CONFIG['feedback_email_from']

  def feedback_email(from, hsh)
    @from = from
    @hsh = {'title' => '', 'name' => '', 'body' => ''}.merge(hsh)
     mail( :to            => "#{@hsh['to_email']}",
           :subject       => "#{@hsh['title']}",
           :from          => @from)
  end
end
