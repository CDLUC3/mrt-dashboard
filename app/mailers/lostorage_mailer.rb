class LostorageMailer < ActionMailer::Base

  default :from       => APP_CONFIG['lostorage_email_from']
  default :reply_to   => APP_CONFIG['lostorage_email_from']

  def lostorage_email(hsh)
    @hsh = {'body' => ''}.merge(hsh)
     mail( :to            => "#{@hsh['to_email']}",
           :subject       => "Merritt #{@hsh['container_type'].capitalize} File Processing Completed ")
  end
end
