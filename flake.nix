{
  description = "url2org - Capture webpages to Org-mode, Markdown, Typst, LaTeX or DOCX";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Python with required packages
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          trafilatura
          readability-lxml
          requests
          lxml
          cssselect
        ]);

        # Main url2org script wrapped with dependencies
        url2org = pkgs.writeScriptBin "url2org" ''
          #!${pythonEnv}/bin/python3
          ${builtins.readFile ./url2org.py}
        '';

        # Wofi capture script with all dependencies
        wofi-cap-url2org = pkgs.writeShellApplication {
          name = "wofi-cap-url2org";
          runtimeInputs = with pkgs; [
            wofi
            fd
            findutils
            wl-clipboard
            libnotify
            coreutils
            gnused
            gawk
          ];
          text = ''
            # shellcheck disable=SC2016
            URL2ORG_BIN="${url2org}/bin/url2org"
            export URL2ORG_BIN

            ${builtins.readFile ./wofi-cap-url2org.sh}
          '';
        };

        # Protocol handler script
        url2org-proto = pkgs.writeShellApplication {
          name = "url2org-proto";
          runtimeInputs = with pkgs; [ python3 ];
          text = ''
            WOFI_CAP="${wofi-cap-url2org}/bin/wofi-cap-url2org"

            ${builtins.readFile ./url2org-proto.sh}
          '';
        };

        # Desktop entry for protocol handler
        desktopItem = pkgs.makeDesktopItem {
          name = "url2org";
          desktopName = "URL → Org Capture (protocol)";
          exec = "${url2org-proto}/bin/url2org-proto %u";
          type = "Application";
          noDisplay = true;
          mimeTypes = [ "x-scheme-handler/url2org" ];
        };

      in {
        packages = {
          inherit url2org wofi-cap-url2org url2org-proto desktopItem;
          default = pkgs.symlinkJoin {
            name = "url2org-suite";
            paths = [ url2org wofi-cap-url2org url2org-proto desktopItem ];
          };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          packages = [
            pythonEnv
            pkgs.pandoc
            pkgs.wofi
            pkgs.fd
            pkgs.wl-clipboard
            pkgs.libnotify
          ];
        };
      }
    );
}
