_ = require 'underscore'
THREE = require 'three'
{Player} = require './backbone.sm2'
{every} = require './utils'

class MusicBlock

  constructor: (options) ->
    this.options = options

    this.id = options.id or undefined
    this.cid = _.uniqueId('musicblockc')

    this.game = options.game

    this.pos = options.pos
    if not (this.pos instanceof THREE.Vector3)
      this.pos = new THREE.Vector3(this.pos.x, this.pos.y, this.pos.z) 


    newBlock = this.game.checkBlock(this.pos)

    this.chunkIndex = options.chunkIndex or newBlock.chunkIndex
    this.voxelVector = options.voxelVector or newBlock.voxelVector
    if not (this.voxelVector instanceof THREE.Vector3)
      this.voxelVector = new THREE.Vector3(this.voxelVector.x, this.voxelVector.y, this.voxelVector.z) 

    this.player = new Player()
    this.charPosOld = undefined
    every 500, => this.updateListenerPosition()

    if options.sound
      this.add(options.sound) 
      this.play() if options.autoPlay

    if options.show
      this.show()

  show: ->
    set = this.voxelAtChunkIndexAndVoxelVector(this.chunkIndex, this.voxelVector, this.options.texture)
    this.game.showChunk(this.game.voxels.chunks[this.chunkIndex])

  voxelAtChunkIndexAndVoxelVector: (ckey, v, val) ->
    chunk = this.game.voxels.chunks[ckey]
    return if not chunk
    size = this.game.voxels.chunkSize
    vidx = v.x + v.y * size + v.z * size * size
    if typeof val != 'undefined'
      before = chunk.voxels[vidx]
      chunk.voxels[vidx] = val
    v = chunk.voxels[vidx]
    v

  add: (sound) ->
    this.player.add(sound)

  play: ->
    this.player.play()

  updateListenerPosition: ->
    charPos = this.game.controls.yawObject.position.clone()
    return if _.isEqual(charPos, this.charPosOld)
    this.charPosOld = charPos.clone()
    pos = this.pos.clone()
    this.setListenerPosition(pos.subSelf(charPos))

  setListenerPosition: (pos) ->
    distanceVolumeEffect = this.options.distanceVolumeEffect or 0.2
    volume = 1 / Math.max(pos.length() * distanceVolumeEffect, 1)
    volume = parseInt(volume * 700)
    volume = 0 if volume < 5
    this.player.sound?.setVolume(volume)

module.exports = {MusicBlock}
