{
  description = "Aegis Lock - standalone Wayland lockscreen with fingerprint support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux;
      pkgsFor = eachSystem (
        system: nixpkgs.legacyPackages.${system}.appendOverlays [ self.overlays.default ]
      );
    in
    {
      formatter = eachSystem (system: pkgsFor.${system}.nixfmt);

      packages = eachSystem (system: {
        default = pkgsFor.${system}.aegis-lock;
      });

      overlays = {
        default = final: prev: {
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
              mkDate (self.lastModifiedDate or "19700101") + "_" + (self.shortRev or "dirty");
          };
        };
      };

      devShells = eachSystem (system: {
        default = pkgsFor.${system}.callPackage ./nix/shell.nix { };
      });

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
              self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
    };
}
