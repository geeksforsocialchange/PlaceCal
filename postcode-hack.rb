
bad_postcodes = ["EC1V2NX","M15","WC2N6HH","N193RQ","N19DN","N78TQ","KT12PT","SW40JL","W1W7LT","WC1N3XX","OL161AB","M40MOSTON","EX46NA","SM11EA","W1J7NF","UK","W1D6AQ","SW192HR","CR43UD","SW197NB","TW13AA","M114UA","N19JP","UB79JL","SM51JJ","M144SQ","UB82DE","W139LA","UB83PH","M16","M144"]

path = '/home/ivan/Downloads/geo-data/Data/NSPL_MAY_2022_UK.csv'

bad_postcodes.each do |bpc|
  out = `grep #{bpc} #{path}`

  next if out.lengt

  puts bpc
end
