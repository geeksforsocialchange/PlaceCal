# frozen_string_literal: true

class Views::Pages::Privacy < Views::Base
  def view_template
    content_for(:title) { 'Privacy Policy' }

    article(class: 'home margin') do
      render Components::Hero.new('PlaceCal Privacy Policy')

      div(class: 'card card--plain') do
        div(class: 'max_width') do
          br
          render_intro
          render_contact_details
          render_personal_information
          render_data_rights
          render_complaints
          render_web_tracking
          render_consent
          br
        end
      end
    end
  end

  private

  def render_intro
    p do
      plain 'At PlaceCal.org, one of our main priorities is the privacy of our visitors. This Privacy Policy document contains types of information that is collected and recorded by PlaceCal.org and how we use it.'
    end
    p do
      plain 'If you have additional questions or require more information about our Privacy Policy, do not hesitate to contact us through email at '
      plain t('contact.email')
      plain '.'
    end

    p { 'One of our main priorities is the privacy of our visitors. This Privacy Policy document contains the types of information that are collected and recorded by placecal.org and placecal-staging.org, and how we use it.' }
    p { 'If you have additional questions or require more information about our Privacy Policy, do not hesitate to contact us.' }
  end

  def render_contact_details
    h3 { 'Our Contact Details' }
    p { "Name: #{t('colophon.copyright')}" }
    p { "Address: #{t('colophon.address')}" }
    p do
      plain 'Email: '
      a(href: "mailto:#{t('contact.email')}") { t('contact.email') }
    end
  end

  def render_personal_information # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    h3 { 'Personal Information' }
    h4 { 'The type of personal information we collect' }
    p { "We currently collect and process the following information from organisations who sign-up to use PlaceCal's services, and any individuals who represent them:" }
    ul do
      li { 'Personal identifiers, contacts and characteristics (for example, name and contact details)' }
      li { 'Email addresses for organisations which may belong to identifiable individuals' }
      li { 'Phone numbers for organisations which may belong to identifiable individuals' }
      li { 'Addresses for organisations which may belong to identifiable individuals' }
      li { 'Addresses for events which may belong to identifiable individuals' }
    end
    p { 'We do not collect personal information from users who are browsing a PlaceCal site without an account.' }

    h4 { 'How we get the personal information and why we have it' }
    p { 'Most of the personal information we process is provided to us directly by you for the purpose of creating and hosting events on the PlaceCal platform.' }
    p { 'We use the information that you have given us in order to share this information with those browsing the site and viewing organisations and their calendars.' }
    p { 'Under the UK General Data Protection Regulation (UK GDPR), the lawful basis we rely on for processing this information is your consent.' }
    p { 'You are able to remove your consent at any time. You can do this by contacting support@placecal.org' }

    h4 { 'How we store your personal information' }
    p { 'Your information is securely stored on our server in London, UK.' }
    p do
      plain 'We keep personal identifiers, contacts and characteristics (as described in the "Type of information we collect" section above) for as long as this information is relevant – meaning as long as a partner, user or calendar this information is associated with is active. '
      plain "'Active' in this sense refers to being a live account which can be logged into by the user, a partner with an associated calendar, or a linked calendar with a working source."
    end
    p do
      plain 'When a user requests to delete their account we will remove all personal identifying information ' \
            "associated with that user account. This does not automatically remove that same individual's " \
            "information from partners and calendars. For a user's information to be removed from a partner or " \
            'calendar, or for a partner or calendar that user manages to be deleted, this needs to be specified. ' \
            'Once a user account is deleted their information will be removed from PlaceCal and no longer be ' \
            'accessible by any user or staff.'
    end
    p { 'Copies of this data may be created by employees and registered volunteers of GFSC Community Interest Company solely for development purposes. This information is destroyed when employees leave the company or volunteer agreements end.' }
  end

  def render_data_rights # rubocop:disable Metrics/AbcSize
    h4 { 'Your data protection rights' }
    p { 'Under data protection law, you have rights including:' }
    # rubocop:disable Rails/OutputSafety
    p { raw(safe('<strong>Your right of access</strong> - You have the right to ask us for copies of your personal information.')) }
    p { raw(safe('<strong>Your right to rectification</strong> - You have the right to ask us to rectify personal information you think is inaccurate. You also have the right to ask us to complete information you think is incomplete.')) }
    p { raw(safe('<strong>Your right to erasure</strong> - You have the right to ask us to erase your personal information in certain circumstances.')) }
    p { raw(safe('<strong>Your right to restriction of processing</strong> - You have the right to ask us to restrict the processing of your personal information in certain circumstances.')) }
    p { raw(safe('<strong>Your right to data portability</strong> - You have the right to ask that we transfer the personal information you gave us to another organisation, or to you, in certain circumstances.')) }
    # rubocop:enable Rails/OutputSafety
    p { 'You are not required to pay any charge for exercising your rights. If you make a request, we have one month to respond to you.' }
    p do
      plain 'Please contact us at '
      a(href: "mailto:#{t('contact.email')}") { t('contact.email') }
      plain ' if you wish to make a request.'
    end
  end

  def render_complaints
    h4 { 'How to complain' }
    p { 'If you have any concerns about our use of your personal information, you can make a complaint to us at support@placecal.org' }
    p { 'You can also complain to the ICO if you are unhappy with how we have used your data.' }
    p { "The ICO's address:" }
    address do
      plain "Information Commissioner's Office"
      br
      plain 'Wycliffe House'
      br
      plain 'Water Lane'
      br
      plain 'Wilmslow'
      br
      plain 'Cheshire'
      br
      plain 'SK9 5AF'
      br
    end
    p do
      plain 'Helpline number: '
      a(href: 'tel:0303-123-1113') { '0303 123 1113' }
    end
    p do
      plain 'ICO website: '
      a(href: 'https://www.ico.org.uk', target: '_blank') { 'https://www.ico.org.uk' }
    end
  end

  def render_web_tracking
    h3 { 'Web Tracking' }
    h4 { 'Log Files' }
    p do
      plain "PlaceCal.org's hosting server follows a standard procedure of using log files. These files log visitors when they visit websites. All hosting companies do this as a part of hosting services' analytics. The information collected by log files include internet protocol (IP) addresses, browser type, Internet Service Provider (ISP), date and time stamp. These are not linked to any information that is personally identifiable."
    end
    p { 'PlaceCal uses an error logging service called [Appsignal](https://www.appsignal.com/). This service logs errors that may occur while you are browsing the site. These are not linked to any information that is personally identifiable. The purpose of these logs is to ensure the security and operation of the website is as expected and alert us when it is not.' }

    h4 { 'Cookies, Web Beacons, Analytics Data and Third Party Privacy Policies' }
    p { "PlaceCal doesn't store first party cookies." }
    p { "PlaceCal uses a third party service called Plausible which allows us to track site visits. You can consult Plausible's Privacy Policy here: " }
  end

  def render_consent
    h3 { 'Consent' }
    p do
      plain 'By using our website, you hereby consent to our Privacy Policy and agree to its '
      link_to 'Terms and Conditions', terms_of_use_url
      plain '.'
    end
  end
end
