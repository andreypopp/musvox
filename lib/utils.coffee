module.exports.every = (ms, func) ->
  setInterval(func, ms)

module.exports.after = (ms, func) ->
  setTimeout(func, ms)

module.exports.Logger =
  log: (message) ->
    console.log "#{this.constructor.name}: #{message}"
