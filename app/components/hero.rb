# frozen_string_literal: true

class Components::Hero < Components::Base
  prop :title, String, :positional
  prop :subtitle, _Nilable(String), :positional, default: ''
  prop :schema, _Nilable(String), :positional, default: nil

  def after_initialize
    @title = clean_title(@title)
  end

  def view_template
    div(class: 'pc-hero bg-base-primary text-center pt-8 pb-4 [&_br]:hidden tp:[&_br]:block') do
      div(class: 'c') do
        if @subtitle
          h4(class: 'allcaps inline-block mt-2 mb-6 leading-[1.2] max-tp:max-w-[14rem]') { @subtitle }
          div(role: 'presentation', class: 'mx-auto w-[4.5rem] border-b-4 border-base-background')
        end
        if @schema
          h1(property: @schema, class: 'mt-5 text-center') { safe(@title) }
        else
          h1(class: 'mt-5 text-center') { safe(@title) }
        end
      end
    end
  end

  private

  def clean_title(title)
    if title.length > 32
      title.split.in_groups(2, false).map { |g| g.join(' ') }.join('<br> ')
    else
      title
    end
  end
end
