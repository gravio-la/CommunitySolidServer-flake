nixos-rebuild:
	sudo nixos-container update solidserver --flake .#container

nixos-create: 
	sudo nixos-container create solidserver --system-path `realpath container` --flake .#container

nixos-update: nixos-stop nixos-rebuild nixos-start

nixos-stop:
	sudo nixos-container stop solidserver

nixos-start:
	sudo nixos-container start solidserver

nixos-login: nixos-start
	sudo nixos-container root-login solidserver

nixos-destroy:
	sudo nixos-container destroy solidserver
