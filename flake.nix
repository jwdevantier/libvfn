{
  description = "provides the libvfn package for NixOS and Nix environments";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      libvfnVersion = "5.1.0";
      allSystems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = fn:
        nixpkgs.lib.genAttrs allSystems
          (system: fn { pkgs = import nixpkgs { inherit system; }; });

      # Default build options
      defaultOptions = {
        docs        = false;
        libnvme     = false;
        profiling   = false;
      };

      # Build the mesonFlags from options
      mkMesonFlags = opts: [
        "-Ddocs=${if opts.docs then "enabled" else "disabled"}"
        "-Dlibnvme=${if opts.libnvme then "enabled" else "disabled"}"
        "-Dprofiling=${if opts.profiling then "true" else "false"}"
      ];

      # Build the libvfn package for a given pkgs set and config
      mkLibvfn = { pkgs, config, ... }:
        pkgs.stdenv.mkDerivation {
          pname = "libvfn";
          version = libvfnVersion;
          src = ./.;
          mesonFlags = mkMesonFlags config;
          nativeBuildInputs = with pkgs;
            [ meson ninja pkg-config perl ]
            ++ pkgs.lib.optionals config.docs [ python3Packages.sphinx ];
          buildInputs = with pkgs;
            pkgs.lib.optionals config.libnvme [ libnvme ];
        };

    in {

      lib = {
        defaultOptions = defaultOptions;
      };

      formatter = forAllSystems ({ pkgs }: pkgs.nixfmt);
      packages = forAllSystems ({ pkgs }: rec {
        # Overridable via .override { config = defaultOptions // { profiling = true; }; }
        libvfn = nixpkgs.lib.makeOverridable mkLibvfn {
          pkgs = pkgs;
          config = defaultOptions;
        };
        default = libvfn;
      });
    };
}
