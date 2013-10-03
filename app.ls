meta =
  'pgrest.calendar':
    f: {-raw}
    s: {date: -1}
    as: 'public.calendar'
    $query: ad: $not: null
    columns:
      sitting_id: $literal: '_calendar_sitting_id(calendar)'
      '*': {}
  'pgrest.sittings':
    s: {id: -1}

require! pgrest

opts = pgrest.get-opts!! <<< {meta}

app <- pgrest.cli! opts, [], [], require \./lib
