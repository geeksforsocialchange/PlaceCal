class JoinMailer < ApplicationMailer
  def join_mailer
    @from = params[:email]
    @name = params[:name]
    mail(to: 'support@placecal.org', subject: "Enquiry from #{@name}"]
  end
end
