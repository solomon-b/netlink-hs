{
  inputs = {
    git-ignore-nix.url = "github:hercules-ci/gitignore.nix/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, git-ignore-nix }:
    let
      overlay = final: prev: {
        haskellPackages = prev.haskellPackages.override (old: {
          overrides = prev.lib.composeExtensions (old.overrides or (_: _: { }))
            (hself: hsuper: {
              netlink-hs = hself.callCabal2nix "netlink-hs"
                (git-ignore-nix.lib.gitignoreSource ./.) { };
            });
        });
      };
      overlays = [ overlay ];
    in flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system overlays; };
      in rec {
        devShell = pkgs.haskellPackages.shellFor {
          packages = p: [ p.netlink-hs ];
          buildInputs = with pkgs; [
            haskellPackages.cabal-install
            haskellPackages.haskell-language-server
          ];

        };
        defaultPackage = pkgs.haskellPackages.netlink-hs;
      }) // {
        inherit overlay overlays;
      };
}
