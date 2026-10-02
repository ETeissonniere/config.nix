{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The MCC backend omits JGit from its classpath. Match the bundled core's version.
  jgit = pkgs.fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/eclipse/jgit/org.eclipse.jgit/4.11.0.201803080745-r/org.eclipse.jgit-4.11.0.201803080745-r.jar";
    hash = "sha256-65gLsZH1dmuEV6JybltR2DU4oj6fdItQXGdkY6ljY+I=";
  };
  mcc =
    (pkgs.vscode-utils.extensionFromVscodeMarketplace {
      publisher = "microchip";
      name = "mplab-code-configurator";
      version = "1.0.5";
      hash = "sha256-Y7n06W4lWg8EX9BIb8iRBFvKDcS7cxwZekky3w0KHQY=";
    }).overrideAttrs
      (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace "$out/share/vscode/extensions/microchip.mplab-code-configurator/dist/extension.js" \
            --replace-fail 'this.additionalClassPaths.push(e,a,u)' 'this.additionalClassPaths.push(e,a,u,"${jgit}")'
        '';
      });
  mccDirectory = "${config.xdg.dataHome}/vscode-mcc/${builtins.baseNameOf mcc}";
in
{
  # MCC downloads its backend beside its code; ContentPath does not relocate it.
  home.file.".vscode/extensions/microchip.mplab-code-configurator".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink mccDirectory
  );
  home.activation.prepareMccExtension =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        if [ ! -d ${lib.escapeShellArg mccDirectory} ]; then
          run mkdir -p ${lib.escapeShellArg (builtins.dirOf mccDirectory)}
          run cp -R ${mcc}/share/vscode/extensions/microchip.mplab-code-configurator ${lib.escapeShellArg mccDirectory}
          run chmod -R u+w ${lib.escapeShellArg mccDirectory}
        fi
      '';

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.overrideAttrs {
      version = "1.140.0";
      src = pkgs.fetchurl {
        name = "VSCode_1.140.0_darwin-arm64.zip";
        url = "https://update.code.visualstudio.com/1.140.0/darwin-arm64/stable";
        hash = "sha256:86a64f1cc9f4e0b5fc44969530994742f4bd61e7b98d9637238c5e24b26593b0";
      };
    };

    # Include the pack's members: Home Manager does not resolve extension packs.
    profiles.default.extensions = [
      mcc
    ]
    ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        publisher = "eclipse-cdt";
        name = "memory-inspector";
        version = "1.3.0";
        hash = "sha256-F7Fq4lvuVosfYa2bLWRZTpkYvekaLnCaye4jrWamLi4=";
      }
      {
        publisher = "microchip";
        name = "mplab-ai-coding-assistant";
        version = "1.2.4";
        hash = "sha256-wQx/krG2eVhXQi56eWT3Cd7G8di1nML08Q26I0HwCHI=";
      }
      {
        publisher = "microchip";
        name = "mplab-clangd";
        version = "2.0.0";
        hash = "sha256-T21e9TLfpHIk0NVgWDBHQBCjAQLPcC5wUF1pLEOi9DY=";
      }
      {
        publisher = "microchip";
        name = "mplab-core-da";
        version = "2.0.2";
        hash = "sha256-GzDjYYj08t7wLIf0ZOPs0sdnBKjvqxbSUWsb1EkhM18=";
      }
      {
        publisher = "microchip";
        name = "mplab-data-visualizer";
        version = "0.1.5";
        hash = "sha256-39ddBiYIRZDIo9zDXHft5D0COkI4tC9ajQYWweizQpk=";
      }
      {
        publisher = "microchip";
        name = "mplab-extension-pack";
        version = "1.2.8";
        hash = "sha256-GxT4MBNMZ3oO8+zXxrvYoQ9nCfoO7J3xDuBgS4AAg4E=";
      }
      {
        publisher = "microchip";
        name = "mplab-extensions-core";
        version = "2.3.1";
        hash = "sha256-dwkpvfj3XFenjaSQBn5lYE1pgisZDnkU/gEz+nBPJO8=";
      }
      {
        publisher = "microchip";
        name = "mplab-extensions-platforms";
        version = "2.0.2";
        hash = "sha256-bFDr+VNFO2mP4BqR/EOJO05UuPJ5WPOpP2R/crUa9vI=";
      }
      {
        publisher = "microchip";
        name = "mplab-kconfig";
        version = "1.5.2";
        hash = "sha256-B3MvI3IeWGWtQiAoYalf3/e2Bjm+DjsntrRShk7yjAw=";
      }
      {
        publisher = "microchip";
        name = "mplab-ui";
        version = "2.0.1";
        hash = "sha256-rNxzvlFDzGGWoARhnDs5HTvBWU4d7eIFP4dCpechVhc=";
      }
      {
        publisher = "microchip";
        name = "mplabx-importer";
        version = "2.0.0";
        hash = "sha256-vzEOlNbuquJtNxrC1coo1D3W2Up2I1TgkYIyrEyoQeA=";
      }
      {
        publisher = "microchip";
        name = "runcmake";
        version = "1.10.2";
        hash = "sha256-QLrLuNuMjRUxdcV5+d60iq92WvQuYLuF9qxyqdireHU=";
      }
      {
        publisher = "microchip";
        name = "toolchains";
        version = "1.10.3";
        hash = "sha256-W0euODB0yWh//jwL3h4oWl1821OEvSYTbCsxX601vAg=";
      }
    ];
  };
}
