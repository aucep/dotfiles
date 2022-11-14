# ' the ONE TRUE CONFIG
#' by chicken

{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix <home-manager/nixos> ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # EDT
  time.timeZone = "America/Detroit";

  networking.networkmanager.enable = true;
  networking.hostName = "nix220";

  sound = {
    # apparently alsa has multiplexing now
    enable = true;
    # easy sound control??
    mediaKeys.enable = true;
  };

  # easy brightness control
  services.illum.enable = true;

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
    # autologin <- disabling my broken touchscreen before x is pain
    displayManager.autoLogin.user = "chick";
    windowManager.openbox.enable = true;
  };

  # me
  users.users.chick = {
    isNormalUser = # so*∕ true;#bestie so
      true;
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
      htop
      micro
      ncdu
      w3m # view nix docs
      wget
      xclip
      zellij # fancy multiplexer

      # gui
      bitwarden
      element-desktop
      gcolor2
      kitty
      pcmanfm
      dmenu
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
          id = 0;
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
          /* # turns out this is unstable
             search = {
             force = true;
             default = "Startpage";
             engines = {
             "Startpage" = {
             urls = [{
             template = "https://startpage.com/sp/search?query={searchTerms}";
             }];
             };
             "NixOS Options" = {
             urls = [{
             template = "https://search.nixos.org/options?channel=22.05&from=0&size=50&sort=relevance&type=packages&query={searchTerms}";
             }];
             definedAliases = [ "/no" ];
             };
             "Home Manager Options" = {
             urls = [{
             template = "https://mipmip.github.io/home-manager-option-search/?{searchTerms}";
             }];
             definedAliases = [ "/ho" ];
             };
             };
             };
          */
        };
      };

      rofi = {
        enable = true;
        theme = "solarized_alternate";
        extraConfig.modi = "drun";
      };

      zsh = {
        enable = true;
        shellAliases = {
          config = "sudo micro /etc/nixos/configuration.nix";
          update = "sudo nixos-rebuild switch";
        };
        initExtra = ''
          zellij
        '';
        # envExtra = "export DIRENV_LOG_FORMAT=";
        oh-my-zsh = {
          enable = true;
          theme = "gallifrey";
        };
      };
    };

    home.file = {
      # overengineered openbox config
      ".config/openbox/rc.xml".text = ''<?xml version="1.0" encoding="UTF-8"?>''
        + (with pkgs.lib;
          let
            genXML = { name, attrs ? { }, children ? [ ] }:
              let
                formatAttr = (k: v: " ${k}=\"${v}\"");
                attrStr = concatStrings (mapAttrsToList formatAttr attrs);
                childrenStr = concatMapStrings
                  (c: if (isAttrs c) then (genXML c) else (toString c))
                  children;
              in "<${name}${attrStr}>${childrenStr}</${name}>";
            elemAttr = name: attrs: children: {
              inherit name;
              inherit attrs;
              children = toList children;
            };
            elem = name: elemAttr name { };
          in genXML (elemAttr "openbox_config" {
            xmlns = "https://openbox.org/3.4/rc";
            "xmlns:xi" = "http://www.w3.org/2001/XInclude";
          } [
            (elem "desktops" (let desktops = [ "page" "code" "else" ];
            in [
              (elem "number" (length desktops))
              (elem "names" (map (elem "name") desktops))
            ]))
            (elem "keyboard" (let
              mkAction = (action:
                elemAttr "action" { name = action.action or action; }
                (mapAttrsToList elem (action.options or { })));
              mkKeybind = (key: data:
                elemAttr "keybind" { inherit key; }
                (if (isAttrs data && !(data ? action)) then
                  (mapAttrsToList mkKeybind data)
                else
                  (map mkAction (toList data))));
            in ([ (elem "chainQuitKey" "C-g") ] ++ (mapAttrsToList mkKeybind
              (let
                exec = command: {
                  action = "Execute";
                  options = { inherit command; };
                };
              in {
                "W-F11" = "Reconfigure";
                "W-r" = exec "rofi -show drun";
                "W-S-r" = exec "dmenu_run";
                "W-S-q" = "Close";
                "W-b" = "ToggleDecorations";
                "A-Tab" = "NextWindow";
                "A-S-Tab" = "PreviousWindow";
                "W-1" = {
                  action = "GoToDesktop";
                  options = { to = "1"; };
                };
                "W-2" = {
                  action = "GoToDesktop";
                  options = { to = "2"; };
                };
                "W-3" = {
                  action = "GoToDesktop";
                  options = { to = "3"; };
                };
                "W-S-1" = {
                  action = "SendToDesktop";
                  options = { to = "1"; };
                };
                "W-S-2" = {
                  action = "SendToDesktop";
                  options = { to = "2"; };
                };
                "W-S-3" = {
                  action = "SendToDesktop";
                  options = { to = "3"; };
                };
                # pseudo-tiling
                "W-s" = {
                  "s" = "Maximize";
                  "a" = [
                    "Unmaximize"
                    {
                      action = "MoveResizeTo";
                      options = {
                        x = "0";
                        y = "0";
                        width = "50%";
                        height = "100%";
                      };
                    }
                  ];
                  "d" = [
                    "Unmaximize"
                    {
                      action = "MoveResizeTo";
                      options = {
                        x = "-0";
                        y = "0";
                        width = "50%";
                        height = "100%";
                      };
                    }
                  ];
                };
              })))))
            (elem "theme" [
              (elem "titleLayout" "NL")
              (elem "keepBorder" "no")
            ])
            (elem "applications" (mapAttrsToList (class: opts:
              elemAttr "application" { inherit class; }
              (mapAttrsToList elem opts)) {
                "*" = {
                  decor = "no";
                  maximized = "yes";
                };
                firefox = { desktop = 1; };
                kitty = { desktop = 2; };
                element = { desktop = 3; };
              }))
          ]));

      ".config/openbox/autostart.sh".text = ''
        # my touchscreen is broken and i don't use my touchpad
        xinput disable "Wacom ISDv4 E6 Finger"
        xinput disable "SynPS/2 Synaptics TouchPad"

        # startup applications
        firefox &
        kitty &
        element &
      '';

      /* ".config/zellij/layouts/default.kdl".text = ''
         layout {

         }
         '';
      */
    };
  };

  # back up config
  system.copySystemConfiguration = true;

  # don't touch
  system.stateVersion = "22.05";

}
