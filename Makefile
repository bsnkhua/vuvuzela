APP_NAME = FIFA Widget
DIST = dist/$(APP_NAME).app

.PHONY: run build app clean

run:
	swift run FIFAWidget

build:
	swift build

app:
	swift build -c release
	rm -rf "$(DIST)"
	mkdir -p "$(DIST)/Contents/MacOS"
	cp .build/release/FIFAWidget "$(DIST)/Contents/MacOS/FIFAWidget"
	cp Resources/Info.plist "$(DIST)/Contents/Info.plist"
	mkdir -p "$(DIST)/Contents/Resources"
	codesign --force --sign - "$(DIST)"
	@echo "Done: $(DIST)"

clean:
	rm -rf .build dist
