#!/usr/bin/env plv8x -jr

# XXX this requires lbills and lmotions tables, which are PUT'ed with g0v-data/ly/ly-bills
# table names are subject to change
matrix = {}

function add_edge(source,target)
  matrix[source] ?= {}
  matrix[source][target] ?= 0
  ++matrix[source][target]

bills = plv8.execute """
  SELECT bill_ref from lbills
""" .map ->
  is_g = it.bill_ref.match /G/

  source = if is_g => '政府提案' else '委員提案'
  res = plv8.execute """
    SELECT date, progress, committee from lmotions where bill_refs @> $1  order by date
  """ [[it.bill_ref]]
  progresses = [source] ++ [committee ? progress for {progress,committee} in res].filter -> it
  match progresses[*-1]
  | /三讀/ => progresses.push '公布'
  | /覆議/ =>
  else => progresses.push '未處理'

  for i in [1 to progresses.length-1]
    add_edge progresses[i-1], progresses[i] if progresses[i-1] isnt progresses[i]

nodes = []
links = []
by-name = {}

function get_node(name)
  if (n = by-name[name])?
    return n

  nodes.push {name}
  by-name[name] = nodes.length-1

for _source of matrix
  for _target, value of matrix[_source]
    [source, target] = [_source, _target].map get_node
    links.push {source, target, value} if source isnt target


{nodes, links}
