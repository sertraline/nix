# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
  ];

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };


  virtualisation = {
    #podman.enable = true;
    docker = {
      enable = true;
    };
    libvirtd = {
      enable = true; 
    };
  };

  specialisation = {
    "Mitigations_Off" = {
      inheritParentConfig = true; # defaults to true
      configuration = {
        system.nixos.tags = [ "mitigations_off" ];
        boot.kernelParams = [ "mitigations=off" ];
      };
    };
  };

  systemd.targets.machines.enable = true;

  services.udisks2.settings = { # fix NTFS mount, from https://wiki.archlinux.org/title/NTFS#udisks_support
    "mount_options.conf" = {
      defaults = {
        ntfs_defaults = "uid=$UID,gid=$GID,noatime,prealloc";
      };
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = "*";
      };
    };
  };
  hardware.enableAllFirmware = true;
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.desu = {
    isNormalUser = true;
    description = "desu";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "docker" "libvirtd" "wireshark" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      kate
    #  thunderbird
    ];
  };

  users.defaultUserShell = pkgs.zsh;


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    curl
    gimp
    krita
    gparted
    okular
    zsh
    vlc
    mpv
    ffmpeg-full
    telegram-desktop
    whois
    htop
    mlocate
    vscode
    android-studio
    wireguard-tools
    xdg-desktop-portal-kde
    plasma-browser-integration
    firefox-bin
    chromium
    virt-manager
    docker-compose
    gdb
    unrar
    unzip
    pavucontrol
    patchelf
    patchutils
    ncdu
    whois
    valgrind
    imagemagick
    python3
    file
    anki-bin
    wireshark
    libreoffice-fresh
  ];

  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-kde
      ];
    };
  };

  environment.etc = {
    "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
  	bluez_monitor.properties = {
  		["bluez5.enable-sbc-xq"] = true,
  		["bluez5.enable-msbc"] = true,
		["bluez5.enable-hw-volume"] = true,
  		["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
  	}
    '';
    "wireplumber/bluetooth.lua.d/50-alsa-config.lua".source = "/etc/nixos/50-alsa-config.lua";
  };

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.8.0.2/24" ];
      dns = [ "1.1.1.1" ];
      privateKeyFile = "/etc/nixos/privatekey";

      peers = [
        {
          publicKey = "";
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = "10.2.0.1:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  programs.adb.enable = true;
  programs.kdeconnect.enable = true;
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
    };
    histSize = 100000;
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "mh";
    };
  };

  services.locate.enable = true;
  services.locate.locate = pkgs.mlocate;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  fonts.fonts = with pkgs; [
    fira-code
    fira-code-symbols
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}