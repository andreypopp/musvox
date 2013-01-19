createGame = require 'voxel-engine'
THREE = require 'three'
_ = require 'underscore'
voxel = require 'voxel'
$ = require 'jquery-browserify'
skin = require 'minecraft-skin'
{MusicBlock} = require './musicblock'
{Tracker} = require './tracker'
{MessageBox} = require './messagebox'
{after} = require './utils'

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

  window.users = users = {}

  cleanMessage = (user) ->
    if user.textWrapper.children.length > 0
      user.textWrapper.remove(user.textWrapper.children[0])

  setMessage = (userId, msg) ->
    user = users[userId]
    return unless user
    cleanMessage(user)
    after 3000, -> cleanMessage(user)
    user.add(textSprite(msg))

  processState = (state) ->
    user = users[state.id]
    return unless user
    pos = state.yawPosition
    rot = state.yawRotation
    user.position.set(pos.x, pos.y, pos.z) if pos
    user.rotation.set(rot.x, rot.y, rot.z) if rot

  textSprite = (text) ->
    canvas = document.createElement('canvas')
    canvas.width = 60
    canvas.height = 20

    context = canvas.getContext('2d')
    context.fillText(text, 0, 10)

    texture = new THREE.Texture(canvas)
    texture.needsUpdate = true

    sprite = new THREE.Sprite
      map: texture
      transparent: true
      useScreenCoordinates: false
    sprite.position.set(0, 0, 0)
    sprite

  addUser = (state) ->
    user = skin(game.THREE, 'lib/viking.png').createPlayerObject()
    user.textWrapper = new THREE.Object3D()
    user.add(user.textWrapper)
    processState(state)
    game.scene.add(user)
    users[state.id] = user

  # message box
  window.messageBox = messageBox = new MessageBox(el: $('#messagebox'))
  messageBox.render()

  messageBox.on 'message', (message) ->
    tracker.message(message)

  window.addEventListener 'keyup', (e) ->
    return unless e.keyCode == 77 # Enter
    messageBox.show()

  # tracker
  window.tracker = tracker = new Tracker
    game: game

  tracker.on 'user:new', (state) ->
    addUser(state)

  tracker.on 'user:state', (state) ->
    processState(state)

  tracker.on 'user:close', (id) ->
    user = users[id]
    return unless user
    users[id] = undefined
    user.parent.remove(user) if user.parent

  tracker.on 'user:message', (userId, message) ->
    setMessage(userId, message)

  game
