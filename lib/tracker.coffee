{every} = require './utils'
_ = require 'underscore'
{EventEmitter} = require('events')
inherits = require('inherits')

class Tracker
  inherits this, EventEmitter

  constructor: (options) ->
    this.options = options or {}
    this.game = options.game
    this.sock = new WebSocket("ws://#{window.location.hostname}:8081/")
    this.sock.onopen = => this.onOpen()
    this.sock.onmessage = (msg) =>
      msg = JSON.parse(msg.data)
      this.onMessage(msg)
    this.seenIds = {}

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
        this.sock.send JSON.stringify
          type: 'state'
          yawPosition: yawPosition
          yawRotation: yawRotation


  onMessage: (msg) ->
    if msg.type == 'state'
      if not this.seenIds[msg.id]
        this.emit 'user:new', msg
        this.seenIds[msg.id] = true
      else
        this.emit 'user:state', msg
    else if msg.type == 'close'
      this.emit 'user:close', msg.id
      delete this.seenIds[msg.id]

module.exports = {Tracker}
