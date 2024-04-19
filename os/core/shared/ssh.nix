{ username, ... }: {
  services.openssh = {
    enable = true;
    ports = [ 23478 ];
    settings.PasswordAuthentication = false;
  };

  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/8nfHCulkm71YTzMXgrvTF+G9RQ9LUvy6pKat/FXot"
  ];
}
