casper = require('casper').create { clientScripts: ["bower_components/jquery/jquery.min.js"] }
fs = require('fs')

{session, extra, type, output} = casper.cli.raw.options

if type == 'i'
  url = 'http://localhost:5000/lgcgi/ttswebpw?in_out/qrin'
else if type == 'b'
  [_, ad, s] = session.match /(\d\d)(\d\d)/
  url = "http://localhost:5000/lgcgi/ttsweb?@0:0:1:lgmempropg#{ad}"
else if type == 'x'
  [_, ad, s] = session.match /(\d\d)(\d\d)/
  session = "#{ad}屆#{s}期"
  url = 'http://localhost:5000/lgcgi/ttswebpw?in_out/mempro2in'
else
  [_, ad, s] = session.match /(\d\d)(\d\d)/
  session = "#{ad}屆#{s}期"
  console.log session
  url = 'http://localhost:5000/ttscgi/ttsweb?@0:0:1:/disk1/lg/lgmeet'

casper.start url, ->
  @page.onConsoleMessage = (msg) ->
    console.log('message: ' + msg)

if type == 'i'
    casper.then ->
        @click 'input[name="_IMG_瀏覽索引"]'
    casper.then ->
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
else if type == 'b'
    if extra == true
        casper.then ->
            res = @evaluate ->
                x = []
                $('select[name="_TTS.SBT2"] option').map ->
                    x.push this.value if this.value
                return x
        casper.then -> @exit()
    else if extra
        casper.then ->
            res = @evaluate ((args) ->
                $('select[name="_TTS.SBT2"]').val args
            ), extra
    else
        casper.then ->
            @evaluate ((args) ->
                matched = $('select[name="_TTS.SBT1"] option').filter ->
                    $(this).val().indexOf(args) == 0

                console.log matched[matched.length - 1].value
                $('select[name="_TTS.SBT1"]').val matched[0].value
                $('select[name="_TTS.SBT1.83.40"]').val matched[matched.length - 1].value
            ), session
    casper.thenClick 'input[name="_IMG_執行檢索"]', ->
        console.log 'nextup!'
else if type is 'x'
    casper.then ->
      # search for 'casperjs' from google form
      @fill "form[name=TTSWEB]", {
        "_TTS.SBF4": "SE"
        "_TTS.SBT4": session
      }, false
      @click 'input[name="_IMG_執行檢索"]'
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

casper.run ->
    # display results
    fs.write output, @getPageContent(), 'w'
    @exit()
