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

class RdfEvent
  attr_reader :context
  attr_reader :type

  attr_reader :name
  attr_reader :starts_at
  attr_reader :ends_at
  attr_reader :url
  attr_reader :summary
  attr_reader :description
  
  def initialize(data_payload)
    @data = data_payload
    @context = @data['@context'].to_s
    @type = @data['@type'].to_s
  end

  def is_event?
    return false if @context != 'http://schema.org'

    @type == 'Event' || @type == 'VisualArtsEvent'
  end

  def to_s
    "<event: type='#{@type}' name='#{@data['name']}'>"
  end
end

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