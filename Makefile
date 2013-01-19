all: run

run:
	@./node_modules/browservefy/bin/browservefy lib/app.js 8080 -- -d

run-ws:
	@coffee lib/server.coffee

install:
	npm $@
