{Server} = require 'ws'
_ = require 'underscore'

server = new Server(port: 8081)
sockets = []

sendMsgFrom = (sock, msg) ->
  for osock in sockets when osock.id != sock.id
    newMsg = _.extend({id: sock.id}, msg)
    send(osock, newMsg)

sendMsgTo = (sock) ->
  for osock in sockets when osock.id != sock.id and osock.msg
    newMsg = _.extend({id: osock.id}, osock.msg)
    send(sock, newMsg)

send = (sock, data) ->
  try
    sock.send JSON.stringify data
  catch e
    undefined

server.on 'connection', (sock) ->
  sock.id = _.uniqueId('user')
  console.log "connected: #{sock.id}"
  sockets.push(sock)
  sendMsgTo(sock)

  sock.on 'message', (msg) ->
    msg = JSON.parse(msg)

    # store state on socket to broadcast on new client
    if msg.type == 'state'
      sock.msg = msg

    # assign id to musicblock
    if msg.type == 'musicblock'
      msg.musicblockId = _.uniqueId('musicblock')

      send(sock, _.extend({}, msg, {type: 'musicblock:reply'}))

    sendMsgFrom(sock, msg)

  sock.on 'close', ->
    console.log "disconnected: #{sock.id}"
    idx = sockets.indexOf(sock)
    sockets.splice(idx, 1)
    for osock in sockets
      osock.send JSON.stringify {type: 'close', id: sock.id}
