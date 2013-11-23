#!/usr/bin/env st-livescript
require! fs
{meta} = require \./src/meta.ls

base_url = 'http://api.ly.g0v.tw'
version  = \v0
collections = \collections
base_path = "/#{version}/#{collections}/"
uri = "#{base_url}/#{base_path}"

sample =
  'ivod':
    chinese: '影片'
    desc: "ivod為立法院的議事轉播公開影片，每一個entry包含影片的錄製時間、影片種類、原始連結、縮圖等資訊。\n資料來源:立法院議事轉播 http://ivod.ly.gov.tw/"
  'calendar':
    chinese: '行程'
    desc: "立法院最新的公開行程\n資料來源: http://www.ly.gov.tw/01_lyinfo/0101_lynews/lynewsList.action"
    q: ['{"type":"hearing"}']
  'motions':
    chinese: '議案/公報'
    desc: "立法院將議事的紀錄撰寫成公報，供所有公民檢閱。\n資料來源: http://misq.ly.gov.tw + http://npl.ly.gov.tw"
    q: ['{"bill_id":"1011011071000200"}','{"type":"hearing"}']
  'bills':
    chinese: '提案'
    desc: "立法院黨團、委員、政府提出的提案，可能是法律案、預算案、其他案、宣戰案...等。\n資料來源: http://misq.ly.gov.tw + http://npl.ly.gov.tw"
    bill_id: '1021021070200400'
    bill_ref: '1150L15359'
  'sittings':
    chinese: '會議'
    desc: "立法院以會期為單位舉辦每個會議，一次會議可能會分多天進行，此 api 包含該次會議的所有相關資訊，如議程、相關影像等。"
    id: '08-04-YS-06'
  'amendments':
    chinese: '法律提案資訊'
    desc: '提供國會圖書館裡頭的法律提案資訊，可在提案(bills)中查找此類資訊'
  'laws':
    chinese: '法律資訊'
    desc: '提供國會圖書館上的法律名稱及代號'
  'ttsmotions':
    chinese: '議案進度'
    desc: '提供了國會圖書館上的議案進度資料 (ttsmotions collections)'
  'ttsinterpellation':
    chinese: '議案進度'
    desc: '提供了國會圖書館上的質詢資料'

# header
output = """
FORMAT: X-1A
HOST: #{base_url}

# TW ly api #{version}
online test of [beta API](http://api.ly.g0v.tw)
This is beta version of api.ly.g0v.tw. Written in [apiblueprint](http://apiblueprint.org/) by [Markdown](http://daringfireball.net/projects/markdown/syntax) syntax.
Every API have following attributes:

+ paging (Object)
    + count (integer) ... Total number of entries
    + l (integer) ... Number of entries list in entries.
    + sk (integer) ... Start offset of entries. Start from 0
        + Sample Page 1: #{base_url}/v0/collections/calendar?l=10&sk=0
        + Sample Page 2: #{base_url}/v0/collections/calendar?l=10&sk=10
        + Sample Page 3: #{base_url}/v0/collections/calendar?l=10&sk=20

+ entries (Array)
    + Every entry have it's own attributes, see following list and example.

Every API can pass json object as query to filter result

+ query sample:
    + Filter field "proposed_by" in someone's name of bills: {"proposed_by":{"$matches":"someone's name"}}
        + Sample URI: http://api.ly.g0v.tw/v0/collections/bills?q={%22proposed_by%22:{%22$matches%22:%22%E4%BA%BA%22}}
    + Filter field "summary" in keyword of sittings:
        + Sample URI: http://api.ly.g0v.tw/v0/collections/sittings?q={%22summary%22:{%22$matches%22:%22%E5%81%A5%E4%BF%9D%22}}

##### Retrieve an API [GET]
\n\n
"""

# version and collections summary
output += doc_section('Version', 'Show specific version of API.' {'uri': "/#{version}/"});
output += doc_section('Collections', 'List all avaible collection of current version.', {'uri': base_path});

for collection of meta
  c = meta[collection]
  o = ''
  collection = collection - 'pgrest.'
  s = sample[collection]

  # listing only
  group_desc = '+ This is the api group of '+collection+" (#{s.chinese})"+"\n"
  if(s.desc?)
    group_desc += '+ '+s.desc+"\n"
  if(s.q?)
    sample_url = base_url+base_path+collection+'?q='+s.q[0]
  else
    sample_url = null
  o += doc_section('Group '+collection, group_desc)
  o += doc_section(collection, null, {'uri': base_path+collection+'/', 'sample_url': sample_url}, null, 2)

  if(c.primary?)
    #have sub query
    if(typeof c.primary == 'function')
      # special case for bill_id
      id = 'bill_id'
    else
      id = c.primary
    if(s[id]?)
      sample_url = base_url+base_path+collection+"/#{s[id]}/"
    o += doc_section(collection+'.entries', null, {'uri': base_path+collection+"/{#{id}}/", 'sample_url':sample_url, 'sample':s}, null, 3)
    for column of c.columns ? {} when column isnt '*'
      if(s[id]?)
        sample_url = base_url+base_path+collection+"/#{s[id]}/#{column}"
      o += doc_section(collection+'.entries.'+column, null, {'uri': base_path+collection+"/{#{id}}/#{column}", 'sample_url':sample_url, 'sample':s}, null, 4)
  output += o

fs.writeFile('apiary.apib', output)
console.log(output)


function doc_section(title, desc = null, req = {}, res = {}, level = 1)
  sharp = '#' * level
  o = []

  o.push if req.uri? => "#sharp GET #{req.uri}" else "#sharp #title"
  if(desc?)
    o.push(desc)
  else if(req?)
    if(req.sample_url?)
      o.push("Example: #{sample_url}");
    else
      o.push("Example: #{base_url}#{req.uri}");
  o.push doc_section_res res if req.uri?
  o.push ''
  return o * "\n"

function doc_section_res({content_type,example})
  content_type ?= 'application/json'
  o = ["+ Response 200 (#content_type)"]
  o.push "\n\t#{example}\n" if example?
  o.push ''
  return o * "\n"

