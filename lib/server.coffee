{Server} = require 'ws'
_ = require 'underscore'

server = new Server(port: 8081)
sockets = []

sendMsgFrom = (sock, msg) ->
  for osock in sockets when osock.id != sock.id
    newMsg = _.extend({id: sock.id}, msg)
    osock.send(JSON.stringify(newMsg))

sendMsgTo = (sock) ->
  for osock in sockets when osock.id != sock.id and osock.msg
    newMsg = _.extend({id: osock.id}, osock.msg)
    sock.send(JSON.stringify(newMsg))

server.on 'connection', (sock) ->
  sock.id = _.uniqueId('user')
  console.log "connected: #{sock.id}"
  sockets.push(sock)
  sendMsgTo(sock)

  sock.on 'message', (msg) ->
    msg = JSON.parse(msg)
    sock.msg = msg if msg.type == 'state'
    sendMsgFrom(sock, msg)

  sock.on 'close', ->
    console.log "disconnected: #{sock.id}"
    idx = sockets.indexOf(sock)
    sockets.splice(idx, 1)
    for osock in sockets
      osock.send JSON.stringify {type: 'close', id: sock.id}
