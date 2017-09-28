FactoryGirl.define do
  factory(:calendar) do
    name 'Zion Centre'
    source ''
    notices nil
    strategy 'place'
    type 'outlook'
    last_import_at '2017-09-27T14:38Z'
  end
end