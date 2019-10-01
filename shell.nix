{ commonLib ? import ./lib.nix
, pkgs ? commonLib.pkgs
}:

let
  iohkpkgs = import ./default.nix {};
  shell = pkgs.mkShell {
    name = "io";
    buildInputs = with pkgs; [
      iohkpkgs.cardano-node
      pkgs.jq
    ];
    shellHook = ''
      cat <<EOF
      Try this:

        cardano-cli --help

      EOF
  '';
  };
in shell
