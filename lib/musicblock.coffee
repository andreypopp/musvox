_ = require 'underscore'
THREE = require 'three'
{Player} = require './backbone.sm2'
{every} = require './utils'

class MusicBlock

  constructor: (options) ->
    this.options = options

    this.game = options.game
    this.pos = options.pos
    if not (this.pos instanceof THREE.Vector3)
      this.pos = new THREE.Vector3(this.pos.x, this.pos.y, this.pos.z) 
    this.game.createBlock(this.pos, options.texture)

    this.player = new Player()

    charPosOld = undefined
    every 500, =>
      charPos = this.game.controls.yawObject.position.clone()
      return if _.isEqual(charPos, charPosOld)
      charPosOld = charPos.clone()
      pos = this.pos.clone()
      this.setListenerPosition(pos.subSelf(charPos))

    this.add(options.sound) if options.sound

  add: (sound) ->
    this.player.add(sound)

  play: ->
    this.player.play()

  setListenerPosition: (pos) ->
    distanceVolumeEffect = this.options.distanceVolumeEffect or 0.2
    volume = 1 / Math.max(pos.length() * distanceVolumeEffect, 1)
    volume = parseInt(volume * 700)
    volume = 0 if volume < 5
    this.player.sound?.setVolume(volume)

module.exports = {MusicBlock}
