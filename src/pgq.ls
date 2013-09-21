require! <[qs]>

# XXX pgrest-pgq integration: run londiste create-root and add-table, setup pgq


# XXX error callback and cps to decide if loop is cancelled
export function consume-events(plx, {queue, consumer, table, interval=3000ms, dry}, cb)
  [res]? <- plx.query "select pgq.register_consumer($1, $2)" [queue, consumer]
  if res.register_consumer
    console.log "Consumer #consumer now subscribing #queue"

  cond = if table => "WHERE (e).ev_extra1 = $2" else ""
  tick = ->
    [{next_batch}]? <- plx.query "select pgq.next_batch($1, $2)" [queue, consumer]
    if next_batch
      # XXX logger
      # Event fields: (ev_id int8, ev_time timestamptz, ev_txid int8, ev_retry int4, ev_type text, ev_data text, ev_extra1, ev_extra2, ev_extra3, ev_extra4)
      # We can also use row_to_json(get_batch_events()) but we'll need polyfill for pg < 9.2
      events <- plx.query """
        SELECT (e).ev_id, (e).ev_time, (e).ev_type, (e).ev_data, (e).ev_extra1 FROM
          (select pgq.get_batch_events($1) as e) _
        #cond
        """ [next_batch] ++ if table => [table] else []
      done <- cb next_batch, events.map -> it{ev_id, ev_time, ev_type} <<< ev_data: qs.parse it.ev_data
      if done
        [{finish_batch}]? <- plx.query "select pgq.finish_batch($1)" [next_batch]
      setTimeout tick, 0
    else
      process.exit 0 if dry
      setTimeout tick, interval

  tick!
