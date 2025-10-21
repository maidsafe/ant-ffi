#!/usr/bin/env zsh

set -e
set -u

# NOTE: You MUST run this every time you make changes to the core. Unfortunately, calling this from Xcode directly
# does not work so well.

# Build modes:
# - Default (no flags): Build only aarch64-apple-ios-sim for fast local development and CI
# - --full: Build all targets and create XCFramework (needed for releases)
# - --release: When used with --full, creates ZIP archive and updates Package.swift checksum
full=false
release=false

for arg in "$@"
do
    case $arg in
        --full)
            full=true
            shift
            ;;
        --release)
            release=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done
fat_simulator_lib_dir="target/ios-simulator-fat/release"
fat_macos_lib_dir="target/macos-fat/release"

generate_ffi() {
  local target_lib="$2"
  echo "Generating framework module mapping and FFI bindings from $target_lib"
  # NOTE: Convention requires the modulemap be named module.modulemap
  cargo run -p uniffi-bindgen-swift -- $target_lib target/uniffi-xcframework-staging --swift-sources --headers --modulemap --module-name $1FFI --modulemap-filename module.modulemap
  mkdir -p ../apple/Sources/UniFFI/
  mv target/uniffi-xcframework-staging/*.swift ../apple/Sources/UniFFI/
  mv target/uniffi-xcframework-staging/module.modulemap target/uniffi-xcframework-staging/module.modulemap
}

create_fat_simulator_lib() {
  echo "Creating a fat library for x86_64 and aarch64 simulators"
  mkdir -p $fat_simulator_lib_dir
  lipo -create target/x86_64-apple-ios/release/lib$1.a target/aarch64-apple-ios-sim/release/lib$1.a -output $fat_simulator_lib_dir/lib$1.a
}

create_fat_macos_lib() {
  echo "Creating a fat library for x86_64 and aarch64 macOS"
  mkdir -p $fat_macos_lib_dir
  lipo -create target/x86_64-apple-darwin/release/lib$1.a target/aarch64-apple-darwin/release/lib$1.a -output $fat_macos_lib_dir/lib$1.a
}

build_xcframework() {
  # Builds an XCFramework
  echo "Generating XCFramework"
  rm -rf target/ios  # Delete the output folder so we can regenerate it
  xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios/release/lib$1.a -headers target/uniffi-xcframework-staging \
    -library target/ios-simulator-fat/release/lib$1.a -headers target/uniffi-xcframework-staging \
    -library target/macos-fat/release/lib$1.a -headers target/uniffi-xcframework-staging \
    -output target/ios/lib$1-rs.xcframework

  if $release; then
    echo "Building xcframework archive"
    ditto -c -k --sequesterRsrc --keepParent target/ios/lib$1-rs.xcframework target/ios/lib$1-rs.xcframework.zip
    checksum=$(swift package compute-checksum target/ios/lib$1-rs.xcframework.zip)
    version=$(cargo metadata --format-version 1 | jq -r --arg pkg_name "$1" '.packages[] | select(.name==$pkg_name) .version')
    sed -i "" -E "s/(let releaseTag = \")[^\"]+(\")/\1$version\2/g" ../Package.swift
    sed -i "" -E "s/(let releaseChecksum = \")[^\"]+(\")/\1$checksum\2/g" ../Package.swift
  fi
}

basename=ant-ffi
basename_underscore=ant_ffi

# Set deployment targets to match Package.swift requirements
export IPHONEOS_DEPLOYMENT_TARGET=16.0
export MACOSX_DEPLOYMENT_TARGET=10.15

if $full; then
  echo "Building all targets for full XCFramework..."
  cargo build -p $basename --lib --release --target x86_64-apple-ios
  cargo build -p $basename --lib --release --target aarch64-apple-ios-sim
  cargo build -p $basename --lib --release --target aarch64-apple-ios
  cargo build -p $basename --lib --release --target x86_64-apple-darwin
  cargo build -p $basename --lib --release --target aarch64-apple-darwin

  generate_ffi $basename_underscore "target/aarch64-apple-ios/release/lib$basename_underscore.a"
  create_fat_simulator_lib $basename_underscore
  create_fat_macos_lib $basename_underscore
  build_xcframework $basename_underscore
else
  echo "Building simulator target only (fast mode)..."
  cargo build -p $basename --lib --release --target aarch64-apple-ios-sim
  generate_ffi $basename_underscore "target/aarch64-apple-ios-sim/release/lib$basename_underscore.a"
  echo "Done! Swift bindings generated in ../apple/Sources/UniFFI/"
  echo "For full XCFramework build, use: ./build-ios.sh --full"
fi
