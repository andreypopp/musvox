Backbone = require 'backbone'
$ = require 'jquery-browserify'
Backbone.$ = $

class MessageBox extends Backbone.View
  events:
    keypress: (e) ->
      return unless e.keyCode == 13 # Enter
      e.stopPropagation()
      this.trigger 'message', this.$message.attr('value')
      this.$message.attr('value', '')
      this.hide()

  show: ->
    $('#container').hide()
    this.$el.show()
    this.$message.focus()

  hide: ->
    this.$el.hide()
    $('#container').show()

  render: ->
    this.$el.html """
      <input class="message" name="message" />
    """
    this.$message = this.$('.message')


module.exports = {MessageBox}
