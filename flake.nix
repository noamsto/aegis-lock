{
  description = "Aegis Lock — standalone Wayland lockscreen with fingerprint support";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Flake-level outputs (not per-system)
      flake = {
        overlays.default = final: prev: {
          aegis-lock = final.callPackage ./nix/package.nix {
            version =
              let
                mkDate =
                  longDate:
                  final.lib.concatStringsSep "-" [
                    (builtins.substring 0 4 longDate)
                    (builtins.substring 4 2 longDate)
                    (builtins.substring 6 2 longDate)
                  ];
              in
              mkDate (inputs.self.lastModifiedDate or "19700101") + "_" + (inputs.self.shortRev or "dirty");
          };
        };

        homeModules.default =
          {
            pkgs,
            lib,
            ...
          }:
          {
            imports = [ ./nix/home-module.nix ];
            programs.aegis-lock.package =
              lib.mkDefault
                inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          };
      };

      perSystem =
        { pkgs, system, ... }:
        let
          pkgsWithOverlay = pkgs.appendOverlays [ inputs.self.overlays.default ];
        in
        {
          formatter = pkgs.nixfmt;

          packages.default = pkgsWithOverlay.aegis-lock;

          devShells.default = pkgs.callPackage ./nix/shell.nix { };
        };
    };
}
