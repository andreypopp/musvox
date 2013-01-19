createGame = require 'voxel-engine'
THREE = require 'three'
voxel = require 'voxel'
skin = require 'minecraft-skin'

currentMaterial = 1
erase = true

module.exports = ->
  game = createGame
    generate: voxel.generator['Valley']
    texturePath: 'lib/textures/'
    materials: [['grass', 'dirt', 'grass_dirt'], 'brick', 'dirt', 'obsidian', 'crate']
    cubeSize: 25
    chunkSize: 32
    chunkDistance: 2
    startingPosition: [35, 1024, 35]
    worldOrigin: [0,0,0]
    controlOptions: {jump: 6}

  game.on 'mousedown', ->
    cid = game.voxels.chunkAtPosition(pos)
    vid = game.voxels.voxelAtPosition(pos)

  game.on 'collision', (item) ->
    incrementBlockTally()
    game.removeItem(item)

  game
