{
  description = "Ema template app";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";

    # Haskell overrides
    ema.url = "github:srid/ema/master";
    ema.flake = false;
    tailwind-haskell.url = "github:srid/tailwind-haskell";
    tailwind-haskell.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, haskell-flake, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        haskell-flake.flakeModule
      ];
      perSystem = { self', config, inputs', pkgs, ... }: {
        # "haskellProjects" comes from https://github.com/srid/haskell-flake
        haskellProjects.default = {
          packages.ema-template.root = ./.;
          haskellPackages = pkgs.haskell.packages.ghc924;
          buildTools = hp: {
            inherit (pkgs)
              treefmt
              nixpkgs-fmt
              foreman;
            inherit (pkgs.haskellPackages)
              cabal-fmt;
            inherit (hp)
              fourmolu;
            inherit (inputs'.tailwind-haskell.packages)
              tailwind;

            # https://github.com/NixOS/nixpkgs/issues/140774 reoccurs in GHC 9.2
            ghcid = pkgs.haskell.lib.overrideCabal hp.ghcid (drv: {
              enableSeparateBinOutput = false;
            });
          };
          source-overrides = {
            ema = inputs.ema + /ema;
            ema-generics = inputs.ema + /ema-generics;
            ema-extra = inputs.ema + /ema-extra;
          };
          overrides = self: super: with pkgs.haskell.lib; {
            inherit (inputs'.tailwind-haskell.packages)
              tailwind;
            type-errors-pretty = dontCheck (doJailbreak super.type-errors-pretty);
            relude = dontCheck (self.callHackage "relude" "1.1.0.0" { }); # 1.1 not in nixpkgs yet 
            retry = dontCheck super.retry; # For GHC 9.2.
            streaming-commons = dontCheck super.streaming-commons; # Fails on darwin
            http2 = dontCheck super.http2; # Fails on darwin
            hls-explicit-fixity-plugin = dontCheck super.hls-explicit-fixity-plugin;
          };
        };
        packages.default = config.packages.ema-template;
        apps.tailwind.program = inputs'.tailwind-haskell.packages.tailwind;
      };
    };
}
