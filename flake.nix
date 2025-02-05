{
  description = "Rzls LSP Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
 flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, self, ...}:
  flake-parts.lib.mkFlake { inherit inputs; } {
      systems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { self, config, self', inputs', pkgs, system, lib, ... }: {
    packages.rzls =
      # Notice the reference to nixpkgs here.
      with import nixpkgs { system = "x86_64-linux"; };
      let
        pname = "rzls";
        dotnet-sdk = with dotnetCorePackages;
          sdk_9_0 // {
            inherit (combinePackages [ sdk_9_0 ]) packages targetPackages;
          };
        # need sdk on runtime as well
        dotnet-runtime = dotnetCorePackages.sdk_9_0;
        rid =
          dotnetCorePackages.systemToDotnetRid stdenvNoCC.targetPlatform.system;

        project = "rzls";
      in buildDotnetModule rec {
        inherit pname dotnet-sdk dotnet-runtime;

        vsVersion = "2.61";
        src = fetchFromGitHub {
          owner = "dotnet";
          repo = "razor";
          # Need a better way to get this commit hash.
          # As the build happens off github on Microsoft Azure DevOps and isn't
          # related to any particular tag/branch.
          rev = "dd64bf78c16a7e8fa1900da060100e9338383dea";
          hash = "sha256-C5/Mc5HxxAVGLO6IPhyyBNLcjvjmF8sKg1KpIdN0/KQ=";
        };

        # versioned independently from vscode-csharp
        # "roslyn" in here:
        # https://github.com/dotnet/vscode-csharp/blob/main/package.json
        version = "9.0.0-preview.25052.3";
        projectFile = "src/Razor/src/${project}/${project}.csproj";
        useDotnetFromEnv = true;
        nugetDeps = ./deps.json;

        nativeBuildInputs = [ jq ];

        postPatch = ''
          # Upstream uses rollForward = latestPatch, which pins to an *exact* .NET SDK version.
          jq '.sdk.rollForward = "latestMinor"' < global.json > global.json.tmp
          mv global.json.tmp global.json
        '';

        dotnetFlags = [
          "-p:TargetRid=${rid}"
          # this removes the Microsoft.WindowsDesktop.App.Ref dependency
          "-p:EnableWindowsTargeting=false"
        ];

        # two problems solved here:
        # 1. --no-build removed -> BuildHost project within roslyn is running Build target during publish
        # 2. missing crossgen2 7.* in local nuget directory when PublishReadyToRun=true
        # the latter should be fixable here but unsure how
        installPhase = ''
          runHook preInstall

          env dotnet publish $dotnetProjectFiles \
              -p:ContinuousIntegrationBuild=true \
              -p:Deterministic=true \
              -p:InformationalVersion=$version \
              -p:UseAppHost=true \
              -p:PublishTrimmed=false \
              -p:PublishReadyToRun=false \
              --configuration Release \
              --no-self-contained \
              --output "$out/lib/$pname" \
              --no-restore \
              --runtime ${rid} \
              ''${dotnetInstallFlags[@]}  \
              ''${dotnetFlags[@]}

          runHook postInstall
        '';

        passthru = {
          tests.version = testers.testVersion { package = rzls; };
          updateScript = ./update.sh;
        };

        meta = {
          homepage = "https://github.com/dotnet/vscode-csharp";
          description = ''
            Razor is a markup syntax for adding server-side logic to web pages. This package
                  contains a Razor language server.'';
          changelog =
            "https://github.com/dotnet/vscode-csharp/releases/tag/v${vsVersion}";
          license = lib.licenses.mit;
          maintainers = with lib.maintainers; [ tris203 ];
          mainProgram = "rzls";
        };
      };
      };

  };
}
