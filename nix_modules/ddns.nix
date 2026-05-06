{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

let
  cfg = config.ddns;
  rustyDdnsPackage = inputs.rusty-ddns.packages.${pkgs.stdenv.hostPlatform.system}.default;
in

{
  options.ddns = {
    recordName = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare DNS record name to update with rusty_ddns.";
    };

    allowCreate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow rusty_ddns to create missing Cloudflare DNS records.";
    };
  };

  config = {
    users.users.rusty-ddns = {
      isSystemUser = true;
      group = "rusty-ddns";
    };
    users.groups.rusty-ddns = { };

    systemd.services.rusty-ddns = {
      description = "Update Cloudflare DNS records with rusty_ddns";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "rusty-ddns";
        Group = "rusty-ddns";
        ExecStart = pkgs.writeShellScript "rusty-ddns" ''
          ${rustyDdnsPackage}/bin/rusty_ddns cloudflare \
            --api-token "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.rustyDdnsCloudflareToken.path})" \
            --record-name ${lib.escapeShellArg cfg.recordName} \
            ${lib.optionalString cfg.allowCreate "--allow-create"}
        '';
      };
    };

    systemd.timers.rusty-ddns = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "rusty-ddns.service";
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        AccuracySec = "30s";
      };
    };
  };
}
