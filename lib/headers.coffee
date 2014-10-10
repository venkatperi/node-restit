module.exports = exports = ( source, headers ) ->
  return unless source? and headers?
  headers = if _.isArray headers then headers else [ headers ]

  for h in headers
    throw error ("Bad header format '#{h}'") unless h.indexOf( ":" ) > 0
    [name, value] = h.split ":"
    if value.length == 0
      delete source[ name ] if source[ name ]
    else
      source[ name ] = value