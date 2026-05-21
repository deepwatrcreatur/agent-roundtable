{ modulesPath, ... }:

{
  imports = [
    ./vaglio-base.nix
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  boot.zfs.forceImportRoot = false;
}
