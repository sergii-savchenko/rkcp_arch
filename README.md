# GitHub repository:

https://github.com/sergii-savchenko/rkcp_arch

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

This section contains 




# Barong Management API

This section contains diagrams on Barong Management API


## Labels with 'private' scope

### Create a label with 'private' scope and assigns to account

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Barong
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request POST '{APPLOGIC}/api/v1/labels/new'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/labels/new'
    AppLogic->>Db: Insert record

    AppLogic->>Vault: Create OTP (MFA)
    Vault-->>AppLogic: Created OTP (MFA)
    AppLogic-->>Proxy: Label ID in queue
    Proxy-->>User: Label ID in queue

    Vault->>User: Send GA OTP
    User->>Proxy: MFA Verification LabelId + OTP, POST '{APPLOGIC}/api/v1/labels/verify'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/labels/verify'

    AppLogic->>Vault: Check sign policy
    Vault-->>AppLogic: Trust

    AppLogic->>+Db: update record
    AppLogic->>+Barong: jws POST '{BARONG}/management_api/v1/labels/'
    Barong-->>AppLogic: response result
    AppLogic-->>Proxy: Response result
    Proxy-->>User: Redirect results
```

### Update label

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Barong
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request POST '{APPLOGIC}/api/v1/labels/update'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/labels/update'
    AppLogic->>Db: Find record
    Db-->>AppLogic: Receive label Id

    AppLogic->>Vault: Create OTP (MFA)
    Vault-->>AppLogic: Created OTP (MFA)
    AppLogic-->>Proxy: Label ID in queue
    Proxy-->>User: Label ID in queue

    Vault->>User: Send GA OTP
    User->>Proxy: MFA Verification LabelId + OTP, POST '{APPLOGIC}/api/v1/labels/verify'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/labels/verify'

    AppLogic->>Vault: Check sign policy
    Vault-->>AppLogic: Trust

    AppLogic->>+Db: update record
    AppLogic->>+Barong: jws PUT '{BARONG}/management_api/v1/labels/'
    Barong-->>AppLogic: response result
    AppLogic-->>Proxy: Response result
    Proxy-->>User: Redirect results
```

### Delete label

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Barong
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request POST '{APPLOGIC}/api/v1/labels/delete'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/labels/delete'
    AppLogic->>Db: Find record
    Db-->>AppLogic: Receive label Id

    AppLogic->>Vault: Create OTP (MFA)
    Vault-->>AppLogic: Created OTP (MFA)
    AppLogic-->>Proxy: Label ID in queue
    Proxy-->>User: Label ID in queue

    Vault->>User: Send GA OTP
    User->>Proxy: MFA Verification LabelId + OTP, POST '{APPLOGIC}/api/v1/labels/verify'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/labels/verify'

    AppLogic->>Vault: Check sign policy
    Vault-->>AppLogic: Trust

    AppLogic->>Db: update record
    AppLogic->>Barong: jws PUT '{BARONG}/management_api/v1/labels/delete'
    Barong-->>AppLogic: response result
    AppLogic-->>Proxy: Response result
    Proxy-->>User: Redirect results
```
## Timestamp

### Receive server time in seconds since Unix epoch

This endpoint is useful for expiration syncronization and testing Management API

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Barong
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request POST '{APPLOGIC}/api/v1/timestamp'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/timestamp'
    
    AppLogic->>Vault: Create OTP (MFA)
    Vault-->>AppLogic: Created OTP (MFA)
    
    Vault->>User: Send GA OTP
    User->>Proxy: MFA Verification OTP, POST '{APPLOGIC}/api/v1/timestamp/verify'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/timestamp/verify'

    AppLogic->>Vault: Check sign policy
    Vault-->>AppLogic: Trust

    AppLogic->>+Barong: jws POST '{BARONG}/management_api/v1/timestamp/'
    Barong-->>AppLogic: response result
    AppLogic-->>Proxy: Response result
    Proxy-->>User: Redirect results
```
# Trading API 

This section contains trading process (Peatio member_api) - creating/canceling orders...
## Orders

