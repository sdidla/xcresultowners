localbin ?= /usr/local/bin

install:
	swift build -c release --disable-sandbox
	install -d "$(localbin)"
	install ".build/release/xcresultowners" "$(localbin)"

uninstall:
	rm -rf "$(localbin)/xcresultowners"

clean:
	rm -rf .build

.PHONY: install uninstall clean
