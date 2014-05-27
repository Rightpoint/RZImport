#!/bin/bash
# Requires xctool

PROJ_PATH=Example/RZAutoImport.xcodeproj
SCHEME_NAME=RZAutoImportTests

# tests only run for iOS7+ since they use XCTest
TEST_SDKS=( iphonesimulator7.1 iphonesimulator7.0 )

for SDK in "${TEST_SDKS[@]}"
do
    xctool -project "$PROJ_PATH" -scheme "$SCHEME_NAME" -sdk "$SDK" run-tests
done