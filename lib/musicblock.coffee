_ = require 'underscore'
THREE = require 'three'
{every} = require './utils'

class MusicBlock

  constructor: (options) ->
    this.options = options

    this.game = options.game
    this.pos = options.pos
    if not (this.pos instanceof THREE.Vector3)
      this.pos = new THREE.Vector3(this.pos.x, this.pos.y, this.pos.z) 

    this.ctx = newAudioContext()
    this.mainVolume = this.ctx.createGainNode()
    this.mainVolume.connect(this.ctx.destination)
    this.sound = undefined

    this.game.createBlock(this.pos, options.texture)

    charPosOld = undefined
    every 500, =>
      charPos = this.game.controls.yawObject.position.clone()
      return if _.isEqual(charPos, charPosOld)
      charPosOld = charPos.clone()
      pos = this.pos.clone()
      this.setListenerPosition(pos.subSelf(charPos))

    this.load() if options.autoLoad

  load: (url = this.options.soundUrl) ->
    body = document.getElementsByTagName('body')[0]
    audio = document.createElement('audio')
    audio.setAttribute('src', url)
    body.appendChild(audio)
    source = this.ctx.createMediaElementSource(audio)
    this.make(source)

  make: (source) ->
    sound = this.sound = {}
    sound.source = source
    sound.source.loop = true
    sound.volume = this.ctx.createGainNode()
    sound.panner = this.ctx.createPanner()

    sound.source.connect(sound.volume)
    sound.volume.connect(sound.panner)
    sound.panner.connect(this.mainVolume)

    this.play() if this.options.autoPlay

  play: ->
    this.sound.source.mediaElement.play()

  setListenerPosition: (pos) ->
    return unless this.sound
    distanceVolumeEffect = this.options.distanceVolumeEffect or 0.05
    this.sound.source.mediaElement.volume = 1 / Math.max(pos.length(), 1)

    # XXX: this doesn't work with MediaElementSourceNode :-(
    # pos = pos.multiplyScalar(distanceVolumeEffect)
    # this.ctx.listener.setPosition(pos.x, pos.y, pos.z)

newAudioContext = ->
  if typeof AudioContext != "undefined"
    new AudioContext()
  else if typeof webkitAudioContext != "undefined"
    new webkitAudioContext();
  else
    throw new Error('AudioContext not supported. :(')

module.exports = {MusicBlock}
