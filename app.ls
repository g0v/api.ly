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

require! pgrest

opts = pgrest.get-opts!! <<< {meta}

app <- pgrest.cli! opts, [], [], require \./lib
