var createGame = require('./game');

var game = window.game = createGame();
var container = document.querySelector('#container');

game.appendTo('#container');

container.addEventListener('click', function() {
  game.requestPointerLock(container);
});
