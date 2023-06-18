{
  description = "R packages for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          hostPlatform = system;
        });
    in
    {
      formatter = forAllSystems (system: pkgs.${system}.nixpkgs-fmt);

      packages = forAllSystems (system:
        let
          inherit (pkgs.${system}) rPackages fetchurl;

          mirror = "https://cran.r-project.org/src/contrib";

          package = { name, version, md5, depends }:
            rPackages.buildRPackage {
              name = "${name}-${version}";
              src = fetchurl {
                outputHash = md5;
                outputHashAlgo = "md5";
                urls = [
                  "${mirror}/${name}_${version}.tar.gz"
                  "${mirror}/Archive/${name}/${name}_${version}.tar.gz"
                ];
              };
              propagatedBuildInputs = depends;
              nativeBuildInputs = depends;
            };

          overrides = import ./overrides.nix { pkgs = pkgs.${system}; lib = pkgs.${system}.lib; };
          _self = import ./cran.nix { inherit self; inherit package; };
          self = _self // (overrides self _self);
        in
        self);

      devShell = forAllSystems (system:
        with pkgs.${system}; mkShell {
          buildInputs = [ R ];
        });
    };
}
