# atticサーバー構築手順

- `gen-template atticserver` でLXCコンテナを作成する
- Proxmox環境にアップロードして構築
- `nix run nixpkgs#openssl rand 64 | base64 -w0`でHS256 JWT secretを作成
- `/etc/atticd/atticd.env`に`ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=上で生成したやつ`を書き込む
- `/etc/cloudflared/atticserver.json`にcloudflaredのシークレットを添付
  作り方忘れたけどcloudflared経由でTunnel作ったら勝手に作られるやつを載せれば良い。PC環境が一緒なら`~/.cloudflared/TunnelID.json`があるはず
- `sudo systemctl restart cloudflared-tunnel-atticserver`でcloudflared tunnelが疎通していることを確認する(atticdは勝手にリスタートして起動してくれてるはず)
- `sudo atticd-atticadm make-token \
    --validity "10y" \
    --sub "home*" \
    --pull "home*" \
    --push "home*" \
    --create-cache "home*" \
    --configure-cache "home*" \
    --configure-cache-retention "home*" \
    --destroy-cache "home*"` でトークンを生成
- 使いたいPC側で
  `attic cache create home`と`attic login home https://attic.turtton.net 上で生成したトークン`を実行。
- 完了



### References

- https://docs.attic.rs/admin-guide/deployment/nixos.html

