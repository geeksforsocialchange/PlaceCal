# frozen_string_literal: true

class Components::ContainerWithHeader < Components::Base
  prop :title, String
  prop :color, String

  def view_template(&)
    div(class: 'container-with-header') do
      div(class: "container-with-header__head container-with-header__head--#{@color}") do
        h3(class: 'container-with-header__title') { @title }
      end
      div(class: 'container-with-header__body', &)
    end
  end
end