### Create new order

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Db
    participant Vault
    participant Notifications

    PeatioDaemons->>RabbitMQ: [subscribe default channel (queues: matching, new_trade, order_processor)]
    PeatioDaemons->>RabbitMQ: [subscribe orderbook channel]
    PeatioDaemons->>RabbitMQ: [subscribe trade channel]
    User->>Proxy: request POST '{APPLOGIC}/api/v1/orders/new'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/orders/new'
    Note over AppLogic: verify JWT (see JWT verification)
    AppLogic->>Peatio: request POST '{PEATIO}/api/v2/orders/'
    Note over Peatio: verify JWT
    Peatio->>+Db: save order
    Peatio->>Db: lock funds (change account balance)
    Db-->>-Peatio: result
    alt success
        Peatio->>RabbitMQ: [in default channel publish action:submit order to the matching queue]
        opt daemons worker
            RabbitMQ-->>PeatioDaemons: [receive data from default channel]
            PeatioDaemons->>RabbitMQ: [in orderbook channel publish action:new marketID+sell/marketId+buy]
            RabbitMQ-->>PeatioDaemons: [receive data from orderbook channel]
            PeatioDaemons->>RabbitMQ: [in default channel to the matching new_trade, order_processor]
            PeatioDaemons-->>PeatioDaemons: calculate
            PeatioDaemons->>Db: save data
        end
        Peatio-->>AppLogic: response new order JSON
    else fail
        Peatio-->>AppLogic: cannot create
    end
    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Delete order

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant PeatioDaemons
    participant RabbitMQ
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request POST '{APPLOGIC}/api/v1/orders/delete'
    Proxy->>AppLogic: redirect POST '{APPLOGIC}/api/v1/orders/delete'
    Note over AppLogic: verify JWT (see JWT verification)
    AppLogic->>Peatio: request POST '{PEATIO}/api/v2/order/delete'
    Note over Peatio: verify JWT
    Peatio->>Db: canceled order
    Peatio->>RabbitMQ: publish canceling
    RabbitMQ-->>PeatioDaemons: Receive notification in subscribing channel

    Peatio-->>AppLogic: Response result

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```
## Public data

### Get markets list

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/markets'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/markets'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/markets'
    Peatio->>Db: get markets
    Db-->>Peatio: response markets
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Get tickers

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/tickers'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/tickers'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/tickers'
    Peatio->>Db: get tickers
    Db-->>Peatio: response tickers
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Get tickers for specified market

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/tickers/{market}'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/tickers/{market}'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/tickers/{market}'
    Peatio->>Db: get tickers for specified market
    Db-->>Peatio: response tickers
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Get order book for market

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/order_book'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/order_book'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/order_book'
    Peatio->>Db: request order book
    Db-->>Peatio: response list
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Get depth

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/depth'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/depth'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/depth'
    Peatio->>Db: request order book
    Db-->>Peatio: response list
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Get recent trades on market

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/trades'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/trades'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/trades'
    Peatio->>Db: request order book
    Db-->>Peatio: response list
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Get OHLC(k line) of specific market

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Redis
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/k'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/k'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/k'
    Peatio->>Redis: get data
    Redis-->>Peatio: response data
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

### Get fees (deposit/withdraw/trading)

```mermaid
sequenceDiagram
    participant User
    participant Proxy
    participant AppLogic
    participant Peatio
    participant RabbitMQ
    participant PeatioDaemons
    participant Redis
    participant Db
    participant Vault
    participant Notifications

    User->>Proxy: request GET '{APPLOGIC}/api/v1/fees/withdraw'
    Note over User: simple request without jwt
    Proxy->>AppLogic: redirect GET '{APPLOGIC}/api/v1/fees/withdraw'
    AppLogic->>Peatio: request GET '{PEATIO}/api/v2/fees/withdraw'
    Peatio->>Db: get fees
    Db-->>Peatio: response fees
    Peatio-->>AppLogic: response JSON

    AppLogic-->>Proxy: Response
    Proxy-->>User: Response
```

# Raised security API 

This section describes set of API of RKCP that needs additional confirmation on actions besides using session JWT and/or API keys

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
        alt jws signatures
            PermittedSigners->>AppLogic: request POST {AppLogic} /api/v1/withdraws/accept
            AppLogic->>AppLogic: Sign withdraw document
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

# Service processes

This section contains jwt authentification process

### JWT verification

```mermaid
sequenceDiagram
    participant Sender
    participant AppLogic
    participant Db

    Sender->>AppLogic: Request with JWToken
    AppLogic->>AppLogic: Decode & verify JWToken
    Note over AppLogic: verify: expiration, iss, jti, aud, sub, algorithms, leeway (iat, iss, exp)
    AppLogic->>Db: Find account by email
    Db-->>AppLogic: Receive member
    alt no verification or no member
        AppLogic-->>Sender: 401 Unauthorized
    else verified
        Note over AppLogic: continue execution
    end
```
