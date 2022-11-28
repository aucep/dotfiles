# ' the ONE TRUE CONFIG
#' by chicken
{
  config,
  pkgs,
  ...
}: {
  imports = [./hardware-configuration.nix <home-manager/nixos>];

  system = {
    stateVersion = "22.05";
    copySystemConfiguration = true;
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "America/Detroit";

  networking = {
    networkmanager.enable = true;
    hostName = "nix220";
  };

  # no sound

  services = {
    # easy brightness control
    illum.enable = true;
    
    # graphical environment
    xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
      # disabling my broken touchscreen before x is pain
      displayManager.autoLogin.user = "chick";
      # i like having window support
      windowManager.openbox.enable = true;
    };
  };
  
  # TRACKPOINT!!!!
  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
    sensitivity = 200;
  };

  # me
  users.users.chick = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "video"];
  };

  # zsh fixes
  users.defaultUserShell = pkgs.zsh;
  environment.shells = [pkgs.zsh];

  # yeah this is a monolithic config
  home-manager.users.chick = {pkgs, ...}: {
    nixpkgs.config.allowUnfree = true;

    services = {
      dunst.enable = true;
    };

    home.packages = with pkgs; [
      # cli
      micro # text editor
      alejandra # nix formatter
      htop # task manager
      ncdu # storage usage viewer
      xclip # clipboard bridge

      # gui
      kitty # terminal
      element-desktop # chat
      scrot # screenshots
      gimp # image editor
      pcmanfm # file manager
      xorg.xkill # last resort
    ];

    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
      };

      firefox = {
        enable = true;
        profiles.main = {
          # essential extensions:
          # - bitwarden
          # - ublock origin
          # - sidebery
          # - dark reader
          settings = {
            "browser.aboutConfig.showWarning" = false;
            "browser.uidensity" = 1; # compact
            "browser.startup.page" = 3; # restore session
            "toolkit.legacyUserProfileCustomizations.stylesheets" =
              true; # enable userchrome
          };
          userChrome = ''
            #titlebar, #sidebar-header {
              display: none;
            }
          '';
        };
      };
      
      neovim = {
        enable = true;
        vimAlias = true;
        plugins = with pkgs.vimPlugins; [
          vim-nix
        ];
      };

      rofi = {
        enable = true;
        theme = "solarized_alternate";
        extraConfig.modi = "drun,run";
      };

      zsh = {
        enable = true;
        shellAliases = {
          config = "sudo micro /etc/nixos/configuration.nix";
          update = "sudo nixos-rebuild switch";
        };
        oh-my-zsh = {
          enable = true;
          theme = "gallifrey";
        };
      };
    };

    home.file = {
      # ensure screenshots folder exists
      "screenshots/.keep".text = "keep";

      # nix-shell templates
      "shells/rust.nix".text = ''
        { pkgs ? import <nixpkgs> {} }:
        with pkgs;
        mkShell {
            nativeBuildInputs = [cargo rust-analyzer];
        }
      '';

      # i saw the reaper and i didn't even try this time
      
      # openbox startup
      ".config/openbox/autostart.sh".text = ''
        # my touchscreen is broken and i don't use my touchpad
        xinput disable "Wacom ISDv4 E6 Finger"
        xinput disable "SynPS/2 Synaptics TouchPad"

        # startup applications
        firefox &
        kitty &
        element-desktop &
      '';

      # overengineered openbox config
      ".config/openbox/rc.xml".text = with pkgs.lib; let
        desktops = ["page" "code" "else"];
        
        chainQuitKey = "C-g";
        
        keybinds = {
          "W-F11" = "Reconfigure";
          "W-r" = action "execute" {command = "rofi -show drun";};
          "W-S-r" = action "execute" {command = "rofi -show run";};
          "Print" = action "execute" {command = "scrot ~/screenshots/%F_%H-%M-%S.png";};
          "S-Print" = action "execute" {command = "scrot -i ~/screenshots/%F_%H-%M-%S.png";};
          "W-S-q" = "Close";
          "W-b" = "ToggleDecorations";
          "A-Tab" = "NextWindow";
          "A-S-Tab" = "PreviousWindow";
          "W-1" = action "GoToDesktop" {to = 1;};
          "W-2" = action "GoToDesktop" {to = 2;};
          "W-3" = action "GoToDesktop" {to = 3;};
          "W-S-1" = action "SendToDesktop" {to = 1;};
          "W-S-2" = action "SendToDesktop" {to = 2;};
          "W-S-3" = action "SendToDesktop" {to = 3;};
          # pseudo-tiling
          "W-s" = {
            "s" = "Maximize";
            "a" = [
              "Unmaximize"
              (
                action "MoveResizeTo"
                {
                  x = "0";
                  y = "0";
                  width = "50%";
                  height = "100%";
                }
              )
            ];
            "d" = [
              "Unmaximize"
              (
                action "MoveResizeTo"
                {
                  x = "-0";
                  y = "0";
                  width = "50%";
                  height = "100%";
                }
              )
            ];
          };
        };
        
        applications = {
          "*" = {
            decor = "no";
          };
          firefox = {
            desktop = 1;
            maximized = true;
          };
          kitty = {
            desktop = 2;
            maximized = true;
          };
          element = {
            desktop = 3;
            maximized = true;
          };
        };
        
        theme = {
          titleLayout = "NL";
          keepBorder = "no";
        };

        # -----------------------------

        action = action: options: {inherit action options;};
        genXML = {
          name,
          attrs ? {},
          children ? [],
        }: let
          # generate attributes
          attrStr = concatStrings (mapAttrsToList (k: v: " ${k}=\"${v}\"") attrs);
          # generate children
          childrenStr =
            concatMapStrings
            (c:
              if isAttrs c
              then genXML c
              else toString c)
            (toList children);
        in "<${name}${attrStr}>${childrenStr}</${name}>";
        elemAttr = name: attrs: children: {inherit name attrs children;};
        elem = name: elemAttr name {};
        toActionElem = action:
          elemAttr "action"
          {name = action.action or action;}
          (mapAttrsToList elem action.options or {});
        toKeybindElem = key: next:
          elemAttr "keybind"
          {inherit key;}
          (
            if isAttrs next && !next ? action
            then mapAttrsToList toKeybindElem next # keybind seq
            else map toActionElem (toList next) # actions
          );
      in
        ''<?xml version="1.0" encoding="UTF-8"?>''
        + (genXML
          (elemAttr "openbox_config"
            {
              xmlns = "https://openbox.org/3.4/rc";
              "xmlns:xi" = "http://www.w3.org/2001/XInclude";
            }
            [
              (elem "desktops" [
                (elem "number" (length desktops))
                (elem "names" (map (elem "name") desktops))
              ])
              (elem "keyboard" ([(elem "chainQuitKey" chainQuitKey)]
                  ++ (mapAttrsToList toKeybindElem keybinds)))
              (elem "theme" (mapAttrsToList elem theme))
              (elem "applications" (mapAttrsToList (class: options:
                elemAttr "application" {inherit class;}
                (mapAttrsToList elem options))
              applications))
            ]));
    };
  };
}
