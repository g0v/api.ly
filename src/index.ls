{ sprintf } = require \sprintf

function sql-ensure-index(table, index_name, expression)
  """
    IF NOT EXISTS (
        SELECT 1 FROM pg_class c WHERE  c.relname = '#index_name'
    ) THEN
        CREATE INDEX #index_name on #table #expression;
    END IF
  """

export function bootstrap(plx, cb)
  <- plx.query """
  CREATE OR REPLACE function is_valid_time(text) RETURNS boolean language plpgsql immutable as $$
  BEGIN
    RETURN CASE WHEN $1::time is null THEN false else true END;
  EXCEPTION WHEN OTHERS THEN
    return false;
  END;$$;

  CREATE TABLE IF NOT EXISTS calendar (
      id integer PRIMARY KEY,
      date date,
      time_start time default '00:00',
      time_end time default '23:59',
      type text,
      name text,
      chair text,
      summary text,
      committee text[],
      ad integer,
      session integer,
      extra integer,
      sitting integer,
      raw json
  );

  CREATE TABLE IF NOT EXISTS sittings (
      id text PRIMARY KEY,
      name text,
      summary text,
      committee text[],
      proceeding_url text,
      ad integer,
      session integer,
      extra integer,
      sitting integer
  );

  CREATE TABLE IF NOT EXISTS motions (
      sitting_id text,
      motion_class text,
      agenda_item int,
      subitem int,
      item int,
      bill_id text,
      result text,
      resolution text,
      status text,
      committee text[],

      tts_id text,
      tts_seq text,
      PRIMARY KEY(sitting_id, bill_id)
  );

  CREATE TABLE IF NOT EXISTS bills (
      bill_id text,
      bill_ref text unique,
      summary text,
      proposed_by text,
      sponsors text[],
      cosponsors text[],
      introduced date,
      abstract text,
      data json,
      doc json,

      report_of text[],
      reconsideration_of text[],

      PRIMARY KEY(bill_id)
  );

  CREATE TABLE IF NOT EXISTS ivod (
      sitting_id text,
      ad int,
      session int,
      extra int,
      sitting int,
      committee text[],
      type text,
      speaker text,
      summary text,
      thumb text,
      firm text,
      time timestamp,
      first_frame_timestamp timestamp,
      length int,
      video_url_n text primary key,
      video_url_w text,
      wmvid text,
      youtube_id text
  );
  CREATE TABLE IF NOT EXISTS ttsmotions (
      tts_key text PRIMARY KEY,
      sitting_name text,
      sitting_id text,
      source json[],
      chair text[],
      date date,
      sitting_type text,
      motion_type text[],
      summary text,
      resolution text,
      topic text[],
      category text[],
      tags text[],
      bill_refs text[],
      progress text,
      memo text,
      speakers json[],
      agencies text[]
  );

  CREATE TABLE IF NOT EXISTS laws (
    id text PRIMARY KEY,
    name text
  );

  CREATE TABLE IF NOT EXISTS amendments (
    bill_ref text,
    law_id text,

    tts_id text UNIQUE,
    source json[],

    PRIMARY KEY(bill_ref, law_id)
  );

  CREATE TABLE IF NOT EXISTS ttsbills (
    bill_ref text PRIMARY KEY,
    sitting_introduced text,
    introduced date,
    sponsors text[],
    cosponsors text[]
  );
  """

  # XXX: make plv8x /sql define-schema reusable
  <- plx.query """
  DO $$
  BEGIN
      IF NOT EXISTS(
          SELECT schema_name
            FROM information_schema.schemata
            WHERE schema_name = 'pgrest'
        )
      THEN
        EXECUTE 'CREATE SCHEMA pgrest';
      END IF;
  END
  $$;

  """
  require! pgrest
  <- pgrest.bootstrap plx, \twly require.resolve \../package.json

  <- plx.query """
  DO $$
  BEGIN
    #{ sql-ensure-index \motions, \motions_bill_id, "(bill_id)"};
    #{ sql-ensure-index \ttsmotions \ttsmotions_date, "(date)"};
    #{ sql-ensure-index \ttsmotions \ttsmotions_sitting_id, "(sitting_id)"};
    #{ sql-ensure-index \ttsmotions \ttsmotions_bill_refs, "USING gin (bill_refs)"};
    #{ sql-ensure-index \ttsmotions \ttsmotions_speakers, "USING gin (_ttsmotions_speaker_names(speakers))"};
    #{ sql-ensure-index \calendar, \calendar_sitting, "(_calendar_sitting_id(calendar))"};
  END $$;
  """

  cb!


export function _calendar_session({ad,session,extra})
  return unless ad and session
  _session = if extra
    sprintf "%02dT%02d", session, extra
  else
    sprintf "%02d", session
  sprintf "%02d-%s", ad, _session

_calendar_session.$plv8x = '(calendar):text'

# generic
export function _sitting_id({committee,sitting}:entry)
  session = _calendar_session entry
  return unless session and sitting
  sitting_type = if committee => committee.join '-' else 'YS'
  [session, sitting_type, sprintf "%02d" sitting].join \-

_sitting_id.$plv8x = '(anyelement):text'

export function _calendar_sitting_id({type,committee,sitting}:calendar)
  return unless type is \sitting
  return _sitting_id calendar

_calendar_sitting_id.$plv8x = '(calendar):text'
_calendar_sitting_id.$bootstrap = true

export function _ttsmotions_speaker_names(speakers) => speakers.map (.name)
_ttsmotions_speaker_names.$plv8x = '(json[]):text[]'
_ttsmotions_speaker_names.$bootstrap = true
