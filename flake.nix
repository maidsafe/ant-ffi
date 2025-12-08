{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # Add components to the toolchain TOML file.
        toolchain =
          let toml = (builtins.fromTOML (builtins.readFile ./rust/rust-toolchain.toml)).toolchain; in
          pkgs.rust-bin.fromRustupToolchain {
            inherit (toml) channel profile targets;
            # For IDE support
            components = toml.components ++ [ "rust-src" "rust-analyzer-preview" ];
          };

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "34" "35" "36" ];
          buildToolsVersions = [ "34.0.0" "35.0.0" "36.0.0" ];
          systemImageTypes = [ "google_apis_playstore" ];
          abiVersions = [ "armeabi-v7a" "arm64-v8a" "x86" "x86_64" ];
          includeNDK = true;
          includeExtras = [ "extras;google;auto" ];
          includeEmulator = true;
          includeSystemImages = true;
        };
      in
      {
        # For `nix develop`:
        devShell = pkgs.mkShell
          ({
            nativeBuildInputs = with pkgs; [
              # Fixes a broken bash shell (e.g. no autocomplete)
              bashInteractive
              # Rust tools
              toolchain
            ] ++ pkgs.lib.optionals (pkgs.hostPlatform.isLinux) [
              # Android
              gradle_9
              jdk # For gradle(w)
              ktlint
              ktfmt
              cargo-ndk
              androidComposition.androidsdk
              (android-studio.withSdk (androidComposition.androidsdk))
            ];

            RUSTFLAGS = builtins.concatStringsSep " " [
              # Debug information is slow to generate and makes the binary larger
              "-C strip=debuginfo"
              "-C debuginfo=0"
            ];

            # Required as `autonomi` depends on `protoc` somewhere in the build phase.
            PROTOC = "${pkgs.protobuf}/bin/protoc";
          } // pkgs.lib.optionalAttrs (pkgs.hostPlatform.isLinux) {
          # override the aapt2 that gradle uses with the nix-shipped version
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidComposition.androidsdk}/libexec/android-sdk/build-tools/36.0.0/aapt2";
          ANDROID_NDK_HOME = "${androidComposition.androidsdk}/libexec/android-sdk/ndk-bundle";
          ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
        });
      }
    );
}
