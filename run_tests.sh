#!/bin/bash

# Requires homebrew and xctool
# Ignore the exit code, proceed to run tests whether succeeded or not
echo "Attempting to update xctool..."
brew update
brew upgrade xctool

WORKSPACE_PATH=RZAutoImport.xcworkspace
SCHEME_NAME=RZAutoImportTests

# tests only run for iOS7+ since they use XCTest
TEST_SDKS=( iphonesimulator7.1 iphonesimulator7.0 )

for SDK in "${TEST_SDKS[@]}"
do
	xctool -workspace "$WORKSPACE_PATH" -scheme "$SCHEME_NAME" -sdk "$SDK" test
done
