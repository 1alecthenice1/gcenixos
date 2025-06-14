{
  description = "NixOS for GCP ARM64 (T2A)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko }: {
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      modules = [
        disko.nixosModules.disko
        ({ config, pkgs, lib, ... }: {
          imports = [ "${nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix" ];

          # Override the Google Cloud filesystem config to use disko devices
          fileSystems."/".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";

          # Proper UEFI boot configuration
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;

          # Add disko configuration with EFI boot partition
          disko.devices = {
            disk = {
              main = {
                type = "disk";
                device = "/dev/nvme0n1";
                content = {
                  type = "gpt";
                  partitions = {
                    boot = {
                      size = "1G";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                      };
                    };
                    root = {
                      size = "100%";
                      content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/";
                        extraArgs = [ "-L" "nixos" ];
                      };
                    };
                  };
                };
              };
            };
          };

          services.openssh.enable = true;
          
          users.users.builder = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5D+e6WddHeNM1eYZRSeQg57JvFZg6KhofgPP3aKvpc aleckillian44@proton.me"
            ];
          };

          security.sudo.wheelNeedsPassword = false;
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          
          system.stateVersion = "24.11";
        })
      ];
    };
  };
}
