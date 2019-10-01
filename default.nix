let
  commonLib = import ./lib.nix;
in
{ cardanoNodeRevOverride ? null
, ...
}:
let
  sources = commonLib.sources;
  cardano-node-pkgs = import (sources.cardano-node.revOverride cardanoNodeRevOverride) {};
in {
  inherit (cardano-node-pkgs.nix-tools.exes) cardano-node;
}
