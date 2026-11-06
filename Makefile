.PHONY: pages clean publish

pages: clean
	./build.sh

clean:
	rm -rf public/

publish: pages
	@echo "🚀 Deploying to GitHub Pages..."
	#redacted due to AI coding
	@echo "✅ Deployment complete!"

