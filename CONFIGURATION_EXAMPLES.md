# Enhanced Xray Configuration Examples
# These examples show the exact format used by the installation scripts

## TLS Configuration Example (Server A - VLESS)
{
  "streamSettings": {
    "network": "splithttp",
    "security": "tls",
    "tlsSettings": {
      "serverName": "cdn.example.com",
      "rejectUnknownSni": false,
      "allowInsecure": false,
      "fingerprint": "chrome",
      "sni": "cdn.example.com",
      "curvepreferences": "X25519",
      "alpn": ["h2", "http/1.1"]
    },
    "splithttpSettings": {
      "transport": "splithttp",
      "acceptProxyProtocol": false,
      "host": "cdn.example.com",
      "custom_host": "cdn.example.com",
      "path": "/assets",
      "noSSEHeader": false,
      "noGRPCHeader": true,
      "mode": "auto",
      "socketSettings": {
        "useSocket": false,
        "dialerProxy": "",
        "DomainStrategy": "asis",
        "tcpKeepAliveInterval": 0,
        "tcpUserTimeout": 0,
        "tcpMaxSeg": 0,
        "tcpWindowClamp": 0,
        "tcpKeepAliveIdle": 0,
        "tcpMptcp": false
      },
      "scMaxEachPostBytes": 1000000,
      "scMaxConcurrentPosts": 6,
      "scMinPostsIntervalMs": 25,
      "xPaddingBytes": 200,
      "keepaliveperiod": 60
    }
  }
}

## Reality Configuration Example (Server A - VLESS)
{
  "streamSettings": {
    "network": "splithttp",
    "security": "reality",
    "realitySettings": {
      "show": false,
      "dest": "www.microsoft.com:443",
      "privatekey": "UG3uFV-EnXrYSOr8KFxwy4QYq1Bqyz9LDotrC8UXWGo",
      "minclientver": "",
      "maxclientver": "",
      "maxtimediff": 0,
      "proxyprotocol": 0,
      "shortids": [
        "4c8485ed0b3826d2",
        "5d76b48a37cda2e0",
        "f59a4dc911a58e44",
        "0b2878e7844516d5",
        "32fa475edd0f8fad",
        "03a6ba30ee1991af",
        "06d382648c274074",
        "39a8628b2b238bd2",
        "65ac06daa2b15e17",
        "ebc4f6767dbccf67"
      ],
      "serverNames": [
        "www.accounts.accesscontrol.windows.net"
      ],
      "fingerprint": "safari",
      "spiderx": "",
      "publickey": "YSYohXH3mMERhGoku28l_mBaNLM8o-F2avUqEARHXBE"
    },
    "splithttpSettings": {
      "transport": "splithttp",
      "acceptProxyProtocol": false,
      "host": "cdn.example.com",
      "custom_host": "cdn.example.com",
      "path": "/assets",
      "noSSEHeader": false,
      "noGRPCHeader": true,
      "mode": "auto",
      "socketSettings": {
        "useSocket": false,
        "dialerProxy": "",
        "DomainStrategy": "asis",
        "tcpKeepAliveInterval": 0,
        "tcpUserTimeout": 0,
        "tcpMaxSeg": 0,
        "tcpWindowClamp": 0,
        "tcpKeepAliveIdle": 0,
        "tcpMptcp": false
      },
      "scMaxEachPostBytes": 1000000,
      "scMaxConcurrentPosts": 6,
      "scMinPostsIntervalMs": 25,
      "xPaddingBytes": 200,
      "keepaliveperiod": 60
    }
  }
}

## Trojan TLS Configuration Example (Server A)
{
  "streamSettings": {
    "network": "tcp",
    "security": "tls",
    "tlsSettings": {
      "serverName": "cdn.example.com",
      "rejectUnknownSni": false,
      "allowInsecure": false,
      "fingerprint": "chrome",
      "sni": "cdn.example.com",
      "curvepreferences": "X25519",
      "alpn": ["h2", "http/1.1"]
    }
  }
}

## Trojan Reality Configuration Example (Server A)
{
  "streamSettings": {
    "network": "tcp",
    "security": "reality",
    "realitySettings": {
      "show": false,
      "dest": "www.microsoft.com:443",
      "privatekey": "UG3uFV-EnXrYSOr8KFxwy4QYq1Bqyz9LDotrC8UXWGo",
      "minclientver": "",
      "maxclientver": "",
      "maxtimediff": 0,
      "proxyprotocol": 0,
      "shortids": [
        "4c8485ed0b3826d2",
        "5d76b48a37cda2e0",
        "f59a4dc911a58e44",
        "0b2878e7844516d5",
        "32fa475edd0f8fad",
        "03a6ba30ee1991af",
        "06d382648c274074",
        "39a8628b2b238bd2",
        "65ac06daa2b15e17",
        "ebc4f6767dbccf67"
      ],
      "serverNames": [
        "www.accounts.accesscontrol.windows.net"
      ],
      "fingerprint": "safari",
      "spiderx": "",
      "publickey": "YSYohXH3mMERhGoku28l_mBaNLM8o-F2avUqEARHXBE"
    }
  }
}

## Server B VLESS Inbound Configuration
{
  "inbounds": [
    {
      "tag": "vless-in",
      "listen": "127.0.0.1",
      "port": 18081,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "12345678-1234-1234-1234-123456789abc",
            "flow": ""
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "splithttp",
        "security": "none",
        "splithttpSettings": {
          "transport": "splithttp",
          "acceptProxyProtocol": false,
          "host": "cdn.example.com",
          "custom_host": "cdn.example.com",
          "path": "/assets",
          "noSSEHeader": false,
          "noGRPCHeader": true,
          "mode": "auto",
          "socketSettings": {
            "useSocket": false,
            "dialerProxy": "",
            "DomainStrategy": "asis",
            "tcpKeepAliveInterval": 0,
            "tcpUserTimeout": 0,
            "tcpMaxSeg": 0,
            "tcpWindowClamp": 0,
            "tcpKeepAliveIdle": 0,
            "tcpMptcp": false
          },
          "scMaxEachPostBytes": 1000000,
          "scMaxConcurrentPosts": 6,
          "scMinPostsIntervalMs": 25,
          "xPaddingBytes": 200,
          "keepaliveperiod": 60
        }
      }
    }
  ]
}

## Server B Trojan Inbound Configuration
{
  "inbounds": [
    {
      "tag": "trojan-in",
      "listen": "127.0.0.1",
      "port": 18081,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "12345678-1234-1234-1234-123456789abc"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    }
  ]
}
