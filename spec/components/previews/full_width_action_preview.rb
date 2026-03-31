# frozen_string_literal: true

class FullWidthActionPreview < Lookbook::Preview
  # @label Blue
  def blue
    render Components::FullWidthAction.new(
      title: "Get started with PlaceCal",
      link_text: "Find out more",
      link_url: "/get-in-touch",
      color: "blue"
    ) { "Connect your community with a shared calendar that everyone can use." }
  end

  # @label Cream
  def cream
    render Components::FullWidthAction.new(
      title: "For community groups",
      link_text: "Learn more",
      link_url: "/community-groups",
      color: "cream"
    ) { "Already running events? Add your calendar to PlaceCal in minutes." }
  end

  # @label Green
  def green
    render Components::FullWidthAction.new(
      title: "For local authorities",
      link_text: "Get in touch",
      link_url: "/get-in-touch",
      color: "green"
    ) { "PlaceCal helps you connect residents with what is happening locally." }
  end

  # @label Red
  def red
    render Components::FullWidthAction.new(
      title: "For housing providers",
      link_text: "See how it works",
      link_url: "/housing-providers",
      color: "red"
    ) { "Help your tenants find community events and services near them." }
  end
end
