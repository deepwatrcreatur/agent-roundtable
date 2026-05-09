{ pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "vaglio-installer";

  services.openssh.enable = true;
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIB4ELcnxIV0zujIJ4EPubU5nkKPV7G8pZ3tDDjZ6pXI deepwatrcreatur@gmail.com"
  ];

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
