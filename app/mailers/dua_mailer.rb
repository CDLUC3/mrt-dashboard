class ContactMailer < ActionMailer::Base

  default :from => APP_CONFIG['feedback_email_from']

  def feedback_email(from, hsh)
    @from = from
    @hsh = {'question_about' => '', 'name' => '', 'body' => ''}.merge(hsh)
    #the hash hsh could have 'question_about', 'name', 'body'
    mail( :to             => "#{@hsh['to_email']}",
          :subject        => "DUA #{@hsh['name']}",
          :from           => @from)
  end
end
