{
  services.cloudflared = {
    enable = true;
    tunnels = {
      "atticserver" = {
        credentialsFile = "/etc/cloudflared/atticserver.json";
        default = "http_status:404";
        ingress = {
          "attic.turtton.net" = {
            service = "http://localhost:8080";
          };
        };
      };
    };
  };
}
