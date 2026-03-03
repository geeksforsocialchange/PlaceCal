# frozen_string_literal: true

class Views::Pages::TermsOfUse < Views::Base
  def view_template
    content_for(:title) { 'Terms of Use' }

    article(class: 'home margin') do
      Hero('PlaceCal Terms of Use')

      div(class: 'card card--plain') do
        div(class: 'max_width') do
          br
          render_acceptance
          render_eligibility
          render_safety
          render_community_rules
          render_warranty
          render_entire_agreement
          br
        end
      end
    end
  end

  private

  def render_acceptance
    h3 { 'Acceptance of Terms of Use Agreement' }
    p { 'By using the PlaceCal website or by signing up for an account with PlaceCal (the "Service"), you agree to be bound by these Terms of Use and our Privacy Policy, which is incorporated by reference into this Agreement (the "Agreement"). If you do not accept and agree to be bound by all of the terms of this Agreement, please do not use the Service.' }
    p { 'If we update the "Agreement" for any reason, we will post the updated version on our website. We will also notify registered users via email. If you continue to use the Service after the changes become effective, then you agree to the revised Agreement.' }
  end

  def render_eligibility
    h3 { 'Eligibility' }
    p { 'You are not authorized to create an account or use the Service unless all of the following are true:' }
    ul do
      li { 'you are at least 18 years of age, or the age of majority in your country' }
      li { 'you can form a binding contract with PlaceCal' }
      li { 'you will comply with this Agreement and all applicable local, national and international laws, rules and regulations' }
    end
    p { 'PlaceCal may terminate your account and use of the Service at any time without notice if it believes that you have violated this Agreement.' }
  end

  def render_safety
    h3 { 'Safety' }
    p { 'PlaceCal is not responsible for the conduct of any member on or off of the Service. You agree to use caution in all interactions with other members, especially if you decide to communicate off the Service or meet in person, such as attending an event.' }
    # rubocop:disable Rails/OutputSafety
    p { raw(safe('<strong>You are solely responsible for your interactions with organisations and events. You understand that PlaceCal does not conduct background checks on users or otherwise inquire into the background of users. PlaceCal makes no representations or warranties as to the content or safety of events and organisations listed on its service.</strong>')) }
    # rubocop:enable Rails/OutputSafety
  end

  def render_community_rules # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    h3 { 'Community Rules' }
    # rubocop:disable Rails/OutputSafety
    p { raw(safe('<strong>PlaceCal is dedicated to providing an inclusive, kind, welcoming, and harassment-free experience for everyone using the platform or going to events listed on it. We do not tolerate harassment of partners or site users in any form.</strong>')) }
    # rubocop:enable Rails/OutputSafety
    p { 'These community rules apply both the PlaceCal platform and our adjacent platforms, including our Discord, emails and direct messages, both online and off. Anyone who violates the community rules may be sanctioned or expelled from these spaces at the discretion of the administrators.' }
    p { 'Prohibited topics for events on our platform, partner descriptions, and communication with the PlaceCal team include:' }
    ul do
      li { 'Offensive comments related to gender, gender identity and expression, sexual orientation, disability, mental illness, neuro(a)typicality, physical appearance, body size, race, immigration status, religion, or other identity marker. This includes anti-Indigenous/Nativeness and anti-Blackness.' }
      li { "Unwelcome comments regarding a person's lifestyle choices and practices, including those related to food, health, parenting, drugs, and employment." }
      li { 'Deliberate misgendering or use of "dead" or rejected names' }
      li { "Gratuitous or off-topic sexual images or behaviour in spaces where they're not appropriate" }
      li { 'Threats of violence or Incitement of violence towards any individual, including encouraging a person to commit suicide or to engage in self-harm' }
      li { 'Deliberate "outing" of any aspect of a person\'s identity without their consent except as necessary to protect vulnerable people from intentional abuse' }
      li { 'Microaggressions, which take the form of everyday jokes, put downs, and insults that spread humiliating feelings to people of marginalised groups' }
      li { 'Publication of non-harassing private information and communication' }
      li { 'Jokes that resemble the above, such as "hipster racism", still count as harassment even if meant satirically or ironically.' }
    end
    p do
      plain 'Although PlaceCal reserves the right to review and remove Content that violates this Agreement, such Content is the sole responsibility of the user who posts it, and PlaceCal cannot guarantee that all Content will comply with this Agreement. If you see Content on the Service that violates this Agreement, please report it by contacting us at '
      a(href: "mailto:#{t('contact.email')}") { t('contact.email') }
      plain '.'
    end
  end

  def render_warranty
    h3 { 'Warranty Disclaimers; Limitation of Liability' }
    p do
      plain 'The services are provided "as is" and without warranty of any kind. To the maximum extent ' \
            'permitted by law, The Company disclaims all representations and warranties, express or implied, ' \
            'relating to the services or any content on the services, whether provided or owned by The Company ' \
            'or by any third party, including without limitation warranties of merchantability, fitness for a ' \
            'particular purpose, title, non-infringement, freedom from computer virus, and any implied ' \
            'warranties arising from course of dealing, course of performance, or usage in trade, all of which ' \
            'are expressly disclaimed. In addition, you assume total responsibility and risk for your use of the ' \
            'services and The Company does not make any representation or warranty that any of the services or ' \
            'any content available through any of the services is accurate, complete, available, current, free ' \
            'of viruses or other harmful components or defects, or that the services will meet your ' \
            'requirements. No advice or information, whether oral or written, obtained by you from company ' \
            'shall create any warranty not expressly made herein.'
    end
    p do
      plain 'In no event whatsoever shall The Company, its affiliates, or suppliers, or their respective ' \
            'officers, employees, shareholders, agents, or representatives, be liable for any indirect, ' \
            'consequential, incidental, special, punitive or exemplary damages, or for any loss of profits or ' \
            'revenue, including but not limited to loss of sales, profit, revenue, goodwill, or downtime, ' \
            "(arising under tort, contract, or other law) regardless of such party's negligence or whether such " \
            'party knew or should have known of the possibility of such damages. You understand and agree that ' \
            'the download of any materials in connection with the services is done at your discretion and risk ' \
            'and that you will be solely responsible for any loss or damage to your computer system or loss of ' \
            'data that may result from the download or upload of any material. Company neither assumes, nor ' \
            'does it authorize any other person to assume on its behalf, any other liability in connection with ' \
            'the provision of the services. If, notwithstanding the other provisions of these terms, company is ' \
            'found to be liable to you for any damage or loss which arises out of or is in any way connected ' \
            "with your use of any services, company's liability shall in no event exceed the greater of (1) the " \
            'total of any fees paid by you to company in the six (6) months prior to the date the claim is ' \
            'asserted for any of the services or feature relevant to the claim, or (2) US $500.00. These ' \
            'disclaimers and limitations of liability are made to the fullest extent permitted by law.'
    end
    p { 'Some jurisdictions do not allow the exclusion or limitation of certain damages, so some or all of the exclusions and limitations in this section may not apply to you.' }
  end

  def render_entire_agreement
    h3 { 'Entire Agreement' }
    p do
      plain 'This Agreement, which includes the '
      link_to 'Privacy Policy', privacy_url
      plain ', contains the entire agreement between you and PlaceCal regarding the use of the Service. If any provision of this Agreement is held invalid, the remainder of this Agreement shall continue in full force and effect. The failure of The Company to exercise or enforce any right or provision of this Agreement shall not constitute a waiver of such right or provision.'
    end
  end
end
