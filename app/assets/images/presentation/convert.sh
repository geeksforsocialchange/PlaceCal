#!/bin/sh
convert -resize 600 ./_source/*.png ./mobile/std.png
convert -resize 1200 ./_source/*.png ./mobile/ret.png

convert -resize 900 ./_source/*.png ./tablet/std.png
convert -resize 1800 ./_source/*.png ./tablet/ret.png

convert -resize 1130 ./_source/*.png ./desktop/std.png
convert -resize 2260 ./_source/*.png ./desktop/ret.png