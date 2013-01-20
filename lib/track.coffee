$ = require 'jquery-browserify'
Backbone = require './backbone'

###*
  Data model for audio tracks.
  Currently only suppors SoundCloud tracks via "soundcloud:XXXXXX" ids.
###
class Track extends Backbone.Model
  url: ->
    [type, id] = this.id.split(':')
    if type == 'soundcloud'
      "http://api.soundcloud.com/tracks/#{id}/stream?client_id=609ae0b573913db156968e0ec38c1e26"
    else
      throw new Error("invalid track type: #{type}")

###*
  Search SoundCloud for tracks with `q` query.

  @param {string} q - search query
  @param {function} cb - callback to fire with an array of results
###
soundCloudSearch = (q, cb) ->
  $.ajax
    url: 'https://api.soundcloud.com/tracks.json'
    data:
      q: q
      limit: 5
      client_id: '609ae0b573913db156968e0ec38c1e26'
    success: (tracks) ->
      tracks = for t in tracks
        new Track
          id: "soundcloud:#{t.id}"
          title: t.title
      cb(tracks)

module.exports = {Track, soundCloudSearch}
