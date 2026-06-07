FRAMEWORKS = /Library/Developer/CommandLineTools/Library/Developer/Frameworks
TESTFLAGS = -Xswiftc -F -Xswiftc $(FRAMEWORKS)

APP_NAME = Vuvuzela
DIST = dist/$(APP_NAME).app

.PHONY: run build test app clean

run:
	swift run Vuvuzela

build:
	swift build

# make test            — run all tests
# make test FILTER=Foo — run only suites/tests matching FILTER
test:
	swift test $(TESTFLAGS) $(if $(FILTER),--filter $(FILTER))

app:
	swift build -c release
	rm -rf "$(DIST)"
	mkdir -p "$(DIST)/Contents/MacOS"
	mkdir -p "$(DIST)/Contents/Resources"
	mkdir -p "$(DIST)/Contents/Frameworks"
	cp .build/release/Vuvuzela "$(DIST)/Contents/MacOS/Vuvuzela"
	cp -R .build/release/Sparkle.framework "$(DIST)/Contents/Frameworks/Sparkle.framework"
	install_name_tool -add_rpath "@executable_path/../Frameworks" "$(DIST)/Contents/MacOS/Vuvuzela"
	cp Resources/Info.plist "$(DIST)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(DIST)/Contents/Resources/AppIcon.icns"
	cp Resources/vuvuzela-menubar.png "$(DIST)/Contents/Resources/vuvuzela-menubar.png"
	codesign --force --sign - "$(DIST)/Contents/Frameworks/Sparkle.framework"
	codesign --force --sign - "$(DIST)"
	@echo "Done: $(DIST)"

clean:
	rm -rf .build dist
