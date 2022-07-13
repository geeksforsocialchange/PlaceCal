module EmailHelper

  def last_email_delivered
    ActionMailer::Base.deliveries.last
  end

  def extract_link_from(email)
    puts '----'
    email.parts.each do |part|
      puts "bbbbb"
      puts part.body
    end

    body_text = email.text_part.body # body.parts
    puts body_text


    body_text =~ /^(https?:\/\/.*)$/ && $1
  end
end
