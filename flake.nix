{
  description = "NixOS for GCP ARM64 (T2A)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";  # Match your Pi flake

  outputs = { self, nixpkgs }: {
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      modules = [
        ({ config, pkgs, ... }: {
          imports = [ "${nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix" ];

          boot.loader.grub.enable = false;
          boot.loader.generic-extlinux-compatible.enable = true;

          services.qemuGuest.enable = true;
          services.openssh.enable = true;

          users.users.builder = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 YOUR_REAL_KEY_HERE"  # Replace with your actual key
            ];
          };

          # Optimized Nix settings for builds
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            max-jobs = "auto";
            cores = 0;
          };

          # Essential build tools
          environment.systemPackages = with pkgs; [
            git
            vim
            htop
            curl
          ];

          # Swap via zram (good for builds)
          services.zramSwap.enable = true;
          services.zramSwap.memoryPercent = 75;

          time.timeZone = "UTC";
          i18n.defaultLocale = "en_US.UTF-8";
          console.keyMap = "us";

          system.stateVersion = "24.11";
        })
      ];
    };
  };
}
