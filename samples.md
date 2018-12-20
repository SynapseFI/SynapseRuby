# Client

## Initializing Client

- Set up a .env file to fetch your client_id and client_secret
- Returns Client instance
- Set raise_for_202 as true if you want 2FA and MFA to be raised

```bash
args = {
  client_id:        ENV.fetch("client_id"),
  client_secret:    ENV.fetch("client_secret"),
  fingerprint:      "fp",
  ip_address:       'ip',
  development_mode: true,
  raise_for_202: true
}

client  = Synapse::Client.new(args)
```

## Creating USER

- Returns user instance

```bash
payload = {
  "logins": [
    {
      "email": "test@synapsefi.com"
    }
  ],
  "phone_numbers": [
    "901.111.1111",
    "test@synapsefi.com"
  ],
  "legal_names": [
    "Test User"
  ],
  "extra": {
    "supp_id": "122eddfgbeafrfvbbb",
    "cip_tag":1,
    "is_business": false
  }
}

user = client.create_user(payload: payload)
```

## Update Headers

- Updates current headers for future request

```bash
headers = client.update_headers(fingerprint:nil, idemopotency_key:nil, ip_address:nil)
```

## Get USER
- returns USER instance

```bash
user_id = "1232"
user = client.get_user(user_id: user_id,full_dehydrate: true)
```

## Get all USERS
-  returns USERS instance
-  Array of users on a platform

```bash
users = client.get_users(** options)
```

## Gets all transactions on a platform

- returns Transactions instance
- array of Transaction instance

```bash
trans = client.get_transaction(page: nil, per_page: nil, query: nil)
```

## Get all platform nodes
- Returns Nodes instance
- Array of Node instance
- Page (optional params)
- Per Page (optional params)

```bash
Nodes = client.get_all_nodes(** options)
```

## Get Institutions

- Returns institutions available for bank logins
- Page (optional params)
- Per Page (optional params)

```bash
institutions = client.get_all_institutions(** options)
```

## Create subscription
- Scope must be an array or else method will raise an error
- Returns subscription instace

```bash
scope = ["TRAN|PATCH"]
url = "webhooks.com"
subscription = client.create_subscriptions(scope: scope, url: url )
```

## Get all platforms subscription
- Developer has option to
- Page (optional params)
- Per Page (optional params)

```bash
subscriptions = client.get_all_subscriptions(** options)
```

## Get a subscription by id
- returns a subscription instance

```bash
subscription_id = "2342324"
subscription = client.get_subscription(subscriptions_id:)
```

## Update Subscription

- Updates a subscription scope or url
- Returns a subscription instance

```bash
subscription_id = "2342324"
scope = ["TRAN|PATCH"]
subscription = client.update_subscriptions(subscription_id: subscription_id , scope: scope)
```

## Issue Public Key

- Returns api response

```bash
scope = ["USERS|GET"]
public_key = client.issue_public_key(scope: scope)
```
## Locate ATM
- Returns all atms nearby
- Param zip
- Param radius
- Param lat
- Param lon

```bash
atms = client.locate_atm(** options)
```

## Get Crypto Quotes

- Returns Crypto Currencies Quotes

```bash
crypto_quotes = client.get_crypto_quotes()
```

## Get Market Data

- Returns Crypto market data
- Param limit
- Param currency


```bash
crypto_data = client.get_crypto_market_data(** options)
```

# User

## Update User Documents

- Updates user documents

```bash
body = {
  "update":{
    "login":{
      "email":"test2@synapsefi.com"
    },
    "remove_login":{
      "email":"test@synapsefi.com"
    },
    "phone_number":"901-111-2222",
    "remove_phone_number":"901.111.1111"
    }
}


user = user.user_update(payload:)
```

## Get User Node

- Gets User node
- Param full_dehydrate or force_refresh

```bash
node_id = "5bd9e7b3389f2400adb012ae"

node = user.get_user_node(node_id: node_id, full_dehydrate: true, force_refresh: true)
```

