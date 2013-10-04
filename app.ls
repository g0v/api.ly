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
    as: 'public.sittings'
    columns:
      '*': {}
      dates:
        $from: 'pgrest.calendar'
        $query: 'sitting_id': $literal: 'sittings.id'
        $order: {id: 1}
        columns:
          'calendar_id': field: 'calendar.id'
          '*': <[chair date time_start time_end]>


require! pgrest

opts = pgrest.get-opts!! <<< {meta}

app <- pgrest.cli! opts, [], [], require \./lib
