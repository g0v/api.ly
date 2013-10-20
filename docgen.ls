base_url = 'http://api-beta.ly.g0v.tw'
version  = \v0
collections = \collections
base_path = "/#{version}/#{collections}/"
uri = "#{base_url}/#{base_path}"

# header
output = """
HOST: #{base_url}

--- TW ly api #{version} ---
---
This is beta version of api.ly.g0v.tw. Written in [apiblueprint](http://apiblueprint.org/) by [Markdown](http://daringfireball.net/projects/markdown/syntax) syntax.
---
"""

# versino and collections summary
req =
  'uri': "/#{version}/"
  'content_type': 'application/json'
res =
  'status': '200'
  'content_type': 'application/json'
output += doc_section_head('Version', 'Show specific version of API.');
output += doc_section_content('', req, res);
req =
  'uri': base_path
  'content_type': 'application/json'
res =
  'status': '200'
  'content_type': 'application/json'
output += doc_section_head('Collections', 'List all avaible collection of current version.');
output += doc_section_content('', req, res);

# meta define, TODO: need to seperate and require from other file
meta =
  'pgrest.ivod':
    as: 'public.ivod'
    columns:
      '*': <[sitting_id type speaker thumb firm time length video_url_n video_url_w wmvid youtube_id]>
  'pgrest.calendar':
    f: {-raw}
    s: {date: -1}
    as: 'public.calendar'
    $query: ad: $not: null
    columns:
      sitting_id: $literal: '_calendar_sitting_id(calendar)'
      '*': {}
  'pgrest.motions':
    s: {sitting_id: -1,motion_class: 1, agenda_item: 1}
    as: 'public.motions LEFT JOIN bills USING (bill_id)'
    columns:
      '*':
        motions: {}
        bills: <[bill_ref summary proposed_by]>
      'doc': type: \json
  'pgrest.bills':
    s: {bill_id: -1}
    f: {data: -1}
    as: 'bills'
    primary: (id) ->
      $or:
        bill_ref: id
        bill_id: id
    columns:
      '*': <[bill_id bill_ref summary proposed_by sponsors cosponsors abstract]>
      data: type: \json
      doc: type: \json
      motions:
        $from: 'public.motions'
        $query: 'bill_id': $literal: 'bills.bill_id'
        $order: {sitting_id: 1}
        columns:
          '*': <[sitting_id ]>
  'pgrest.sittings':
    s: {id: -1}
    f: {-videos}
    as: 'public.sittings'
    primary: \id
    columns:
      '*': {}
      dates:
        $from: 'pgrest.calendar'
        $query: 'sitting_id': $literal: 'sittings.id'
        $order: {id: 1}
        columns:
          'calendar_id': field: 'calendar.id'
          '*': <[chair date time_start time_end]>
      videos:
        $from: 'pgrest.ivod'
        $query: 'sitting_id': $literal: 'sittings.id'
        columns:
          '*': {}
      motions:
        $from: 'pgrest.motions'
        $query: 'sitting_id': $literal: 'sittings.id'
        $order: {motion_class: 1, agenda_item: 1}
        columns:
          '*': <[motion_class agenda_item subitem item bill_id bill_ref proposed_by summary doc]>

for collection of meta
  c = meta[collection]
  o = ''
  collection = collection - 'pgrest.'

  # listing only
  o += doc_section_head(collection)
  req =
    'uri': base_path+collection+'/'
    'content_type': 'application/json'
  res =
    'status': '200'
    'content_type': 'application/json'
  o += doc_section_content('', req, res)

  if(c.primary?)
    #have sub query
    if(typeof c.primary == 'function')
      # special case for bill_id
      id = 'bill_id'
    else
      id = c.primary
    req =
      'uri': base_path+collection+"/{#{id}}/"
      'content_type': 'application/json'
    res =
      'status': '200'
      'content_type': 'application/json'
    o += doc_section_head(collection+'.entries');
    o += doc_section_content('', req, res);
    if(c.columns?)
      for column of c.columns
        if(column != '*')
          req =
            'uri': base_path+collection+"/{#{id}}/#{column}"
            'content_type': 'application/json'
          res =
            'status': '200'
            'content_type': 'application/json'
          o += doc_section_head(collection+".entries.#{column}");
          o += doc_section_content('', req, res);
  output += o

console.log output

function doc_section_head(title, desc)
  o = '--'+"\n"+title+"\n"
  if(desc?)
    o += desc+"\n"
  o += '--'+"\n"
  return o

function doc_section_content(desc, req, res)
  #request
  o = ''
  if(desc?)
    o += desc
  if(req.uri?)
    o = "GET #{req.uri}\n"
  if(req.content_type?)
    o += "> Content-Type: #{req.content_type}\n"
  if(req.example?)
    o += req.example+"\n"
  #response
  if(res.status?)
    o += '< ' + res.status+"\n"
  if(res.content_type?)
    o += "< Content-Type: #{res.content_type}\n"
  if(res.example?)
    o += res.example+"\n"
  else
    o += "{}\n"
  return o+"\n"

