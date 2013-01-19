{Server} = require 'ws'
_ = require 'underscore'

server = new Server(port: 8081)
sockets = []

sendMsgFrom = (sock) ->
  for osock in sockets when osock.id != sock.id
    newMsg = _.extend({id: sock.id}, sock.msg)
    osock.send(JSON.stringify(newMsg))

sendMsgTo = (sock) ->
  for osock in sockets when osock.id != sock.id
    newMsg = _.extend({id: osock.id}, osock.msg)
    sock.send(JSON.stringify(newMsg))

server.on 'connection', (sock) ->
  sock.id = _.uniqueId('user')
  sockets.push(sock)
  sendMsgTo(sock)

  sock.on 'message', (msg) ->
    sock.msg = JSON.parse(msg)
    sendMsgFrom(sock)

  sock.on 'close', ->
    idx = sockets.indexOf(sock)
    sockets.splice(idx, 1)
    for osock in sockets
      osock.send JSON.stringify {type: 'close', id: sock.id}
