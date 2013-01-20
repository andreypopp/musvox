require('./soundmanager2');
soundManager.setup({url: "lib/swf", debugMode: false});

require('jquery-browserify')(function() {
	require('./game');
});
