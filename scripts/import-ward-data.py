#!/usr/bin/env python3
import csv
import json

indata = []
outdata = {}

with open('Ward_to_Local_Authority_District_to_County_to_Region_to_Country_(December_2019)_Lookup_in_United_Kingdom.csv', 'r') as h:
     r = csv.reader(h)
     for row in r:
         indata.append(dict(zip(('FID',
                                 'WD19CD',
                                 'WD19NM',
                                 'LAD19CD',
                                 'LAD19NM',
                                 'CTY19CD',
                                 'CTY19NM',
                                 'RGN19CD',
                                 'RGN19NM',
                                 'CTRY19CD',
                                 'CTRY19NM'), row)))

# The first line of the table is literally just the keys that we already have right here ^
indata.pop(0)

# New target dataset looks like:
# {
#    'Scotland': {
#         'properties': { 'name': 'Scotland', 'code': 'E00000000' },
#         'children': {
#              'foo': {
#                   'properties': { ... },
#                   'children': { ... }
#              }
#         }
#    }
# }

def make_unit(parent, name, code, unit, unit_code_key):
     if not parent:
          parent = outdata
     else:
          parent = parent['children']

     if name not in parent:
          structure = {
               'properties': {
                    'name': name,
                    'code': code if len(code) > 0 else 'E99999999',
                    'unit': unit,
                    'unit_code_key': unit_code_key
               },
               'children': {}
          }
          parent[name] = structure

     return parent[name]



for i in indata:
     country_name = i['CTRY19NM']
     country_code = i['CTRY19CD']

     region_name = i['RGN19NM']
     region_code = i['RGN19CD']

     county_name = i['CTY19NM']
     county_code = i['CTY19CD']

     lad_name = i['LAD19NM']
     lad_code = i['LAD19CD']

     ward_name = i['WD19NM']
     ward_code = i['WD19CD']

     country = make_unit(None, country_name, country_code, 'country', 'CTRY19CD')
     region = make_unit(country, region_name, region_code, 'region', 'RGN19CD')
     county = make_unit(region, county_name, county_code, 'county', 'CTY19CD')
     lad = make_unit(county, lad_name, lad_code, 'district', 'LAD19CD')
     ward = make_unit(lad, ward_name, ward_code, 'ward', 'WD19CD')

outdata_json = json.dumps(outdata)
with open('location-lookup-data-v3.json', 'w') as h:
     h.write(outdata_json)
