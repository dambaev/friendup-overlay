{config, pkgs, options, ...}:
let
  friendup_overlay = import ./overlay.nix;
in
{
  nixpkgs.overlays = [ friendup_overlay ];
  options = {
    services.friendup = {
      enable = mkEnableOption "Friendup Services";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ friendup ];
    services.mysql = {
      enable = true;
    };
    systemd.services.friendup-core-init = {
      description = "initializaion for friendcore";
    };
    systemd.services.friendup-core = {\
      description = "Friendup Core";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "friend-core-init" ];
    };
  };
}