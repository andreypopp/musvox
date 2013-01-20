((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['backbone', 'underscore'], (Backbone, _) ->
      root.Backbone.SM2 = factory(Backbone, _)
  else if typeof require == 'function' and module?.exports?
    module.exports = factory(require('./backbone'), require('underscore'))
  else
    root.Backbone.SM2 = factory(root.Backbone, root._)
) this, (Backbone, _) ->

  ###*
   * Playlist iterator('cursor') pointed at currently played track and returning
   * previous and next tracks in the queue
   ###
  class QueueCursor
    constructor: (queue) ->
      @queue = queue
      @ref = -1

    cur: ->
      if _.isArray(@ref) then @queue.at(@ref[0]).at(@ref[1]) else @queue.at(@ref)

    peek: ->
      @nextImpl().track

    find: (id) ->
      {track, ref} = @findImpl(id)
      @ref = ref
      track

    next: ->
      {track, ref} = @nextImpl()
      @ref = ref
      track

    prev: ->
      {track, ref} = @prevImpl()
      @ref = ref
      track

    findImpl: (id) ->
      for t, i in @queue.models
        if t.get('tracks')
          for tt, j in t.get('tracks').models
            if tt.id == id or tt.cid == id
              return {track: tt, ref: [i, j]}
        else
          if t.id == id or t.cid == id
            return {track: t, ref: i}
      {track: undefined, ref: @ref}

    # compute prev track in queue and prev ref but do not update them
    prevImpl: ->
      if _.isArray(@ref)
        ref = @ref.slice()
        track = @queue.at(ref[0]).get('tracks').at(ref[1] - 1)
        if track
          ref[1] = ref[1] - 1
        else
          track = @queue.at(ref[0] - 1)
          ref = ref[0] - 1
      else
        ref = @ref - 1
        track = @queue.at(ref)

      # we reached the start of the queue
      if not track
        return {ref: -1, track: track}

      if track.get('tracks')
        ref = [ref, track.get('tracks').length - 1]
        track = track.get('tracks').last()

      {ref, track}

    # compute next track in queue and next ref but do not update them
    nextImpl: ->
      if _.isArray(@ref)
        ref = @ref.slice()
        track = @queue.at(ref[0]).get('tracks').at(ref[1] + 1)
        if track
          ref[1] = ref[1] + 1
        else
          track = @queue.at(ref[0] + 1)
          ref = ref[0] + 1
      else
        ref = @ref + 1
        track = @queue.at(ref)

      # we reached the end of the queue
      if not track
        return {ref: @ref, track: @cur()}

      if track.get('tracks')
        ref = [ref, 0]
        track = track.get('tracks').at(0)

      {ref, track}

  ###*
   * Player class
  ###
  class Player
    _.extend this.prototype, Backbone.Events

    preloadThreshold: 5000 # msec

    constructor: (options) ->
      @allowPreload = options?.allowPreload
      @preloadThreshold = options?.preloadThreshold or @preloadThreshold
      @sound = undefined
      @nextSound = undefined
      @queue = new Backbone.Collection()
      @cur = new QueueCursor(@queue)

    add: (track) ->
      track = if _.isArray(track)
        new Backbone.Model(tracks: new Backbone.Collection(track))
      else if track instanceof Backbone.Collection
        new Backbone.Model(tracks: track)
      else if track instanceof Backbone.Model
        track
      else
        new Backbone.Model(track)
      @queue.add(track)
      @trigger('queue:add', track)

    isActive: (track, playState = 0) ->
      if track
        @sound?.playState == playState and @sound?.id == track.id
      else
        @sound?.playState == playState

    isPlaying: (track) ->
      @isActive(track, 1) and not @sound?.paused

    isPaused: (track) ->
      @isActive(track, 1) and @sound?.paused

    play: (id) ->
      if id
        track = @cur.find(id)
        return if not track
        @sound = @initPlayable(track)
        @initSound(@sound)
        if @sound
          @trigger('queue:select', @sound.track, @sound)
        @sound
      else
        return if @isPlaying()
        if @sound?
          @sound.play()
          @trigger('track:play', @sound.track, @sound)
        else
          track = @cur.next()

          # reached the end of the queue
          if not track
            this.trigger('queue:end')
            return

          @sound = @initPlayable(track)
          @initSound(@sound)
        @sound

    pause: ->
      return unless @sound?
      @sound.pause()
      @trigger('track:pause', @sound.track, @sound)

    stop: (destruct = false) ->
      return unless @sound?
      @sound.stop()
      @trigger('track:stop', @sound.track, @sound)
      if destruct
        @sound.destruct()
        @sound = undefined

    next: ->
      return unless @sound?
      @stop(true)
      if @nextSound?
        @sound = @nextSound
        @initSound(@sound)
        @cur.next()
      else
        @play()
      if @sound
        @trigger('queue:next', @sound.track, @sound)
      @sound

    prev: ->
      return unless @sound?
      @stop(true)
      track = @cur.prev()

      # reached the start of the queue
      if not track
        return

      @sound = @initPlayable(track)
      @initSound(@sound)
      if @sound
        @trigger('queue:prev', @sound.track, @sound)
      @sound

    # init track with a sound object
    initPlayable: (track, preload = false) ->
      sound = soundManager.createSound
        onid3: =>
          @trigger 'track:id3loaded', track, sound.id3
        onload: =>
          @preloadNextFor(sound)
        onfinish: =>
          @trigger('track:finish', @sound.track, @sound)
          @next()
        id: track.get('id')
        url: if _.isFunction(track.url) then track.url() else track.get('url')
        whileplaying: =>
          @trigger 'track:whileplaying', track, sound
        whileloading: =>
          @trigger 'track:whileloading', track, sound
      sound.track = track
      sound

    # start playing sound
    initSound: (sound) ->
      @sound = sound
      @nextSound = undefined
      @trigger('track:play', @sound.track, @sound)
      @sound.play()

    # set a callback on sound position to start preloading next track
    preloadNextFor: (sound) ->
      if @allowPreload?
        offset = sound.duration - @preloadThreshold
        sound.onPosition (offset), =>
          sound.clearOnPosition(offset)
          track = @cur.peek()
          @nextSound = @initPlayable(track)
          @nextSound.load()

  ###*
   * Player app
  ###
  class PlayerView extends Backbone.View
    className: 'app'

    initialize: (options) ->
      @player = options?.player or new Player()
      @listenTo(@player, 'track:play', @onPlay) if @onPlay
      @listenTo(@player, 'track:stop', @onStop) if @onStop
      @listenTo(@player, 'track:pause', @onPause) if @onPause
      @listenTo(@player, 'queue:add', @onQueueAdd) if @onQueueAdd
      @listenTo(@player, 'track:id3loaded', @onTrackInfoReceived) if @onTrackInfoReceived

  ###*
   * Progress bar
  ###
  class ProgressBar extends Backbone.View
    className: 'view-progress-bar'

    events:
      'click': 'onClick'

    initialize: (options) ->
      @$progressBar = undefined
      @$bufferingBar = undefined

      # current track id
      @trackId = undefined
      @player = options.player
      @listenTo @player,
        'track:play': @onPlay
        'track:stop': @onStop
        'track:whileplaying': @whilePlaying
        'track:whileloading': @whileLoading

    render: ->
      @$el.html """
        <div class="buffering-bar"></div>
        <div class="progress-bar"></div>
        """
      @updateElements()

    updateElements: ->
      @$progressBar = @$('.progress-bar')
      @$bufferingBar = @$('.buffering-bar')

    onClick: (e) ->
      return unless @trackId? and @player.sound?
      pos = (e.offsetX / @$el.width()) * @player.sound.duration
      @player.sound.setPosition(pos)

    onPlay: (track) ->
      @trackId = track.id

    onStop: ->
      @trackId = undefined
      @$progressBar.width(0)

    whilePlaying: (track, sound) ->
      if track.id == @trackId
        maxW = @$el.width()
        w = (sound.position / sound.duration) * maxW
        @$progressBar.width(Math.min(w, maxW))

    whileLoading: (track, sound) ->
      if track.id == @trackId
        maxW = @$el.width()
        w = (sound.bytesLoaded / sound.bytesTotal) * maxW
        @$bufferingBar.width(Math.min(w, maxW))

  {Player, PlayerView, ProgressBar}