## Get All User Nodes

- Options[page, per_page, type]
```bash
Nodes = user.get_all_nodes(**options)
```

## Authenticate a USER

- Authenticates users
- Params Scope [Array]
- Param Idempotency_key [String]  (optional)

```bash
response = user.authenticate(** options)
```

## Select 2FA device

- Register new fingerprint
- Param device
- Param Idempotency_key [String]  (optional)

```bash
response = user.select_2fa_device(device:)
```

## Confirm 2FA pin

- Supply pin
- Param pin
- Param Idempotency_key [String]  (optional)

```bash
response = user.confirm_2fa_pin(pin:)
```

## Get user transactions

- Returns transactons instance
- Options[page, per_page, type]

```bash
transactions = user.get_user_transactions(** options)
```

## Create Node

- Creates Node
- Param node payload
- Param Idempotency_key [String]  (optional)
- Returns node or access token depending on node

```bash
node = user.create_node(payload:, options)
```

## ACH MFA

- Submit MFA question and access token
- Param MFA payload
- Param Idempotency_key [String]  (optional)
- Returns node or access token depending on node

```bash
node = user.ach_mfa(payload:, options)
```

## Create UBO

- Upload an Ultimate Beneficial Ownership or REG GG Form

```bash
response = user.create_ubo(payload:)
```

## Get User Statement

- Gets user statements
- Options[page, per_page, type]

```bash
statement = user.get_user_statement()
```

## Ship Card

- Initate card shipment
- Param node_id
- Param payload

```bash
node = user.ship_card()
```

## Reset Debit Cards

- Get new card number and cvv
- Param node_id

```bash
node = user.reset_debit_card(node_id:)
```

## Create Transaction

- Create a node transaction
- Param node_id
- Param payload
- Param Idempotency_key [String]  (optional)

```bash
transaction = user.create_transaction(node_id:, payload:, ** options)
```

## Get Node Transaction

- Param node_id
- Param trans_id

```bash
transaction = user.get_node_transaction(node_id:, trans_id:)
```

## Get all node transaction

- Param node_id
- Options[page, per_page, type]

```bash
nodes = user.get_all_node_transaction(node_id:, options)
```

## Verify Micro Deposit

- Param node_id
- Param payload

```bash
node = user.verify_micro_deposit(node_id:, payload:)
```

## Reinitiate Micro Deposit

- Param node_id

```bash
node = user.reinitiate_micro_deposit(node_id:)
```

## Generate Apple pay Token

- Param node_id
- Param payload

```bash
response = user.generate_apple_pay_token(node_id:, payload:)
```

## Update Node

- Param node_id
- Param payload

```bash
node = user.generate(node_id:, payload:)
```

## Delete Node

- Param node_id

```bash
response = user.delete_node(node_id:)
```

## Dummy Transactions

- initiates a dummy transaction to a node
- Param node_id [String]
- Param is_credit [Boolean]

```bash
response = user.dummy_transactions(node_id:, is_credit:)
```


## Comment on status

- Param node_id
- Param trans_id
- Param payload

```bash
transaction = user.comment_transaction(node_id:, trans_id:, payload:)
```

## Cancel Transaction

- Param node_id
- Param trans_id

```bash
response = user.cancel_transaction(node_id:, trans_id:)
```

## Dispute Card Transactions

- Param node_id
- Param trans_id

```bash
response = user.dispute_user_transactions(node_id:, trans_id:)
```

## Get All Subnets

- Param node_id
- Options[page, per_page, type]

```bash
subnets = user.get_all_subnets(node_id:, options)
```

## Get Subnet

- Param node_id
- Param subnet_id

```bash
subnet = user.get_subnet(node_id:, subnet_id:)
```
## Get Node Statements

- Param node_id
- Options[page, per_page, type]

```bash
response = get_node_statements(node_id:, ** options)
```


