APP_NAME = Vuvuzela
DIST = dist/$(APP_NAME).app

.PHONY: run build app clean

run:
	swift run Vuvuzela

build:
	swift build

app:
	swift build -c release
	rm -rf "$(DIST)"
	mkdir -p "$(DIST)/Contents/MacOS"
	cp .build/release/Vuvuzela "$(DIST)/Contents/MacOS/Vuvuzela"
	cp Resources/Info.plist "$(DIST)/Contents/Info.plist"
	mkdir -p "$(DIST)/Contents/Resources"
	@if [ -f Resources/AppIcon.icns ]; then cp Resources/AppIcon.icns "$(DIST)/Contents/Resources/AppIcon.icns"; fi
	codesign --force --sign - "$(DIST)"
	@echo "Done: $(DIST)"

clean:
	rm -rf .build dist
