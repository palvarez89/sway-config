{ config, pkgs, nixGL, lib, ... }:

let
  WALLPAPERS="$HOME/Pictures/Wallpapers";
  REPO="git@github.com:palvarez89/wallpapers.git";
in
{
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  # home.stateVersion = "25.05"; # Please read the comment before changing.

  # Ensure HM configures .deskop files correctly using XDG_DATA_DIRS
  targets.genericLinux.enable = true;

  # Needed to manage XDG directories + .desktop entries
  xdg.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    pkgs.swaylock-effects
    pkgs.nwg-displays
    # pkgs.wpaperd

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  xdg.configFile."sway/environment".text = ''
    if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi
  '';

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/pedro/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  xdg.desktopEntries.nwg-displays = {
    name = "Displays Settings";
    genericName = "Output configuration utility";
    comment = "nwg-shell tool to configure outputs";
    exec = lib.getExe pkgs.nwg-displays;
    terminal = false;
    icon = "nwg-displays";
    categories = [
      "Settings"
      "DesktopSettings"
    ];
  };


  xdg.desktopEntries.slackpwa = {
    name = "Slack (PWA)";
    exec = "google-chrome-stable --app=https://app.slack.com/client/";
    terminal = false;
    categories = [ "Network" "InstantMessaging" ];
  };


  # One-time initialization of the wallpapers folder
  home.activation.initWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${WALLPAPERS}"

    if [ ! -d "${WALLPAPERS}/.git" ]; then
      echo "Initializing wallpapers git repo..."
      /usr/bin/git -C "${WALLPAPERS}" init
      /usr/bin/git -C "${WALLPAPERS}" remote add origin "${REPO}"
    fi

    # Pull latest if folder is empty
    if [ -z "$(ls -A ${WALLPAPERS})" ]; then
      echo "Pulling wallpapers from remote..."
      /usr/bin/git -C "${WALLPAPERS}" pull origin main || true
    fi
  '';

  # Systemd service to sync wallpapers periodically
  systemd.user.services.wallpaper-git-sync = {
    Unit = {
      Description = "Update wallpapers from GitHub";
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      WorkingDirectory = WALLPAPERS;
      ExecStart = "/usr/bin/git pull --ff-only";
      SuccessExitStatus = [0 1]; # don’t fail if no updates
    };
  };

  systemd.user.timers.wallpaper-git-sync = {
    Unit = { Description = "Periodic wallpaper git sync"; };
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install = { WantedBy = [ "timers.target" ]; };
  };

  services.wpaperd = {
    enable = true;

    package = pkgs.runCommand "wpaperd-nixgl" { buildInputs = [ pkgs.makeWrapper ]; } ''
          mkdir -p $out/bin
          # Use nixGLDefault which auto-detects Nvidia vs Mesa (Intel/AMD)
          makeWrapper ${nixGL.packages.${pkgs.system}.nixGLDefault}/bin/nixGL $out/bin/wpaperd-nixgl \
            --add-flags "${pkgs.wpaperd}/bin/wpaperd"
        '';

    settings = {

      default = {
        duration = "10m";
        mode = "fit-border-color";
        recursive = true;
      };

      "eDP-1" = {
        path = "${config.home.homeDirectory}/Pictures/Wallpapers/16x10";
      };

      any = {
        path = "${config.home.homeDirectory}/Pictures/Wallpapers/16x9";
      };
    };
  };


  services.kanshi = {
    enable = true;
    settings = [
      # 1. Specific case: Your 1080p Dell monitor
      {
        profile = {
          name = "docked-1080p";
          outputs = [
            {
              criteria = "eDP-1";
              scale = 1.2;
              status = "enable";
            }
            {
              criteria = "Dell Inc. DELL SE2722HX 9KY71R3";
              scale = 0.8;
              status = "enable";
            }
          ];
        };
      }

      # 2. Home 4K case: Matches your Philips home monitor
      {
        profile = {
          name = "docked-4k-at-home";
          outputs = [
            {
              criteria = "eDP-1";
              scale = 1.2;
              status = "enable";
            }
            {
              criteria = "Philips Consumer Electronics Company PHL 288E2 UK52124002606";
              mode = "3840x2160@60Hz";
              scale = 1.2;
              status = "enable";
            }
          ];
        };
      }
      # 3. General 4K case: Matches all office Dell 4K monitors
      {
        profile = {
          name = "docked-4k-colony";
          outputs = [
            {
              criteria = "eDP-1";
              scale = 1.2;
              status = "enable";
            }
            {
              criteria = "Dell Inc. DELL S2725QC*";
              mode = "3840x2160@60Hz";
              scale = 1.2;
              status = "enable";
            }
          ];
        };
      }

      # 4. Fallback: Laptop only
      {
        profile = {
          name = "undocked";
          outputs = [
            {
              criteria = "eDP-1";
              scale = 1.0;
              status = "enable";
            }
          ];
        };
      }
    ];
  };

  systemd.user.services.wpaperd = {
    Service = {
      Type = "idle";  # wait for session
      Environment = "DISPLAY=${env:DISPLAY}";
      ExecStart = lib.mkDefault "${pkgs.wpaperd}/bin/wpaperd";

      Restart = "always";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        terminal = "foot";
        layer = "overlay";
        width = 45;
        lines = 10;
        font = "monospace:size=12";
        prompt = "❯ ";
        icon-theme = "Papirus";
        icons-enabled = true;
        exit-on-keyboard-focus-loss = false;
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
