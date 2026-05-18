#cloud-config

write_files:
  # 起動時にKey Vaultからトークンを取得する
  - path: /usr/local/bin/fetch-kv-token.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e

      # IMDS（Instance Metadata Service）からアクセストークン取得
      TOKEN=$(curl -s -H "Metadata: true" \
        "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net&client_id=${user_assigned_identity_client_id}" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

      # Key VaultからTFCトークン取得
      SECRET=$(curl -s -H "Authorization: Bearer $TOKEN" \
        "${key_vault_uri}secrets/tfc-agent-token?api-version=7.0" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['value'])")

      # 環境変数ファイルに書き込み
      echo "export TFC_AGENT_TOKEN=$SECRET" > /etc/profile.d/tfc-agent.sh
      echo "export TFC_AGENT_NAME=agent_pool" >> /etc/profile.d/tfc-agent.sh

  # systemdサービス定義(起動ごとに実行)
  - path: /etc/systemd/system/fetch-kv-token.service
    content: |
      [Unit]
      Description=Fetch TFC Agent Token from Key Vault
      After=network-online.target

      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/fetch-kv-token.sh

      [Install]
      WantedBy=multi-user.target

  # トークン取得後、tfc-agentを起動する
  - path: /etc/systemd/system/tfc-agent.service
    content: |
      [Unit]
      Description=HCP Terraform Agent
      After=fetch-kv-token.service

      [Service]
      EnvironmentFile=/etc/profile.d/tfc-agent.sh
      ExecStart=/usr/local/bin/tfc-agent agent
      Restart=always

      [Install]
      WantedBy=multi-user.target

runcmd:
  # サービスファイルを認識させる
  - systemctl daemon-reload
  # fetch-kv-token.serviceを毎起動時に実行されるよう登録
  - systemctl enable fetch-kv-token.service
  # fetch-kv-token.serviceを今すぐ実行
  - systemctl start fetch-kv-token.service
  # tfc-agentのzipをダウンロード
  - curl -Lo /tmp/tfc-agent.zip https://releases.hashicorp.com/tfc-agent/1.28.8/tfc-agent_1.28.8_linux_amd64.zip
  # tfc-agentを解凍
  - unzip /tmp/tfc-agent.zip -d /tmp/tfc-agent-dir
  # バイナリを配置
  - mv /tmp/tfc-agent-dir/tfc-agent /usr/local/bin/tfc-agent
  # 実行権限付与
  - chmod +x /usr/local/bin/tfc-agent
  # 不要となったファイルを削除
  - rm -rf /tmp/tfc-agent.zip /tmp/tfc-agent-dir
  # tfc-agent.serviceを毎起動時に実行されるよう登録
  - systemctl enable tfc-agent.service
  # tfc-agent.serviceを今すぐ実行
  - systemctl start tfc-agent.service
