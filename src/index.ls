{ sprintf } = require \sprintf

export function _calendar_session({ad,session,extra})
  _session = if extra
    sprintf "%02dT%02d", session, extra
  else
    sprintf "%02d", session
  sprintf "%02d-%s", ad, _session

_calendar_session.$plv8x = '(calendar):text'
