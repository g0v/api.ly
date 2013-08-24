casper = require('casper').create { clientScripts: ["components/jquery/jquery.min.js"] }
fs = require('fs')

{session, type, output} = casper.cli.raw.options

if type == 'i'
  url = 'http://localhost:5000/lgcgi/ttswebpw?in_out/qrin'
else
  url = 'http://localhost:5000/ttscgi/ttsweb?@0:0:1:/disk1/lg/lgmeet'
  [_, ad, s] = session.match /(\d\d)(\d\d)/
  session = "#{ad}屆#{s}期"
  console.log session

casper.start url, ->
  @page.onConsoleMessage = (msg) ->
    console.log('message: ' + msg)

if type == 'i'
    casper.then ->
        @echo 'grr!'
        @click 'input[name="_IMG_瀏覽索引"]'
    casper.then ->
        @echo 'foo!'
        @evaluate ((args) ->
            [res] = $('select[name="_TTS.BROWSEKEY"] option').filter (index) ->
                $(this).text().replace(/\s/g, '') == '屆期'
            $('select[name="_TTS.BROWSEKEY"]').val res.value
            $('input[name="_TTS_BROWSEKEYVALUE"]').val args
        ), session

    casper.thenClick 'input[name="_IMG_執行瀏覽"]', ->
        href = @evaluate ((args) ->
            [res] = $('blockquote table[border="1"]').find('a').filter ->
                $(this).text().replace(/\s/g, '') == args
            return $(res).attr('href')
        ), session
        @click 'a[href="'+href+'"]'

        @echo 'nextup!'
else
    casper.then ->
      # search for 'casperjs' from google form
      @fill "form[name=TTSWEB]", {
        "_TTS.SBF1": "SE"
        "_TTS.SBT1": session
      }, false
      @click 'input[name="_IMG_執行檢索"]'

toClick = null
casper.then -> @evaluate ->
    matched = $(document).text().match(/共(\d+)筆，本頁顯示/)
    entries = matched[1]
    console.log 'total entries', entries
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
    fs.write output, @getPageContent(), 'w'
    @exit()
