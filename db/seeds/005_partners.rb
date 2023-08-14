# frozen_string_literal: true

module SeedPartners
  LONG_TEXT = <<-LOREM_IPSUM
  Nullam in tristique orci. Mauris congue ex eget varius pretium. Quisque at posuere
  lorem. Vestibulum mauris justo, vestibulum non laoreet varius, vehicula varius dui.
  Donec suscipit sapien nulla, eu imperdiet lorem porttitor in. Nullam aliquet magna
  scelerisque ipsum gravida feugiat. Pellentesque consectetur massa eget vulputate
  consectetur. Sed at venenatis metus. Praesent eleifend turpis interdum massa varius
  vehicula. Suspendisse potenti. Nullam vel malesuada sapien.

  Nam et lobortis risus. Quisque nec magna dolor. Mauris congue, metus et laoreet
  fermentum, nisl dolor vestibulum quam, et convallis justo orci eu mi. Proin
  condimentum ligula nec fringilla tempor. Morbi bibendum nec leo at pretium. Vivamus
  feugiat mi a mi facilisis, vel auctor ligula pretium. Mauris efficitur, ante non
  blandit sagittis, odio diam ornare velit, sit amet fringilla tortor est id dui.

  Donec imperdiet sem quis molestie dictum. Aliquam nec metus nec magna imperdiet
  congue. Nulla dui enim, sodales in lacinia a, elementum nec risus. In pellentesque
  mauris a ex dapibus volutpat. Nam feugiat massa et est maximus, at convallis est
  sollicitudin. Cras finibus vitae leo sit amet mattis. Morbi ullamcorper, est vitae
  pellentesque egestas, urna turpis porttitor nulla, gravida volutpat metus mauris
  quis dui. Aliquam pretium nec arcu nec vehicula. Nullam tincidunt tellus ullamcorper
  facilisis scelerisque. Nam dolor leo, interdum vitae feugiat tempus, accumsan sed
  felis. Vivamus dui tellus, eleifend quis mattis sed, ornare at libero.
  LOREM_IPSUM

  def self.run
    $stdout.puts 'Partners'

    partner = Partner.new(
      name: 'Sample Partner',
      summary: 'The summary of Sample Partner',
      description: LONG_TEXT
    )

    neighbourhood = Neighbourhood.last
    partner.service_area_neighbourhoods << neighbourhood

    partner.save!
  end
end

SeedPartners.run
