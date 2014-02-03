#!/usr/bin/env lsc -cj
author: 'Chia-liang Kao'
name: 'twly'
description: 'api.ly.g0v.tw'
version: '0.0.1'
repository:
  type: 'git'
  url: 'https://github.com/g0v/ly.g0v.tw'
engines:
  node: '0.8.x'
  npm: '1.1.x'
scripts:
  prepublish: '''./node_modules/.bin/lsc -cj package.ls &&
  ./node_modules/.bin/lsc -bc -o lib src
'''
  start: './node_modules/.bin/brunch b --config brunch-templates.ls && ./node_modules/.bin/brunch watch --server'
  test: 'testacular test/testacular.config.js'
main: \lib/index.js
dependencies:
  async: \0.2.x
  optimist: \0.4.x
  express: \3.4.x
  sprintf: \0.1.1
  qs: \0.6.x
  moment: \2.4.x
  fscache: \0.0.1
  xregexp: \2.0.x
  'node-twitter-api': \1.1.x
  twlyparser: 'git://github.com/g0v/twlyparser.git'
  pgrest: 'git://github.com/clkao/pgrest.git'
devDependencies:
  LiveScript: '1.1.x'
  googleapis: '~0.6.1'
  xdg: '~0.1.1'
  mkdirp: '~0.3.5'
