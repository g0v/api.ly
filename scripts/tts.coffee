casper = require('casper').create { clientScripts: ["components/jquery/jquery.js"] }
fs = require('fs')

casper.start "http://localhost:5000/ttscgi/ttsweb?@0:0:1:/disk1/lg/lgmeet"

casper.then ->
  @echo 'go'

  @page.onConsoleMessage = (msg) ->
    console.log('message: ' + msg)

  # search for 'casperjs' from google form
  @fill "form[name=TTSWEB]", {
    "_TTS.SBF1": "SE"
    "_TTS.SBT1": "08屆02期"
  }, false
  @click 'input[name="_IMG_執行檢索"]'

toClick = null
casper.then ->
  @evaluate ->
    matched = $(document).text().match(/共(\d+)筆，本頁顯示/)
    entries = matched[1]
    $doc = $ document
    $('select[name="_TTS.DISPLAYPAGE"]').get(0).options[0].value = entries
    details = $doc.find('input[name="_IMG_顯示詳目"]')
    if (details.length)
        toClick = 'input[name="_IMG_顯示詳目"]'
    else
        toClick = 'input[name="_IMG_顯示結果"]'

casper.thenClick 'input[name="_IMG_顯示詳目"]', ->
  @echo 'clicked?', toClick

casper.run ->
  # display results
  fs.write "./output.html", @getPageContent(), 'w'
  @exit()
