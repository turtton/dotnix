{
  services.openssh = {
    enable = true;
    ports = [ 23478 ];
    settings.PasswordAuthentication = false;
  };
}
