{
  description = "A Cargo subcommand for competitive programming.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-flake = {
      url = "github:juspay/rust-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.rust-flake.flakeModules.default
        inputs.rust-flake.flakeModules.nixpkgs
      ];

      perSystem =
        { config, self', pkgs, lib, ... }:
        {
          rust-project = {
            crates.cargo-compete = {
              crane.args = {
                buildInputs = [ pkgs.openssl ];
                doCheck = false;
              };
            };
            src = lib.cleanSourceWith {
              src = inputs.self;
              filter = path: type:
                config.rust-project.crane-lib.filterCargoSources path type
                || lib.hasInfix "resources" path;
            };
          };
          packages.default = self'.packages.cargo-compete;
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              taplo.enable = true;
              nixfmt.enable = true;
              rustfmt.enable = true;
            };
          };
        };
    };
}
