{
  description = "rust-template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:DarkKirb/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    cargo2nix = {
      url = "github:DarkKirb/cargo2nix/release-0.11.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.rust-overlay.follows = "rust-overlay";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
    cargo2nix,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [
        cargo2nix.overlays.default
        (import rust-overlay)
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      rustPkgs = pkgs.rustBuilder.makePackageSet {
        packageFun = import ./Cargo.nix;
        rustChannel = "stable";
        rustVersion = "latest";
        packageOverrides = pkgs:
          pkgs.rustBuilder.overrides.all;
      };
    in rec {
      devShells.default = with pkgs;
        mkShell {
          buildInputs = [
            (rust-bin.stable.latest.default.override {
              extensions = ["rust-src"];
            })
            cargo2nix.packages.${system}.cargo2nix
            pkgconfig
            wayland
            udev
            libseat
            capnproto
            openjdk11
          ];
          LIBCLANG_PATH = pkgs.lib.makeLibraryPath [pkgs.llvmPackages.libclang.lib];
        };
      packages = {
        racwm = rustPkgs.workspace.racwm {};
      };
      nixosModules.default = import ./nixos {
        inherit inputs system;
      };
      hydraJobs = packages;
      formatter = pkgs.alejandra;
    });
}
