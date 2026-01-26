{
  pkgs,
  inputs,
  config,
  ...
}:

let
  housefirePackage =
    inputs.python-serverless-housefire.packages.${pkgs.stdenv.hostPlatform.system}.default;
  housefireServiceFactory =
    { ticker }:
    {
      after = [
        "network.target"
        "auditd.service"
      ];
      description = "The python housefire scraper client for ${ticker}";
      serviceConfig = {
        ExecStart = pkgs.writeShellScript "housefire-${ticker}" ''
          ${pkgs.xvfb-run}/bin/xvfb-run -d -s "-screen 0 2560x1600x24" ${housefirePackage}/bin/housefire run-data-pipeline ${ticker}
        '';
        Type = "oneshot";
        User = config.users.users.liam.name;
        Group = config.users.users.liam.group;
      };
    };
  housefireTimerFactory =
    { ticker, dayOfMonth }:
    {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "housefire-${ticker}.service";
        OnCalendar = "*-*-${dayOfMonth} 00:00:00";
      };
    };
in

{
  imports = [
    ./postgres.nix # module is named nix_postgres
  ];

  services.postgresql = {
    ensureDatabases = [ "housefire" ];
    ensureUsers = [
      {
        name = "housefire";
        ensureDBOwnership = true;
      }
    ];
  };

  nix_postgres = {
    extraAuthLines = ''
      local sameuser  housefire     scram-sha-256
      host  sameuser  housefire     all              scram-sha-256
    '';
    pgbouncerDatabases = {
      housefire = "host=/run/postgresql dbname=housefire user=housefire ";
    };
  };

  users.users.housefire = {
    linger = true;
    isSystemUser = true;
    group = "housefire";
  };
  users.groups.housefire = { };

  systemd.services."housefire-pld" = housefireServiceFactory { ticker = "pld"; };
  systemd.timers."housefire-pld" = housefireTimerFactory {
    ticker = "pld";
    dayOfMonth = "01";
  };
  systemd.services."housefire-dlr" = housefireServiceFactory { ticker = "dlr"; };
  systemd.timers."housefire-dlr" = housefireTimerFactory {
    ticker = "dlr";
    dayOfMonth = "03";
  };
  systemd.services."housefire-eqix" = housefireServiceFactory { ticker = "eqix"; };
  systemd.timers."housefire-eqix" = housefireTimerFactory {
    ticker = "eqix";
    dayOfMonth = "07";
  };
  systemd.services."housefire-spg" = housefireServiceFactory { ticker = "spg"; };
  systemd.timers."housefire-spg" = housefireTimerFactory {
    ticker = "spg";
    dayOfMonth = "11";
  };
  systemd.services."housefire-well" = housefireServiceFactory { ticker = "well"; };
  systemd.timers."housefire-well" = housefireTimerFactory {
    ticker = "well";
    dayOfMonth = "15";
  };
}
