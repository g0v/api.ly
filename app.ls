meta = do
  'pgrest.calendar': do
    f: {-raw}
    s: {date: -1}

require! pgrest

opts = pgrest.get-opts!! <<< {meta}

app <- pgrest.cli! opts, [], [], require \./lib
