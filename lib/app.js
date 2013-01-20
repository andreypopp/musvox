require('./soundmanager2');
soundManager.setup({url: "lib/swf", debugMode: false, onready: function() {
	require('jquery-browserify')(function() {
		require('./game');
	});
}});

