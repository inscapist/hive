{
  description = "Hony from The Hive";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  inputs.main.url = "path:../.";
  outputs = inputs:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux" "x86_64-darwin"] (
      system: let
        inherit (inputs.main.inputs.std) deSystemize;
        inherit
          (deSystemize system inputs)
          main
          devshell
          nixos-generators
          ;
        inherit
          (deSystemize system inputs.main.inputs)
          std
          deploy-rs
          ;
        inherit (deSystemize system std.inputs) nixpkgs;
        withCategory = category: attrset: attrset // {inherit category;};
      in {
        devShells.mellifera = devshell.legacyPackages.mkShell (
          {
            extraModulesPath,
            pkgs,
            ...
          }: {
            name = "Apis Mellifera";
            git.hooks = {
              enable = true;
              pre-commit.text = builtins.readFile ./pre-flight-check.sh;
            };
            imports = [
              std.std.devshellProfiles.default
              "${extraModulesPath}/git/hooks.nix"
            ];
            cellsFrom = "./comb";
            commands = [
              (withCategory "hexagon" {package = nixpkgs.legacyPackages.treefmt;})
              (withCategory "hexagon" {package = deploy-rs.packages.deploy-rs;})
              (withCategory "hexagon" {package = nixos-generators.defaultPackage;})
            ];
            packages = [
              # formatters
              nixpkgs.legacyPackages.alejandra
              nixpkgs.legacyPackages.nodePackages.prettier
              nixpkgs.legacyPackages.nodePackages.prettier-plugin-toml
              nixpkgs.legacyPackages.shfmt
              nixpkgs.legacyPackages.editorconfig-checker
            ];
            devshell.startup.nodejs-setuphook =
              nixpkgs.lib.stringsWithDeps.noDepEntry
              ''
                export NODE_PATH=${nixpkgs.legacyPackages.nodePackages.prettier-plugin-toml}/lib/node_modules:$NODE_PATH
              '';
          }
        );
      }
    );
}
