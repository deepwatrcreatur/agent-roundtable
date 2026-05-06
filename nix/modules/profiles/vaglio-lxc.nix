{ lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  networking.hostName = "vaglio";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  users.users.vaglio = {
    isNormalUser = true;
    description = "Standalone Vaglio maintainer account";
    extraGroups = [ "wheel" ];
    shell = pkgs.bashInteractive;
  };

  environment.systemPackages = with pkgs; [
    bashInteractive
    curl
    git
    gh
    dolt
    jujutsu
    tmux
  ];

  services.roundtable = {
    enable = true;
    enableTuiTooling = true;
    phoenixHost = "localhost";
  };

  system.stateVersion = lib.mkDefault "25.11";
}
