.PHONY: all build run test clean

all: build

build:
	@./scripts/build_app.sh

run: build
	@echo "✨ Launching Drift.app..."
	@open Drift.app

test:
	@swiftc -module-cache-path /tmp/clang-cache -Xcc -fmodules-cache-path=/tmp/clang-cache Sources/Models/Track.swift Sources/Models/LyricLine.swift Sources/Services/LRCParser.swift Sources/Services/LyricsService.swift Sources/Services/ColorExtractor.swift Tests/main.swift -o /tmp/run_tests && /tmp/run_tests

clean:
	@rm -rf Drift.app .build /tmp/clang-cache /tmp/run_tests
	@echo "Cleaned build artifacts."

