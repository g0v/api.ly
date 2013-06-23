#!/usr/bin/env lsc -cj
author: 'Chia-liang Kao'
name: 'api.ly.g0v.tw'
description: 'api.ly.g0v.tw'
version: '0.0.1'
repository:
  type: 'git'
  url: 'https://github.com/g0v/ly.g0v.tw'
engines:
  node: '0.8.x'
  npm: '1.1.x'
scripts:
  prepublish: './node_modules/.bin/lsc -cj package.ls'
  start: './node_modules/.bin/brunch b --config brunch-templates.ls && ./node_modules/.bin/brunch watch --server'
  test: 'testacular test/testacular.config.js'
dependencies:
  async: \0.2.x
  optimist: \0.4.x
  pgrest: 'git://github.com/clkao/pgrest.git'
devDependencies:
  LiveScript: '1.1.x'
