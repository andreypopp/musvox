require './jquery-ui'
$ = require 'jquery-browserify'
Backbone = require './backbone'
{soundCloudSearch} = require './track'

###*
  A widget to enter some message.
###
class MessageBox extends Backbone.View
  events:
    keypress: (e) ->
      return unless e.keyCode == 13 # Enter
      this.trigger 'message', this.$message.attr('value')
      this.$message.attr('value', '')
      this.hide()

  show: ->
    Backbone.trigger 'hideGame'
    this.$el.show()
    this.$message.focus()

  hide: ->
    this.$el.hide()
    Backbone.trigger 'showGame'

  render: ->
    this.$el.html """
      <input class="message" name="message" />
    """
    this.$message = this.$('.message')
    this.listenTo Backbone, 'showMessageBox', => this.show()

###*
  A widget to select song from SoundCloud.
###
class SongBox extends Backbone.View
  className: 'songbox'

  events:
    'click .exit .button': (e) ->
      e.preventDefault()
      this.remove()
    'keydown': (e) ->
      if e.keyCode == 27
        this.remove()
      else if e.keyCode == 13
        this.$query.select()

  render: ->
    this.$el.html """
      <div class="exit">
        <a class="button" href custom><i class="icon-remove"></i></a>
      </div>
      <div class="search">
        <input class="query" type="text" name="song" placeholder="search" />
      </div>
      """
    this.$query = this.$ '.query'
    this.$query.autocomplete
      focus: (e, ui) =>
        this.$query.val(ui.item.label)
      close: (e, ui) =>
        if ui.item?.trackId?
          this.trigger 'selected', ui.item.track
        this.remove()
      select: (e, ui) =>
        this.$query.val(ui.item.label)
        if ui.item?.trackId?
          this.trigger 'selected', ui.item.track
        this.remove()
      source: (request, response) =>
        soundCloudSearch request.term, (tracks) =>
          response({trackId: t.id, value: t.get('title'), track: t} for t in tracks)

  remove: ->
    Backbone.trigger 'showGame'
    super

  focus: ->
    this.$query.focus()

  @open: (cb) ->
    view = new SongBox()
    view.on 'selected', cb
    view.render()
    Backbone.trigger 'hideGame'
    $(document.body).append(view.el)
    # due to http://bugs.jqueryui.com/ticket/8858
    # fix after jQuery UI 1.10 will be released
    view.$query.autocomplete('option', 'appendTo', view.$el)
    view.focus()

module.exports = {MessageBox, SongBox}
