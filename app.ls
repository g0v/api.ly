require \.meta
require! pgrest

opts = pgrest.get-opts!! <<< {meta}

app <- pgrest.cli! opts, [], [], require \./lib
