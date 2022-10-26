require './config/environment'
require 'nokogiri'

#html = File.open('outsavvy-sapho-events.html').read
# puts html

#html_file = StringIO.new(html)

#rdf = JSON::LD::API.toRdf(html_file, extractAllScripts: true)
# puts rdf

#File.open('outsavvy-sapho-events.html') do |file|
#  body = Nokogiri::HTML(file)
#  output = JSON::LD::API.load_html(body, url: 'https://www.outsavvy.com/organiser/sappho-events')
#  puts output
#end


#output = JSON::LD::API.frame('outsavvy-sapho-events.html', 'https://www.outsavvy.com/organiser/sappho-events')
#puts output

class OutSavvyEvent
  attr_reader :context
  attr_reader :full_type

  attr_reader :name
  attr_reader :uid
  attr_reader :starts_at
  attr_reader :ends_at
  attr_reader :url
  attr_reader :summary
  attr_reader :description
  attr_reader :location

  def self.is_event_data?(data)
    return unless data.present?
    return unless data['@context'].to_s == 'http://schema.org'
    data['@type'] == 'Event' || data['@type'] == 'VisualArtsEvent'
  end

  def initialize(event_hash)
    event_hash.each do |key, value|
    case key 
      when '@type'
        @full_type = value.first

      when 'http://schema.org/description'
        @description = value.first['@value']

      when 'http://schema.org/endDate'
        @ends_at = value.first['@value']

      when 'http://schema.org/startDate'
        @starts_at = value.first['@value']

      when 'http://schema.org/name'
        @name = value.first['@value']

      when 'http://schema.org/url'
        @url = value.first['@id']
        @uid = @url

      when 'http://schema.org/location'
        # TODO
        location = value.first
        address = location['http://schema.org/address'].first

        street_address = address['http://schema.org/streetAddress']

        @location = street_address.first['@value']
      end
    end
  end

  def type
    @full_type.split('/').last
  end

  def to_s
    # "<event: type='#{@type}'  description='#{@description}'  name='#{@name}'  >"
    "<event: type='#{type}'  description='...'  name='#{name}'  start_date='#{starts_at}'  end_date='#{ends_at}'  uid='#{uid}'  url='#{url}'  location='#{@location}'>"
  end
end

# lets try it without the "helpful" gem
File.open('outsavvy-sapho-events.html') do |file|
  doc = Nokogiri::HTML(file)

  data_nodes = doc.xpath('//script[@type="application/ld+json"]')

  event_data = data_nodes.reduce([]) do |events, node| 
    data = JSON.parse(node.inner_html)

    new_events = if data.is_a?(Hash)
      [data]

    elsif data.is_a?(Array)
      data

    else
      [nil]
    end

    events.concat new_events
  end
  
  events = JSON::LD::API
    .expand(event_data)
    .keep_if { |event_hash| OutSavvyEvent.is_event_data?(event_hash) }
    .map { |event_hash| OutSavvyEvent.new(event_hash) }
  
  events.each do |event|
    puts event
  end
end



__END__

# lets try it without the "helpful" gem
File.open('outsavvy-sapho-events.html') do |file|
  doc = Nokogiri::HTML(file)

  data_nodes = doc.xpath('//script[@type="application/ld+json"]')
  data_nodes.each do |node|
    puts "-" * 80
    data = JSON.parse(node.inner_html)

    
    # extraction may need to be recursive?
    if data.is_a?(Hash)
      # puts data.class.name
      event = RdfEvent.new(data)
      puts event

    elsif data.is_a?(Array)
      data.each do |sub_data|
        # puts sub_data.class.name
        # event extract
        event = RdfEvent.new(sub_data)
        puts event
      end

    else
      puts "Unrecognised RDF type '#{data.class.name}'"
    end

    # event = RdfEvent.new(data)
    # next unless event.is_event?
    # puts event
  end
end

JSON::LD::API.expand(events)


class OutSavvyEvent
  attr_reader :context
  attr_reader :type

  attr_reader :name
  attr_reader :starts_at
  attr_reader :ends_at
  attr_reader :url
  attr_reader :summary
  attr_reader :description
  attr_reader :location

  def initialize(data_payload)
    @data = data_payload
    @context = @data['@context'].to_s
    @type = @data['@type'].to_s
    @name = @data['name']
    @uid = @data['url']
    @publisher_url = @data['url']
    @start_date = @data['startDate']
    @end_date = @data['endDate']
  end

  def is_event?
    return false if @context != 'http://schema.org'

    @type == 'Event' || @type == 'VisualArtsEvent'
  end

  def to_s
    "<event: type='#{@type}' name='#{@data['name']}'>"
  end
end

class ValueContainer
  attr_reader :type
  attr_reader :name
  attr_reader :value

  
  def initialize(key, value)

  end
end

def extract_value(input)
  if input.is_a?(Array)
    input.each do |part|
      extract_value part
    end
    return
  end

  if input.is_a?(Hash)
    input.each do |key, value|
      # something to do with the key
      extract_value value
    end
  end
end