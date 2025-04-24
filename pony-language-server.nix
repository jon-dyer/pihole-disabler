{
  stdenv,
  pkgs,
# ponyc,
# pony-corral,
}:
let
  name = "pony-language-server";
in
stdenv.mkDerivation {
  inherit name;
  version = "0.2.2";

  srcs = [
    (pkgs.fetchFromGitHub {
      owner = "ponylang";
      repo = "pony-language-server";
      rev = "81135a7fb66d578549afdfb971b0cc8d07cca0a3";
      hash = "sha256-KGotqa4Y1xOWwGg64tfczSjPUcLOUj/eX5G1WONbjVk=";
      # fetchSubmodules = true;
    })
    (pkgs.fetchFromGitHub {
      name = "peg";
      owner = "ponylang";
      repo = "peg";
      rev = "c7466f10533f3675013a67f5f1cae4b223edd94b";
      hash = "sha256-MiA6DRmE7iOpMWAnKy2RXI1mbdYQnJctE5/D2U5VT2c=";
    })
    (pkgs.fetchFromGitHub {
      name = "immutable-json";
      owner = "mfelsche";
      repo = "pony-immutable-json";
      rev = "0bc55215beb3c7de0ebb5c60c889e5979e988b72";
      hash = "sha256-jHXoVB216ywz3h6V5zOkcF9NHAYxM7/yVPXm8ldcWw4=";
    })
    (pkgs.fetchFromGitHub {
      name = "ast";
      owner = "mfelsche";
      repo = "pony-ast";
      rev = "684b0506f81f8a29d27e70df3e5ea581c6157e37";
      hash = "sha256-AhE1Cw5l3F1ZUFvMjqvFZ2vFF/ZsegoJZUEgmFl6lmY=";
    })
    (pkgs.fetchFromGitHub {
      name = "binarysearch";
      owner = "mfelsche";
      repo = "pony-binarysearch";
      rev = "9c59382f02d68be96d19b439d8c37f913a8d3fed";
      hash = "sha256-Gx3feaH9teCX/PJltSOsl6BAuUBk0yZKls5rGf/8DHk=";
    })
  ];
  sourceRoot = ".";

  prePatch = ''
    cd source
  '';

  patches = [
    ./nofetch.patch
  ];

  nativeBuildInputs = [ ];
  buildInputs = [
    pkgs.ponyc
    pkgs.pony-corral
    # (pkgs.callPackage ./default.nix { })
    # (pkgs.callPackage ./pony-corral.nix { })
  ];

  buildPhase = ''
    mkdir _corral
    mv ../immutable-json _corral/github_com_mfelsche_pony_immutable_json
    mv ../ast _corral/github_com_mfelsche_pony_ast
    mv ../peg _corral/github_com_ponylang_peg
    mv ../binarysearch _corral/github_com_mfelsche_pony_binarysearch
    make language_server
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp build/release/pony-lsp $out/bin/pony-lsp
  '';
}
