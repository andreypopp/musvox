THREE = require 'three'

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

    this.game.controls.on 'command', (command, isKeyDown) =>
      charPos = this.game.controls.yawObject.position.clone()
      pos = this.pos.clone()
      this.setListenerPosition(pos.subSelf(charPos))

    this.load() if options.autoLoad

  load: (url = this.options.soundUrl) ->
    request = new XMLHttpRequest()
    request.open("GET", url, true)
    request.responseType = "arraybuffer"
    request.onload = =>
      this.make(request.response)
    request.send()

  make: (audioData) ->
    sound = this.sound = {}

    sound.source = this.ctx.createBufferSource()
    sound.source.loop = true
    sound.volume = this.ctx.createGainNode()
    sound.panner = this.ctx.createPanner()

    sound.source.connect(sound.volume)
    sound.volume.connect(sound.panner)
    sound.panner.connect(this.mainVolume)


    sound.buffer = this.ctx.createBuffer(audioData, false)

    sound.source.buffer = sound.buffer
    this.play() if this.options.autoPlay

  play: ->
    this.sound.source.noteOn(this.ctx.currentTime)

  setListenerPosition: (pos) ->
    return unless this.sound
    geomEffect = this.options.geomEffect or 0.05
    pos = pos.multiplyScalar(geomEffect)
    this.ctx.listener.setPosition(pos.x, pos.y, pos.z)

newAudioContext = ->
  if typeof AudioContext != "undefined"
    new AudioContext()
  else if typeof webkitAudioContext != "undefined"
    new webkitAudioContext();
  else
    throw new Error('AudioContext not supported. :(')

module.exports = {MusicBlock}
