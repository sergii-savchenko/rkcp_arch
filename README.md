# Installation

To use CLI to render document, please install (depending on your system configuration, you may need to use `sudo`):

```
npm install -g markdown-cli-renderer
npm install -g babel-runtime
```

## Rendering document

To render current version just type:

`./render.sh`

## Viewing current documents


We recommend using MS VSCode for this:

https://code.visualstudio.com/download

With installed plugins:

* Mermaid preview
* Markdown Preview Mermaid support

After installing those plugins you should see something like this:

![](./assets/vscode.png)


# Raised security API 

This section descripbes set of API of RKCP that needs additional confirmation on actions besides using session JWT and/or API keys

## Deposits: Fiats

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant Barong
    participant Peatio
    participant PeatioDaemons
    participant RabbitMQ
    participant Redis
    participant Db
    participant Vault
    participant SmtpRelay
    participant Pusher

    User->>Proxy: request post '/management_api/v1/deposits/new'
    Proxy->>Peatio: forward post '/management_api/v1/deposits/new'
    Peatio->>Db:  insert deposits
    alt saved
        Db-->>Peatio: saved
    else bad data
        Db-->>Peatio: bad data
    end
    Peatio-->>Proxy: response
    alt saved
        Peatio-->>Proxy: status: 201
    else bad data
        Peatio-->>Proxy: status: 422
    end
    Proxy--xUser: forward response
```

## Withdraws: Fiats

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Barong
    participant Peatio
    participant PeatioDaemons
    participant RabbitMQ
    participant Redis
    participant Db
    participant Vault
    participant SmtpRelay
    participant PushNotifications
    participant SMSNotifications

    User->>Proxy: request post '{APPLOGIC}/api/v1/withdraws/new'
    Proxy->>AppLogic: forward post '{APPLOGIC}/api/v1/withdraws/new'
    AppLogic->>Db: Insert record

    AppLogic->>Vault: Create OTP (MFA)
    Vault-->>AppLogic: Created OTP (MFA)
    AppLogic-->>Proxy: Withdraw ID in queue 
    Proxy-->>User: Withdraw ID in queue

    Vault->>User: Send GA OTP
    User->>Proxy: MFA Verification WithdrawId + OTP, POST {APPLOGIC}/api/v1/withdraws/verify'

    Proxy->>AppLogic: MFA Verification WithdrawId + OTP, POST {APPLOGIC}/api/v1/withdraws/verify'

    AppLogic->AppLogic: Check sign policy  

    AppLogic->>Peatio: POST'/management_api/v1/withdraws/new'

    Peatio->>Db:  insert withdraw
    alt saved
        Db-->>Peatio: saved
    else bad data
        Db-->>Peatio: bad data
    end
    Peatio-->>Proxy: response
    alt saved
        Peatio-->>Proxy: status: 201
    else bad data
        Peatio-->>Proxy: status: 422
    end
    Proxy--xUser: forward response
```
