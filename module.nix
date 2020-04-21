{config, pkgs, options, lib, ...}:
let
  friendup_overlay = (import ./overlay.nix);
  cfg = config.services.friendup;
in
{
  options.services.friendup = {
    enable = lib.mkEnableOption "Friendup Services";
    dbPassword = lib.mkOption {
      type = lib.types.str;
      description = "Plain-text password to for database access";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ friendup_overlay ];
    environment.systemPackages = [ pkgs.friendup pkgs.php ];
    users.users.friendup = {
      createHome = true;
      home = "/home/friendup";
    };
    services.mysql = {
      enable = true;
      package = pkgs.mysql;
    };
    networking.firewall.enable = true;
    networking.firewall.allowedTCPPorts = [
      6500 # web sockets
      6502 # http web interface TODO: use SSL instead
      ];
    systemd.services.friendup-core-init = {
      description = "initializaion for friendcore";
      wantedBy = [ "multi-user.target" ];
      after = [ "mysql.service" ];
      requires = [ "mysql.service" ];
      path = [ pkgs.mysql ];
      script = ''
        set -e

        mkdir -p /home/friendup/cfg

        cat << EOF >> /home/friendup/cfg/cfg.ini
        [DatabaseUser]

        host=localhost
        login=friendup
        password=${cfg.dbPassword}
        dbname=FriendMaster

        [FriendCore]
        fchost = localhost
        port = 6502
        fcupload = storage/

        [Core]
        SSLEnable=0
        port=6502

        [FriendNetwork]
        enabled = 0

        [FriendChat]
        enabled = 0
        EOF

        # friendup does not support passwordless auth to mysql, so we will
        # provide password, passed as a parameter to a module
        set -x
        cat << EOF | mysql -uroot -N
        CREATE USER IF NOT EXISTS 'friendup'@'localhost';
        SET PASSWORD FOR 'friendup'@'localhost' = PASSWORD("${cfg.dbPassword}");
        CREATE DATABASE IF NOT EXISTS FriendMaster;
        GRANT ALL PRIVILEGES on FriendMaster.* TO 'friendup'@'localhost';
        EOF
        if [ -e "/home/friendup/initialized-db" ]; then
          exit 0 # do nothing, as initialization had already been done
        fi

        mysql -uroot -N FriendMaster --execute="SOURCE ${pkgs.friendup}/db/FriendCoreDatabase.sql;"

        # create initialized flag to not to touch DB later
        touch /home/friendup/initialized-db
      '';
    };
    systemd.services.friendup-core = {
      description = "Friendup Core";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "mysql.service" "friendup-core-init.service" ];
      requires = [ "mysql.service" "friendup-core-init.service" ];
      path = [ pkgs.friendup pkgs.binutils-unwrapped pkgs.strace pkgs.php ];
      script = ''
        stat /home/friendup/modules/system/include > /home/friendup/log.log
        # strace is helpful when you need to know which directory is missing again
        # and cause segfault
        # strace -f -o/home/friendup/trace.log ${pkgs.friendup}/FriendCore
        # redirect logs from stdout to not to polute system logs
        ${pkgs.friendup}/FriendCore > /home/friendup/stdout
      '';
      environment = {
        FRIEND_HOME = "/home/friendup";
      };
      serviceConfig = {
        Type = "simple";
        User = "friendup";
        WorkingDirectory = "/home/friendup";
        Restart = "no";
      };
      preStart =
        let
           friendup_hash = lib.last (lib.splitString "/" (toString pkgs.friendup));
        in
        ''
        hash_value=""
        [ -e /home/friendup/initialized ] && {
          hash_value=$(cat /home/friendup/initialized)
        }
        if [ "$hash_value" != "${friendup_hash}" ]; then
          echo "HASH_MISMATCH! $hash_value != ${friendup_hash}"
          # surprisingly, Friendup wants to have write access to the directory,
          # in which it had been installed. Parts of it looks for FRIEND_HOME
          # which should be root of cfg/cfg.ini, which is ok, but then it tries to
          # load libraries from the same root and this is silly.
          # So we have to trick it a little
          rm -rf /home/friendup/libs
          ln -fs ${pkgs.friendup}/libs /home/friendup/

          rm -rf /home/friendup/sqlupdatesscripts
          ln -fs ${pkgs.friendup}/sqlupdatescripts /home/friendup/
          rm -rf /home/friendup/authmods
          ln -fs ${pkgs.friendup}/authmods /home/friendup/
          rm -rf /home/friendup/emod
          ln -fs ${pkgs.friendup}/emod /home/friendup/
          rm -rf /home/friendup/php
          ln -fs ${pkgs.friendup}/php /home/friendup/
          rm -rf /home/friendup/services
          ln -fs ${pkgs.friendup}/services /home/friendup/
          rm -rf /home/friendup/loggers
          ln -fs ${pkgs.friendup}/loggers /home/friendup/
          rm -rf /home/friendup/devices
          ln -fs ${pkgs.friendup}/devices /home/friendup/
          rm -rf /home/friendup/fsys
          ln -fs ${pkgs.friendup}/fsys /home/friendup/

          rm -rf /home/friendup/resources # remove leftovers from possible previous versions
          cp -r ${pkgs.friendup}/resources /home/friendup/ || true
          chmod -R ug+rwx /home/friendup/resources

          rm -rf /home/friendup/storage # remove leftovers from possible previous versions
          mkdir /home/friendup/storage

          rm -rf /home/friendup/modules # remove leftovers from possible previous versions
          cp -r ${pkgs.friendup}/modules /home/friendup/
          chmod -R ug+rwx /home/friendup/modules

          # DO NOT REMOVE. create mark, that means, that we had already done
          # initialization for current version
          echo ${friendup_hash} > /home/friendup/initialized
        fi

        while [ ! -e /home/friendup/initialized-db ]; do
          sleep 1s # wait until initialization service will be finished
        done
      '';

    };
  };
}

