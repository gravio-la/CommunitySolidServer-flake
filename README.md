CommunitySolidServer Nix Flake
==============================

This Nix Flake provides a package and a NixOS module for the [CommunitySolidServer](https://solidcommunity.be/community-solid-server/), a node.js based server that implements the Solid specification. The Solid specification is a framework for decentralized social networking, allowing users to own and control their own data.
The project describes itself as an "open software that provides you with a [Solid](https://solidproject.org/) Pod and identity. That Pod acts as your own personal storage space so you can share data with people and Solid applications."

To use this Nix Flake, you will need to have [Nix](https://nixos.org/nix/) and optionally, to use the module [NixOS](https://nixos.org/) installed on your system.

Installation
------------

To install the CommunitySolidServer package and NixOS module, you can add the following lines to your `flake.nix` file:

```
{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    community-solid-server = {
      url = "github:gravio-la/CommunitySolidServer.nix#main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, community-solid-server }:
  let
    system = "x86_64-linux";
    pkgs =  import nixpkgs {
      inherit system;
    };
  in
  rec {
    nixosConfigurations = {
      sampleHost = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          community-solid-server.nixosModules.default
          {
            services.solid-server = {
              enable = true;
            };
          }
        ];
      };
    };
  }
}
```

NixOS Container
---------------

This flake provides a preconfigured container to test and avaluate the CommunitySolidServer.

look at the Makefile targets to see how to operate on them

`nixos-rebuild`: This target rebuilds the NixOS container for the solidserver service using the `nixos-container update` command.

`nixos-create`: This target creates a new NixOS container for the solidserver service using the `nixos-container create` command.

`nixos-update`: This target updates the solidserver service by stopping the current container, rebuilding the container, and starting the new container.

`nixos-stop`: This target stops the solidserver service by using the `nixos-container stop` command.

`nixos-start`: This target starts the solidserver service by using the `nixos-container start` command.

`nixos-login`: This target starts the solidserver service and logs in to the container using the `nixos-container root-login` command.

`nixos-destroy`: This target destroys the solidserver service container using the `nixos-container destroy` command.


Configuration
-------------

The CommunitySolidServer NixOS module provides a number of options for configuring the server. These options can be set in the `services.solid-server` attribute in your `configuration.nix` file.

Here is a description of each option:

-   `enable`: A boolean option that enables or disables the CommunitySolidServer service.
-   `package`: The Solid server package to use.
-   `port`: The TCP port on which the server should listen.
-   `baseUrl`: The base URL used internally to generate URLs.
-   `socket`: The Unix Domain Socket on which the server should listen.
-   `loggingLevel`: The detail level of logging.
-   `configFile`: The configuration file for the server.
-   `rootFilePath`: The root folder where the server stores data when using a file-based configuration.
-   `sparqlEndpoint`: The URL of the SPARQL endpoint when using a quadstore-based configuration.
-   `showStackTrace`: A boolean option that enables or disables detailed logging on error output.
-   `podConfigJson`: The path to the file that keeps track of dynamic Pod configurations.
-   `seededPodConfigJson`: The path to the file that keeps track of seeded Pod configurations.
-   `mainModulePath`: The path from which Components.js will start its lookup when initializing configurations.
-   `workers`: An integer option that sets the number of workers to use in multithreaded mode.

For example, to change the port that the server listens on, you can set the `port` option in your `configuration.nix` file:


```
{

  services.solid-server = {
    enable = true;
    package = pkgs.solid-server;
    port = 4000;
  };
}
```

Running the CommunitySolidServer
--------------------------------

Once the CommunitySolidServer package and NixOS module are installed and configured, you can start the server by running the following command:


`systemctl start solid-server`

To stop the server, use the `stop` command instead:


`systemctl stop solid-server`

Contributing
------------

If you would like to contribute to this Nix Flake,  please feel free to submit a pull request on GitHub.
