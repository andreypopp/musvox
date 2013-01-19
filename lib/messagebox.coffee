Backbone = require './backbone'

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


module.exports = {MessageBox}
