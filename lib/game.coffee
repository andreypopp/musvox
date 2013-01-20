createGame = require 'voxel-engine'
THREE = require 'three'
_ = require 'underscore'
voxel = require 'voxel'
Backbone = require './backbone'
$ = require 'jquery-browserify'
skin = require 'minecraft-skin'
{MusicBlock} = require './musicblock'
{Tracker} = require './tracker'
{MessageBox, SongBox} = require './messagebox'
{after} = require './utils'


class Game extends Backbone.View

  events:
    click: ->
      this.game.requestPointerLock(this.el)

  initialize: ->
    this.game = createGame
      generate: voxel.generator['Hill']
      texturePath: 'lib/textures/'
      materials: [['grass', 'dirt', 'grass_dirt'], 'brick', 'dirt', 'obsidian', 'crate', 'speaker']
      cubeSize: 25
      chunkSize: 32
      chunkDistance: 2
      startingPosition: [385, 70, 385]
      worldOrigin: [0, 0, 0]
      controlOptions: {jump: 6}
    this.game.on 'mousedown', (pos) =>
      this.addMusicBlock(pos)
    this.musicBlocks = []
    this.users = {}

  cleanUserMessage: (userId) ->
    user = this.users[userId]
    return unless user
    if user.textWrapper.children.length > 0
      user.textWrapper.remove(user.textWrapper.children[0])

  setUserMessage: (userId, msg) ->
    return # XXX: doesn't work for now
    user = this.users[userId]
    return unless user
    this.cleanUserMessage(user)
    after 3000, => this.cleanUserMessage(user)
    user.textWrapper.add(textSprite(msg))

  updateUser: (userId, state) ->
    user = this.users[userId]
    return unless user
    pos = state.yawPosition
    rot = state.yawRotation
    user.position.set(pos.x, pos.y, pos.z) if pos
    user.rotation.set(rot.x, rot.y, rot.z) if rot

  removeUser: (userId) ->
    user = this.users[userId]
    return unless user
    this.users[userId] = undefined
    user.parent.remove(user) if user.parent

  addUser: (userId, state) ->
    user = skin(this.game.THREE, 'lib/viking.png').createPlayerObject()
    this.users[userId] = user

    user.textWrapper = new THREE.Object3D()
    user.add(user.textWrapper)

    this.game.scene.add(user)
    this.updateUser(userId, state)

  render: ->
    this.game.appendTo(this.el)
    this.listenTo Backbone,
      hideGame: => this.$el.hide()
      showGame: => this.$el.show()

  addMusicBlock: (pos) ->
    musicBlock = new MusicBlock
      game: this.game
      texture: 6
      pos: pos
      autoLoad: true
      autoPlay: true
    SongBox.open (track) =>
      musicBlock.add(track)
      musicBlock.play()
    this.musicBlocks.push(musicBlock)

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

$(window).on 'keyup', (e) ->
  if e.keyCode == 77 # 'm'
    Backbone.trigger 'showMessageBox'

gameView = window.gameView = new Game(el: $('#game'))
gameView.render()

messageBox = window.messageBox = new MessageBox(el: $('#messagebox'))
messageBox.render()
messageBox.on 'message', (message) =>
  tracker.message(message)

tracker = window.tracker = new Tracker(game: gameView.game)
tracker.on 'user:new', (state) =>
  gameView.addUser(state.id, state)
tracker.on 'user:state', (state) =>
  gameView.updateUser(state.id, state)
tracker.on 'user:close', (userId) =>
  gameView.removeUser(userId)
tracker.on 'user:message', (userId, message) =>
  gameView.setUserMessage(userId, message)
