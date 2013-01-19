createGame = require 'voxel-engine'
THREE = require 'three'
_ = require 'underscore'
voxel = require 'voxel'
skin = require 'minecraft-skin'
{MusicBlock} = require './musicblock'
{Tracker} = require './tracker'

currentMaterial = 1
erase = true

module.exports = ->

  window.game = game = createGame
    generate: voxel.generator['Valley']
    texturePath: 'lib/textures/'
    materials: [['grass', 'dirt', 'grass_dirt'], 'brick', 'dirt', 'obsidian', 'crate', 'speaker']
    cubeSize: 25
    chunkSize: 32
    chunkDistance: 2
    startingPosition: [35, 1024, 35]
    worldOrigin: [0,0,0]
    controlOptions: {jump: 6}

  window.music = music = new MusicBlock
    game: game
    texture: 6
    pos: {x: 5, y: 77, z: 5}
    soundUrl: 'http://api.soundcloud.com/tracks/293/stream?client_id=609ae0b573913db156968e0ec38c1e26'
    autoLoad: true
    autoPlay: true
    distanceVolumeEffect: 1

  window.users = users = {}

  processState = (state) ->
    user = users[state.id]
    return unless user
    pos = state.yawPosition
    rot = state.yawRotation
    user.position.set(pos.x, pos.y, pos.z) if pos
    user.rotation.set(rot.x, rot.y, rot.z) if rot

  window.tracker = tracker = new Tracker
    game: game

  tracker.on 'user:new', (state) ->
    user = skin(game.THREE, 'lib/viking.png').createPlayerObject()
    processState(state)
    game.scene.add(user)
    users[state.id] = user

  tracker.on 'user:state', (state) ->
    processState(state)

  tracker.on 'user:close', (id) ->
    users[id] = undefined

  game
