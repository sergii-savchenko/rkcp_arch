# Installation

To use CLI to render document, please install (depending on your system configuration, you may need to use `sudo    `):

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

# User management API




# Trading API 

This section contains 
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

### User initiate new withdraw

```mermaid
sequenceDiagram
    participant PermittedSigners
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant PeatioDaemons
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request post '{APPLOGIC}/api/v1/withdraws/new'
    Proxy->>AppLogic: redirect post '{APPLOGIC}/api/v1/withdraws/new'
    AppLogic->>Db: Insert record

    AppLogic->>Vault: Create OTP (MFA)
    Vault-->>AppLogic: Created OTP (MFA)
    AppLogic-->>Proxy: Withdraw ID in queue
    Proxy-->>User: Withdraw ID in queue

    Vault->>User: Send GA OTP
    User->>Proxy: MFA Verification WithdrawId + OTP, POST {APPLOGIC}/api/v1/withdraws/verify'
    Proxy->>AppLogic: redirect POST {APPLOGIC}/api/v1/withdraws/verify'

    AppLogic->AppLogic: Check sign policy

    AppLogic->>Db: update record
    Db-->>AppLogic: get organization signers list
    AppLogic-->>Notifications: Publish withdraw request for organization signers
    AppLogic-->>Proxy: Response notification about waiting accepting
    Proxy-->>User: Redirect notification
```

### Subscriber get withdraw request (for organization signers)

```mermaid
sequenceDiagram
    participant PermittedSigners
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant PeatioDaemons
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications

    Notifications-->>PermittedSigners: Receive notification about signature waiting

    PermittedSigners->>Proxy: Receive withdraw - request GET {AppLogic} /api/v1/withdraws/id
    Proxy->>AppLogic: redirect GET {AppLogic} /api/v1/withdraws/id

    Db-->>AppLogic: get withdraw
    AppLogic-->>Proxy: redirect withdraw
    Proxy-->>PermittedSigners: redirect withdraw

    opt not canceled yet
        alt set signature
            PermittedSigners->>AppLogic: request POST {AppLogic} /api/v1/withdraws/accept
            AppLogic->>AppLogic: Set signature
            AppLogic->>Db: Update record - add withdraw signature
            opt all signatures received
                AppLogic-->>Notifications: Publish info about receiving all organization signatures
            end
        else canceled
            PermittedSigners->>AppLogic: request POST {AppLogic} /api/v1/withdraws/cancel
            AppLogic->>Db: Set withdraw state canceled
            AppLogic-->>Notifications: Publish about withdraw canceling
        end
        AppLogic-->>Proxy: response result
        Proxy-->>PermittedSigners: redirect result
    end
    
```

### All organization signatures received

```mermaid
sequenceDiagram
    participant PermittedSigners
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant PeatioDaemons
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications
    
    Notifications-->>AppLogic: Withdraw - all signatures received
    AppLogic->>AppLogic: Set PEATIO mandatory signature
    AppLogic->>Peatio: Create accepted withdraw POST {PEATIO} /management_api/v1/withdraws/new
    Peatio->>+PeatioDaemons: withdraw in queuee
    PeatioDaemons->>+RabbitMQ: withdraw in queuee
    RabbitMQ-->>-PeatioDaemons: withdraw created
    PeatioDaemons-->>-AppLogic: withdraw created
    AppLogic->>Db: Update record
    AppLogic-->>Notifications: Publish about withdraw completing
```
