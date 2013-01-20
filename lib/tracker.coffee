_ = require 'underscore'
$ = require 'jquery-browserify'
{EventEmitter} = require 'events'
inherits = require 'inherits'
{every, Logger} = require './utils'

###*
  Game state tracker.

  @param {object} options - an options object, `game` option is required
###
class Tracker
  inherits this, EventEmitter
  _.extend(this.prototype, Logger)

  constructor: (options) ->
    this.options = options or {}
    this.game = options.game
    this.sock = new WebSocket("ws://#{window.location.hostname}:8081/")
    this.seenIds = {}

    this.sock.onopen = =>
      $(window).on 'unload', => this.sock.close()
      $(window).on 'close', => this.sock.close()
      this.onOpen()

    this.sock.onmessage = (msg) =>
      msg = JSON.parse(msg.data)
      this.onMessage(msg)

  ###*
    Send a `message` over websocket.
  ###
  send: (msg) ->
    this.sock.send(JSON.stringify(msg))

  ###*
    Send a chat `message` to other users.
  ###
  message: (message) ->
    this.send
      type: 'message'
      message: message

  ###*
    Callback for connection open with a server.
    This callback sets up a player's state notification.
  ###
  onOpen: ->
    interval = this.options.interval or 300
    yawPositionOld = undefined
    yawRotationOld = undefined
    every interval, =>
      needBroadcast = false

      yawPosition = this.game.controls.yawObject.position.clone()
      yawPosition.y = yawPosition.y - this.game.cubeSize
      needBroadcast = true unless _.isEqual(yawPosition, yawPositionOld)
      yawPositionOld = yawPosition.clone()

      yawRotation = this.game.controls.yawObject.rotation.clone()
      yawRotation.y = yawRotation.y + Math.PI / 2
      needBroadcast = true unless _.isEqual(yawRotation, yawRotationOld)
      yawRotationOld = yawRotation.clone()
      
      if needBroadcast
        this.send
          type: 'state'
          yawPosition: yawPosition
          yawRotation: yawRotation

  ###*
    Callback for every message received from a server.

    @param {object} msg - received message
  ###
  onMessage: (msg) ->
    if msg.type == 'state'
      if not this.seenIds[msg.id]
        this.log("connected: #{msg.id}")
        this.emit 'user:new', msg
        this.seenIds[msg.id] = true
      else
        this.emit 'user:state', msg

    else if msg.type == 'close'
      this.log("disconnected: #{msg.id}")
      this.emit 'user:close', msg.id
      delete this.seenIds[msg.id]

    else if msg.type == 'message'
      this.emit 'user:message', msg.id, msg.message

    else
      console.log 'unknown message type', msg

module.exports = {Tracker}
