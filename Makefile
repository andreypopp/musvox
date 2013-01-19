all: run

run:
	@./node_modules/browservefy/bin/browservefy lib/app.js 8080 -- -d

install:
	npm $@
