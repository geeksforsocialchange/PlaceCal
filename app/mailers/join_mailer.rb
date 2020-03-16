class JoinMailer < ApplicationMailer

  def join_us(join)
    @join = join

    mail(to: 'support@placecal.org', subject: 'New Join Request')
  end
end
