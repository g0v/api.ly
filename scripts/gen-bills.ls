#!/usr/bin/env plv8x -jr

function parse_roc_date(d)
  [_, y, m, d] = d.match /^(\d\d\d?)(\d\d)(\d\d)/
  [+y + 1911, +m , +d]

function parse_sitting(d)
  [_, ad, session, sitting, extra] = d.match /(\d+)屆(\d+)期(\d+)次(?:臨時會(\d+)會次)?/
  if extra
    "#ad#{session}T#{sitting}-#{extra}"
  else
    "#ad#{session}-#{sitting}"

function parse_source(d)
  a = d.split /(?:[\s,;]*)?(.*?)\s*(\[.*?\])/
  res = []

  do
    [_, text, link]:x = a.slice 0, 3
    if x.length is 3
      res.push {text, link: JSON.parse link}
    else
      break
  while a.splice 0, 3

  res

amendments = plv8.execute """
  SELECT
    系統號 tts_id,
    提案編號 bill_ref,
    法名稱 law_name,
    法編號 law_id,
    提案影像 source
  FROM ttsbill
""" .map ->
  it.source = parse_source it.source
  it.bill_ref .= replace /政/ \G .replace /委/ \L
  it

#'SELECT * from (SELECT count(*) as cnt from _bills group by bill_id) _ where cnt > 1
bills = plv8.execute """
WITH _bills as (
  SELECT
    提案編號 bill_ref,
    會期 sitting_introduced,
    提案日期 introduced,
    "提案委員/機關"::text sponsors
  FROM ttsbill
    group by bill_ref, sponsors, sitting_introduced, introduced
)

SELECT * from _bills
""" .map ->
  it.sponsors = JSON.parse it.sponsors
  it.cosponsors = it.sponsors.連署提案
  it.sponsors = it.sponsors.主提案
  it.bill_ref .= replace /政/ \G .replace /委/ \L
  it.introduced = parse_roc_date it.introduced .join \-
  it.sitting_introduced = parse_sitting it.sitting_introduced
  it


motions = plv8.execute """
  SELECT
    提案編號 bill_refs,
    系統號 tts_id,
    議案代碼 tts_seq,
    會議別 sitting_type,
    日期 date,
    主席 chair,
    資料來源 source,
    會議名稱 sitting_name,
    案別 motion_type,
    會議及提案內容 summary,
    決議 resolution,
    提案影像 source,
    主題 topic,
    類別 category,
    附加詞 tags,
    進度 progress,
    備註 memo,
    發言委員 speakers,
    委員會 committee,
    機關 agencies

  FROM ttsmotion

""" .map ->
  if it.bill_refs
    it.bill_refs .= map -> it.replace /政/ \G .replace /委/ \L
  it.date = parse_roc_date it.date
  if it.source
    it.source = parse_source it.source
  it

{amendments, bills, motions}
