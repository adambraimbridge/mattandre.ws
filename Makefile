include n.Makefile

build build-production:
	rm -rf public
	hexo generate
	@$(MAKE) $@-super

run:
	static public

watch:
	@$(MAKE) watch-super watch-hexo -j2

watch-hexo:
	hexo generate --watch

test: verify

deploy:
	s3up --strip 1 --region eu-west-1 --cache-control 's-maxage=31536000, max-age=300' --bucket mattandre.ws `find . -path "./public/*"`
