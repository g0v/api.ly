require! fs
base_url = 'http://api-beta.ly.g0v.tw'
version  = \v0
collections = \collections
base_path = "/#{version}/#{collections}/"
uri = "#{base_url}/#{base_path}"

# header
output = """
FORMAT: X-1A
HOST: #{base_url}

# TW ly api #{version}
online test of [beta API](http://api-beta.ly.g0v.tw)
This is beta version of api.ly.g0v.tw. Written in [apiblueprint](http://apiblueprint.org/) by [Markdown](http://daringfireball.net/projects/markdown/syntax) syntax.\n\n
"""

# version and collections summary
output += doc_section('Version', 'Show specific version of API.' {'uri': "/#{version}/"});
output += doc_section('Collections', 'List all avaible collection of current version.', {'uri': base_path});

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
  o += doc_section(collection, 'This is the api group of '+collection)+"\n"
  o += doc_section(collection, null, {'uri': base_path+collection+'/'}, null, 2)

  if(c.primary?)
    #have sub query
    if(typeof c.primary == 'function')
      # special case for bill_id
      id = 'bill_id'
    else
      id = c.primary
    o += doc_section(collection+'.entries', null, {'uri': base_path+collection+"/{#{id}}/"}, null, 3)
    if(c.columns?)
      for column of c.columns
        if(column != '*')
          o += doc_section(collection+'.entries.'+column, null, {'uri': base_path+collection+"/{#{id}}/#{column}"}, null, 4)
  output += o

fs.writeFile('apiary.apib', output)
console.log(output)


function doc_section(title, desc = null, req = {}, res = {}, level = 1)
  sharp = ''
  for i from 1 to level
    sharp+='#'
  o = []
  if(req?)
    if(req.uri?)
      o.push(sharp+" GET #{req.uri}")
  else
    o.push(sharp+' '+title)
  if(desc?)
    o.push(desc)
  else
    if(req?)
      o.push("Try real api path: #{base_url}#{req.uri} ");
  o.push(doc_section_res(res))
  return o.join("\n")+"\n";

function doc_section_res(res)
  o = []
  if(res.content_type?)
    content_type = '('+req.content_type+')'
  else
    content_type = '(application/json)'
  o.push("+ Response 200 "+content_type)
  if(res.example?)
    o.push("\n\t"+res.example+"\n")
  return o.join("\n")+"\n"

