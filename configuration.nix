#' the ONE TRUE CONFIG
#' by chicken

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];
    
  # boring stuff
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.pulseaudio.enable = true;
  sound.enable = true;
  time.timeZone = "America/Chicago";
  networking.networkmanager.enable = true;
  networking.hostName = "nix";
  
  # TRACKPOINT!!!!
  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
    sensitivity = 200;
  };
  
  # graphical env
  services.xserver = {
    enable = true;
    excludePackages = [ pkgs.xterm ];
    displayManager.autoLogin.user = "chick";
    windowManager.openbox.enable = true;
  };

  # me
  users.users.chick = {
    isNormalUser = /*so*∕ true;#bestie so*/true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  # zsh fixes
  users.defaultUserShell = pkgs.zsh;
  environment.shells = [ pkgs.zsh ];

  # yeah this is a monolithic config
  home-manager.users.chick = { pkgs, ... }: {
    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [
      # cli
      micro
      w3m
      wget
      xclip

      # gui
      bitwarden
      chromium
      gcolor2
      kitty
      dmenu
    ];

    programs = {
      # cli
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
      };
      
      zsh = {
        enable = true;
        shellAliases = {
          config = "sudo micro /etc/nixos/configuration.nix";
          update = "sudo nixos-rebuild switch";
        };
        envExtra = ''
          export DIRENV_LOG_FORMAT=""
        '';
        oh-my-zsh = {
          enable = true;
          theme = "gallois";
        };
      };

      # gui
      firefox = {
        enable = true;
        profiles.main = {
          id = 0;
          # install tree tabs (not a fan of the way extensions are here)
          userChrome = ''
          #titlebar {
            visibility: collapse !important;
          }
          '';
        };
      };
    };

    home.file = {
      # openbox config
      ".config/openbox/rc.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      
      <openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xi="http://www.w3.org/2001/XInclude">

      <desktops>
        <number>3</number>
        <names>
          <name>code</name>
          <name>page</name>
          <name>else</name>
        </names>
      </desktops>

      <!-- keybinds -->
      <keyboard>
        <chainQuitKey>C-g</chainQuitKey>

        <!-- reload config without restarting -->
        <keybind key="W-F11">
          <action name="Reconfigure"/>
        </keybind>

        <!-- application launcher -->
        <keybind key="W-r">
          <action name="Execute">
            <command>dmenu_run</command>
          </action>
        </keybind>

        <!-- window switching -->
        <keybind key="A-Tab">
          <action name="NextWindow" />
        </keybind>
        
        <keybind key="A-S-Tab">
          <action name="PreviousWindow" />
        </keybind>

        <!-- pseudo-tiling -->
        <keybind key="W-s">
        
          <!-- full -->
          <keybind key="w">
            <action name="ToggleMaximize" />
          </keybind>
          
          <!-- left -->
          <keybind key="a">
            <action name="Unmaximize" />
            <action name="MoveResizeTo">
              <x>0</x>
              <y>0</y>
              <width>50%</width>
              <height>100%</height>
            </action>
          </keybind>
          
          <!-- right -->
          <keybind key="d">
            <action name="Unmaximize" />
            <action name="MoveResizeTo">
              <x>-0</x>
              <y>0</y>
              <width>50%</width>
              <height>100%</height>
            </action>
          </keybind>
          
        </keybind>
        
      </keyboard>
      
      </openbox_config>
      '';

      # my touchscreen is broken and i don't use my touchpad
      ".config/openbox/autostart.sh".text = ''
      xinput disable "Wacom ISDv4 E6 Finger"
      xinput disable "SynPS/2 Synaptics TouchPad"
      '';
    };
  };

  # back up config
  system.copySystemConfiguration = true;

  # don't touch
  system.stateVersion = "22.05";

}

