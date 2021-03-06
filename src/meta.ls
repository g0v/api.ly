readonly = -> it

export meta =
  'pgrest.ivod': readonly do
    as: 'public.ivod'
    columns:
      '*': <[sitting_id type speaker thumb firm time first_frame_timestamp length video_url_n video_url_w wmvid youtube_id]>
  'pgrest.calendar': readonly do
    f: {-raw}
    s: {date: -1}
    as: 'public.calendar'
    $query: ad: $not: null
    columns:
      sitting_id: $literal: '_calendar_sitting_id(calendar)'
      '*': {}
  'pgrest.ttsmotions': readonly do
    s: {date: -1}
    as: 'public.ttsmotions'
    columns:
      '*': <[tts_key date source sitting_id chair motion_type summary resolution progress topic category tags bill_refs memo agencies speakers]>
  'pgrest.motions': readonly do
    s: {sitting_id: -1,motion_class: 1, agenda_item: 1}
    as: 'public.motions LEFT JOIN bills USING (bill_id) LEFT JOIN ttsbills USING (bill_ref)'
    columns:
      '*':
        motions: {}
        bills: <[bill_ref summary proposed_by]>
        ttsbills: <[sitting_introduced]>
      'doc': type: \json
  'pgrest.sittings': readonly do
    s: {id: -1}
    f: {-videos}
    as: 'public.sittings'
    primary: \id
    columns:
      '*': {}
      dates:
        $from: 'pgrest.calendar'
        $query: 'sitting_id': $literal: 'sittings.id'
        $order: {date: 1}
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
          '*': <[motion_class agenda_item subitem item bill_id bill_ref proposed_by summary doc sitting_introduced]>
  'pgrest.amendments': readonly do
    as: "amendments JOIN laws ON (amendments.law_id = laws.id)"
  'pgrest.laws': readonly do
    as: "laws"
  'pgrest.bills': readonly do
    s: {bill_id: -1}
    f: {data: -1, law_ids: -1}
    as: "bills LEFT JOIN (select sponsors, cosponsors, bill_ref, sitting_introduced, 'legislative'::text as bill_type from ttsbills) ttsbills USING (bill_ref)"
    primary: (id) ->
      $or:
        bill_ref: id
        bill_id: id
    columns:
      '*': <[bill_id bill_ref summary proposed_by abstract report_of reconsideration_of bill_type sitting_introduced]>
      data: type: \json
      doc: type: \json
      sponsors: $literal: '(case when ttsbills.sponsors is null then bills.sponsors else ttsbills.sponsors end)'
      cosponsors: $literal: '(case when ttsbills.cosponsors is null then bills.cosponsors else ttsbills.cosponsors end)'
      law_ids:
        $literal: '(select array_agg(law_id) from amendments where amendments.bill_ref = bills.bill_ref)'
      amendments:
        $from: 'pgrest.amendments'
        $query: 'bill_ref': $literal: 'bills.bill_ref'
        columns:
          '*': <[law_id name source]>
      motions:
        $from: 'pgrest.motions JOIN pgrest.sittings ON (sitting_id = sittings.id)'
        $query: 'bill_id': $literal: 'bills.bill_id'
        # XXX: better sorting required, since 08-03T01-XX comes before 08-03-XX
        $order: {sitting_id: 1}
        columns:
          '*':
            motions: <[sitting_id resolution status committee motion_class agenda_item item]>
            sittings: <[dates]>
  'pgrest.ttsinterpellation': readonly do
    as: "ttsinterpellation"

  'pgrest.analytics': readonly do
    as: "stats.analytics"
