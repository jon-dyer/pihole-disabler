{
  description = "new flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=pull/396553/head";
    dev.url = "github:dyercode/dev";
  };

  outputs =
    {
      self,
      nixpkgs,
      dev,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          ponyc
          pony-corral
          openssl_3
          dev.packages.${system}.default
          (pkgs.callPackage ./pony-language-server.nix { })
        ];

        shellHook = ''
          export PIHOLE_BASE_URL="https://example.org/"
          export PIHOLE_PASS="super reall password"
          export PIHOLE_TIMER_SEC="10"
        '';
      };
    };
}
