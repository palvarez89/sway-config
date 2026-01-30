{
  description = "Home Manager configuration of pedro";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixGL.url = "github:guibou/nixGL";
  };

  outputs =
    { nixpkgs, home-manager, nixGL,... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = { username, homeDirectory, stateVersion}:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = stateVersion;
            }
            ./home.nix
          ];
          extraSpecialArgs = { inherit nixGL; };
        };
    in
    {
      homeConfigurations = {

        pedroalvarez = mkHome {
          username = "pedroalvarez";
          homeDirectory = "/home/pedroalvarez";
          stateVersion = "23.11";
        };

        pedro = mkHome {
          username = "pedro";
          homeDirectory = "/home/pedro";
          stateVersion = "25.05";
        };
      };
    };
}
