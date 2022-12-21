{
  description = "An open and modular implementation of the Solid specifications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-npm-buildPackage.url = "github:serokell/nix-npm-buildpackage";
    nix-npm-buildPackage.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, flake-utils, nix-npm-buildPackage }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      bp = pkgs.callPackage nix-npm-buildPackage { nodejs = pkgs.nodejs-14_x; };
      # https://github.com/CommunitySolidServer/CommunitySolidServer.git
      src = pkgs.fetchFromGitHub {
        owner = "CommunitySolidServer";
        repo = "CommunitySolidServer";
        rev = "v5.1.0";
        sha256 = "sha256-K38rtRJhV7CyR8cRjjwpTl9uX00lfDa1z2867f63axc=";
      };
    in {

        packages.default = bp.buildNpmPackage {
          name = "solid-server";
          src = src;
          packageJSON = "${src}/package.json";
          packageLockJSON = "${src}/package-lock.json";
          buildInputs = with pkgs; [ nodejs nodePackages.typescript ];
        };

        apps.default = {
          type = "app";
          program = "${self.packages.default}/bin/server";
        };

        nixosModules.default = { config, lib, ...}: {
          options.services.solid-server = {
            enable = lib.mkEnableOption "enable Solid server";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${system}.default;
              defaultText = "pkgs.solid-server";
              description = "The Solid server package to use.";
            };
            port = lib.mkOption {
              type = lib.types.port;
              default = 3000;
              description = "The TCP port on which the server should listen.";
            };
            baseUrl = lib.mkOption {
              type = lib.types.str;
              default = "http://localhost:${toString config.services.solid-server.port}/";
              description = "The base URL used internally to generate URLs. Change this if your server does not run on `http://localhost:$PORT/`.";
            };
            socket = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "The Unix Domain Socket on which the server should listen. `--baseUrl` must be set if this option is provided";
            };
            loggingLevel = lib.mkOption {
              type = lib.types.enum [ "error" "warn" "info" "verbose" "debug" "silly" ];
              default = "info";
              description = "The detail level of logging; useful for debugging problems. Use `debug` for full information.";
            };
            configFile = lib.mkOption {
              type = lib.types.path;
              default = "${self.packages.${system}.default}/config/default.json";
              description = "The configuration(s) for the server. The default only stores data in memory; to persist to your filesystem, use `@css:config/file.json`";
            };
            rootFilePath = lib.mkOption {
              type = lib.types.path;
              default = "./";
              description = "Root folder where the server stores data, when using a file-based configuration.";
            };
            sparqlEndpoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "URL of the SPARQL endpoint, when using a quadstore-based configuration.";
            };
            showStackTrace = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enables detailed logging on error output.";
            };
            podConfigJson = lib.mkOption {
              type = lib.types.path;
              default = "${self.packages.${system}.default}/pod-config.json";
              description = "Path to the file that keeps track of dynamic Pod configurations. Only relevant when using `@css:config/dynamic.json`.";
            };
            seededPodConfigJson = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Path to the file that keeps track of seeded Pod configurations.";
            };
            mainModulePath = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Path from where Components.js will start its lookup when initializing configurations.";
            };
            workers = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.unsigned;
              default = 1;
              description = "Run in multithreaded mode using workers. Special values are `-1` (scale to `num_cores-1`), `0` (scale to `num_cores`) and 1 (singlethreaded).";
            };
          };
          config = {
            systemd.services.solid-server = let
              cfg = config.services.solid-server;
            in {
              description = "Solid server";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              enable = cfg.enable;
              serviceConfig = {
                ExecStart = ''
                  ${cfg.package}/bin/server \
                    --port ${toString cfg.port} \
                    --baseUrl ${cfg.baseUrl} \
                    ${lib.optionalString (cfg.socket != null) "--socket ${cfg.socket}"} \
                    --loggingLevel ${cfg.loggingLevel} \
                    --config ${cfg.configFile} \
                    ${lib.optionalString (cfg.rootFilePath != null) "--rootFilePath ${cfg.rootFilePath}"} \
                    ${lib.optionalString (cfg.sparqlEndpoint != null) "--sparqlEndpoint ${cfg.sparqlEndpoint}"} \
                    ${lib.optionalString cfg.showStackTrace "--showStackTrace"} \
                    ${lib.optionalString (cfg.podConfigJson != null) "--podConfigJson ${cfg.podConfigJson}"} \
                    ${lib.optionalString (cfg.seededPodConfigJson != null) "--seededPodConfigJson ${cfg.seededPodConfigJson}"} \
                    ${lib.optionalString (cfg.mainModulePath != null) "--mainModulePath ${cfg.mainModulePath}"}
                  '';
                Restart = "on-failure";
              };
          };
        };
      };

      devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ gnumake ];
      };
    }) // {
    nixosConfigurations.container = 
      let 
        system = "x86_64-linux"; 
        port = 4000;
        localAddress = "10.233.3.2";
        hostAddress = "10.233.3.1";
      in {
        inherit localAddress hostAddress;
        privateNetwork = true;
      } // nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ({ pkgs, lib, ... }: {
          imports = [ self.nixosModules.${system}.default ];
          boot.isContainer = true;
          networking.useDHCP = false;
          networking.firewall.enable = true;
          networking.firewall.allowedTCPPorts = [ port ];
          services.solid-server = {
            inherit port;
            enable = true;
            baseUrl = "http://${localAddress}:${toString port}/";
            rootFilePath = "/data";
          };
      }) ];
    };
  };
}
