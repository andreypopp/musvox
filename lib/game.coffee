createGame = require 'voxel-engine'
THREE = require 'three'
voxel = require 'voxel'
skin = require 'minecraft-skin'
{MusicBlock} = require './musicblock'

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

  window.music = new MusicBlock
    game: game
    texture: 6
    pos: {x: 5, y: 77, z: 5}
    soundUrl: 'lib/sounds/Mark_Neil_-_11_strANGE_Ls.mp3'
    autoLoad: true
    autoPlay: true
    distanceVolumeEffect: 0.3

  game
