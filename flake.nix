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

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          trafilatura
          readability-lxml
          requests
          lxml
          cssselect
        ]);

        url2org = pkgs.stdenv.mkDerivation {
          pname = "url2org";
          version = "1.0.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin
            cp url2org $out/bin/url2org
            chmod +x $out/bin/url2org
            PATH=${pythonEnv}/bin:$PATH
            patchShebangs $out/bin/url2org
            wrapProgram $out/bin/url2org \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.pandoc pkgs.wget ]}
          '';
        };

        wofi-cap-url2org = pkgs.stdenv.mkDerivation {
          pname = "wofi-cap-url2org";
          version = "1.0.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin
            cp wofi-cap-url2org $out/bin/wofi-cap-url2org
            chmod +x $out/bin/wofi-cap-url2org
            wrapProgram $out/bin/wofi-cap-url2org \
              --set URL2ORG_BIN "${url2org}/bin/url2org" \
              --prefix PATH : ${pkgs.lib.makeBinPath [
                pkgs.wofi pkgs.fd pkgs.findutils pkgs.wl-clipboard
                pkgs.libnotify pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.gnugrep pkgs.xdg-user-dirs
              ]}
          '';
        };

        url2org-proto = pkgs.stdenv.mkDerivation {
          pname = "url2org-proto";
          version = "1.0.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin
            cp url2org-proto $out/bin/url2org-proto
            chmod +x $out/bin/url2org-proto
            wrapProgram $out/bin/url2org-proto \
              --set WOFI_CAP "${wofi-cap-url2org}/bin/wofi-cap-url2org" \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.python3 pkgs.gnused ]}
          '';
        };

        desktopItem = pkgs.makeDesktopItem {
          name = "url2org";
          desktopName = "URL to Org Capture";
          exec = "${url2org-proto}/bin/url2org-proto %u";
          type = "Application";
          noDisplay = true;
          mimeTypes = [ "x-scheme-handler/url2org" ];
        };

        captureDesktopItem = pkgs.makeDesktopItem {
          name = "url2org-capture";
          desktopName = "URL2Org Capture";
          comment = "Webpagina opslaan als Org, Markdown, Typst, LaTeX of DOCX";
          exec = "${wofi-cap-url2org}/bin/wofi-cap-url2org";
          icon = "text-html";
          terminal = false;
          categories = [ "Utility" ];
          keywords = [ "url2org" "URL" "Org" "Markdown" ];
        };

      in {
        packages = {
          inherit url2org wofi-cap-url2org url2org-proto desktopItem captureDesktopItem;
          default = pkgs.symlinkJoin {
            name = "url2org-suite";
            paths = [ url2org wofi-cap-url2org url2org-proto desktopItem captureDesktopItem ];
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [ pythonEnv pkgs.pandoc pkgs.wofi pkgs.fd pkgs.wl-clipboard pkgs.libnotify ];
        };
      }
    );
}
