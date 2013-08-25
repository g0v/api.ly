#!/usr/bin/env plv8x -jr

function parse_roc_date(d)
  [_, y, m, d] = d.match /^(\d\d\d?)(\d\d)(\d\d)/
  [+y + 1911, +m , +d]

function parse_source(d)
  [_, text, link] = d.match /(.*?)\s*(\[.*\])/
  {text, link: JSON.parse link}

x <- plv8.execute """
  SELECT 系統號 tts_id, 質詢人 mly, 質詢公報 source, 案由 summary, 答復否 answered,
    答復公報 answer_source, 質詢日期 date_asked, 答復日期 answer_date,
    類別 category, 主題 topic, 關鍵詞 keywords, 答復人 answered_by, 質詢性質 debate_type
  FROM ttsinter
   WHERE not (質詢性質 = '專案質詢')
""" .map
answer_date = delete x.answer_date
x.answered = x.answered is '已答'
answer_source = delete x.answer_source

x.date_asked = parse_roc_date x.date_asked .join \-
x.source = parse_source x.source
x.source_image = parse_source x.source_image if x.source_image
if answer_date
  x.answers = for i in [0 to answer_date.length-1]
    do
      date: parse_roc_date answer_date[i] .join \-
      source: parse_source answer_source[i]
x
