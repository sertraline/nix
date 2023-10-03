{ modulesPath, config, lib, pkgs, ... }: let
  publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHt2AM65QtSRGKFg8H7QzdPxXIt4lz9DyZD/ynnYdJz4EZW7gPZixk2UsnX1DsQwztSC936M/ILhg0llnSM7+webGWokFftqZaRkWX9BxeeupZKguA3H/2x5wgXzYmG/IZhJc5Zy75lrRRbJlnHI4ZdAY7CXotC+LgT7GSj2Hm57xVC3gAzIMYD8HBelkJhM9zsF3SdCcvPT6bUUDV9YRjvtbsBNew7uMwMt+OkR76/6lTXobAiyH949FQFXB0JhtOYwEKoQ1oNxmKezpOOn6sa61B/ERcMVPQ627scGjZ435fhzZCgcmkQOKC56qmZ8jSfGtssvSgwSRc7Yu4PYeh/42GhHfmfwYMVKn7pK/hHGwJMLKmu2H3fDGE7vy+mfYEULGme+77E37gGPC69+ghxmMQHT7iolzcSY0IeigkQe9Ie4xWMk+WCcqYFRIYK/cYd5xGHna+InpgE6QcSnLLUV+RQhC7HKgCLEt/+XWpQAE7DaGoVL7dd8p9DQL7wYJzVTyFbvq/8cQEH7dzP56b0p2ONRxq7/brmDihVrOafNHMPehmrtkxOF1Cn6LV3k97eIhkb1HLm6apLC69UA1pcETgbHm2IbvYNk5DHJT4T6cAq8x1bjUdtCq0nCbj/df3HUauLWP9yOg1EVRs2RWhI8ziuoGHpgJm8MNPheV/aQ== desu@interlinked";
  in {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
      ./disk-config.nix
    ];

    boot.loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    networking.hostName = "MAID";
    time.timeZone = "Europe/Moscow";

    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "prohibit-password";
      ports = [ 2216 ];
    };

    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
    
      virtualHosts = {
        "acid.im" = {
          root = "SED";
          listen = [
            { addr = "0.0.0.0"; port = 80; }
            { addr = "0.0.0.0"; port = 443; ssl = true; }
          ];
          forceSSL = true;
          enableACME = true;
          locations."/archive".extraConfig = ''
            autoindex on;
          '';
         };
        "SED" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            extraConfig = ''
              proxy_pass_header Authorization;
            '';
          };
        };
        };
      };

    security.acme = {
      acceptTerms = true;
      defaults.email = "SED";
    };


    environment.systemPackages = map lib.lowPrio [
      pkgs.curl
      pkgs.gitMinimal
    ] ++ (with pkgs; [
      vim
      nano
      zsh
      ffmpeg
      git
      wget
      unzip
      unrar
      patchelf
      patchutils
      ncdu
      whois
      neofetch
      valgrind
      imagemagick
      file
      oh-my-zsh
      (python3.withPackages(x: with x; [ pandas requests aiofiles aiohttp yt-dlp ]))
      go
    ]);

    virtualisation = {
      docker = {
        enable = true;
      };
    };

    users.users.root.openssh.authorizedKeys.keys = [ publicKey ];

    users.users.acid = {
      isNormalUser = true;
      description = "ablableble";
      extraGroups = [ "docker" ];
      shell = pkgs.zsh;
      packages = with pkgs; [
        #
      ];
      openssh.authorizedKeys.keys = [
        publicKey
      ];
    };

    users.defaultUserShell = pkgs.zsh;
    programs.direnv.enable = true;

    nixpkgs.config.allowUnfree = true;

    programs.zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
      };
      histSize = 100000;
      autosuggestions.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      ohMyZsh = {
        enable = true;
        plugins = [
          "git"
        ];
        theme = "mh";
      };
      interactiveShellInit = ''
          autoload -Uz compinit
          autoload -Uz promptinit
          compinit
          promptinit

          HISTFILE=~/.zsh_history
          SAVEHIST=8000

          bindkey -v
          bindkey -e
          bindkey "^[[1;5D" backward-word
          bindkey "^[[1;5C" forward-word

          export LANG=en_US.UTF-8
                
          alias soundcloud='python3 -m yt_dlp -o "%(uploader)s — %(title)s.%(ext)s" --embed-thumbnail --add-metadata -x --audio-format=mp3 '
          alias air='~/go/bin/air'
      '';
    };

    networking.nat.enable = true;
    networking.nat.externalInterface = "ens3";
    networking.nat.internalInterfaces = [ "wg0" ];
    networking.firewall = {
      allowedUDPPorts = [ 51820 ];
      allowedTCPPorts = [ 80 443 ];
    };

    networking.wireguard.interfaces = {
      wg0 = {
        ips = [ "10.8.0.1/24" ];

        listenPort = 51820;

        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ens3 -j MASQUERADE
        '';
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o ens3 -j MASQUERADE
        '';
        privateKeyFile = "/root/.wg_privatekey";

        peers = [
          {
            publicKey = "lt7FRLghVGVA7fCdqi572XtLMVpyLE/awWQA3AvVjkM=";
            allowedIPs = [ "10.8.0.2/32" ];
            persistentKeepalive = 25;
          }
          {
            publicKey = "huRXLXMF/jcJW+Rga/J+rZP4GVY7qh2HqxYZadEFMFA=";
            allowedIPs = [ "10.8.0.3/32" ];
            persistentKeepalive = 25;
          }
        ];
      };
    };

    system.stateVersion = "23.11";
}
