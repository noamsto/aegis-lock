{
  version ? "dirty",
  lib,
  stdenvNoCC,
  qt6,
  quickshell,
}:
let
  src = lib.cleanSourceWith {
    src = ../.;
    filter =
      path: type:
      !(builtins.any (prefix: lib.path.hasPrefix (../. + prefix) (/. + path)) [
        /.git
        /.github
        /.gitignore
        /nix
        /flake.nix
        /flake.lock
        /CLAUDE.md
      ]);
  };
in
stdenvNoCC.mkDerivation {
  pname = "aegis-lock";
  inherit version src;

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
  ];

  installPhase = ''
    mkdir -p $out/share/aegis-lock $out/bin
    cp -r . $out/share/aegis-lock
    ln -s ${quickshell}/bin/qs $out/bin/aegis-lock
  '';

  preFixup = ''
    qtWrapperArgs+=(
      --add-flags "-p $out/share/aegis-lock"
      --set AEGIS_LOCK 1
    )
  '';

  meta = {
    description = "Standalone Wayland lockscreen with fingerprint authentication";
    license = lib.licenses.mit;
    mainProgram = "aegis-lock";
  };
}
