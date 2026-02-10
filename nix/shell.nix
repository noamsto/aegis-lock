{
  quickshell,
  nixfmt,
  statix,
  deadnix,
  jsonfmt,
  shellcheck,
  kdePackages,
  fprintd,
  playerctl,
  mkShellNoCC,
}:
mkShellNoCC {
  packages = [
    quickshell

    # nix
    nixfmt
    statix
    deadnix

    # json
    jsonfmt

    # shell
    shellcheck

    # QML tooling (qmlfmt, qmllint, qmlls)
    kdePackages.qtdeclarative

    # runtime deps for testing
    fprintd
    playerctl
  ];

  shellHook = ''
    export AEGIS_PROJECT_DIR="$(pwd)"

    echo "aegis-lock dev shell"
    echo "  run:    qs -p .                    (preview mode — safe)"
    echo "  debug:  AEGIS_DEBUG=1 qs -p .      (preview + debug logging)"
    echo "  lock:   AEGIS_LOCK=1 qs -p .       (real session lock — use with caution)"
  '';
}
