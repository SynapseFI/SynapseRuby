# Table of Contents
- [Client](#client)
    * [Initialize Client](#initialize-client)
    * [Create User](#create-user)
    * [Get User](#get-user)
    * [Get Subscription](#get-subscription)
    * [Update Subscription](#update-subscription)
    * [Get All Users](#get-all-users)
    * [Get All Client Transactions](#get-all-client-transactions)
    * [Get All Client Nodes](#get-all-client-nodes)
    * [Get All Client Institutions](#get-all-client-institutions)
    * [Issue Public Key](#issue-public-key)
- [User](#user)
    * [Get New Oauth](#get-new-oauth)
    * [Update User or Update/Add Documents](#update-user-or-update-add-documents)
    * [Generate UBO](#generate-ubo)
    * [Get All User Nodes](#get-all-user-nodes)
    * [Get All User Transactions](#get-all-user-transactions)
    + [Nodes](#nodes)
        * [Create Node](#create-node)
        * [Get Node](#get-node)
        * [Get All User Nodes](#get-all-user-nodes-1)
        * [Update Node](#update-node)
        * [Ship Debit](#ship-debit)
        * [Reset Debit](#reset-debit)
        * [Verify Micro Deposit](#verify-micro-deposit)
        * [Reinitiate Micro Deposit](#reinitiate-micro-deposit)
        * [Generate Apple Pay](#generate-apple-pay)
        * [Delete Node](#delete-node)
        * [Get All Node Subnets](#get-all-node-subnets)
        * [Get All Node Transactions](#get-all-node-transactions)
    + [Subnets](#subnets)
        * [Create Subnet](#create-subnet)
        * [Get Subnet](#get-subnet)
    + [Transactions](#transactions)
        * [Create Transaction](#create-transaction)
        * [Get Transaction](#get-transaction)
        * [Comment on Status](#comment-on-status)
        * [Dispute Transaction](#dispute-transaction)
        * [Cancel Delete Transaction](#cancel-delete-transaction)

# Client

##### Initialize Client

- Set up a .env file to fetch your client_id and client_secret
- Returns Client instance

```bash
args = {
  # synapse client_id
  client_id:        ENV.fetch("client_id"),
  # synapse client_secret
  client_secret:    ENV.fetch("client_secret"),
  # a hashed value, either unique to user or static for app
  fingerprint:      "fp",
  # end user's IP
  ip_address:       'ip',
  # (optional) requests go to sandbox endpoints if true
  development_mode: true,
  # (optional) if true logs requests to stdout
  logging: true,
  # (optional) file path to write logs to
  log_to: nil,
  # (optional) rases for 2FA and MFA if set to true
  raise_for_202: true
}

client  = Synapse::Client.new(args)
```

##### Create User

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

##### Get User
- returns USER instance

```bash
user_id = "1232"
user = client.get_user(user_id: user_id,full_dehydrate: true)
```

##### Create Subscription
- Returns subscription instace

```bash
scope = {
  "scope": [
    "USERS|POST",
    "USER|PATCH",
    "NODES|POST",
    "NODE|PATCH",
    "TRANS|POST",
    "TRAN|PATCH"
  ],
  "url": "https://requestb.in/zp216zzp"
}
subscription = client.create_subscriptions(scope: scope)
```

##### Get Subscription
- returns a subscription instance

```bash
subscription_id = "2342324"
subscription = client.get_subscription(subscriptions_id: subscription_id)
```

#### Update Subscription

- Updates a subscription scope, active or url
- Returns a subscription instance

```bash
subscription_id = "2342324"
body = {
  "is_active": true,
  "scope": [
    "USERS|POST",
    "NODES|POST",
    "TRANS|POST"
  ]
  "url": 'https://requestb.in/zp216zzp'
}
subscription = client.update_subscriptions(subscription_id: subscription_id , body: body)
```

##### Get All Users
-  returns USERS instance
-  Array of users on a platform

```bash
# param page (optional) response will default to 1
# param per_page [Integer] (optional) response will default to 20
users = client.get_users(** options)
```

#### Get All Client Transactions

- returns Transactions instance
- array of Transaction instance

```bash
trans = client.get_transaction(page: nil, per_page: nil, query: nil)
```

#### Get All Client Nodes
- Returns Nodes instance
- Array of Node instance
- Page (optional params)
- Per Page (optional params)

```bash
# param page (optional) response will default to 1
# param per_page [Integer] (optional) response will default to 20
Nodes = client.get_all_nodes(** options)
```

#### Get All Client Institutions

- Returns institutions available for bank logins
- Page (optional params)
- Per Page (optional params)

```bash
# param page (optional) response will default to 1
# param per_page [Integer] (optional) response will default to 20
institutions = client.get_all_institutions(** options)
```

#### Issue Public Key

- Returns api response

```bash
scope = "USERS|GET,USER|GET,USER|PATCH"
public_key = client.issue_public_key(scope: scope)
```

# User

##### Get New Oauth

```bash
scope =["USERS|GET,USER|GET,USER|PATCH"]
user.authenticate(scope: scope)
```

##### Update User or Update/Add Documents

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
user = user.user_update(payload:body)
```

##### Create UBO

- Upload an Ultimate Beneficial Ownership or REG GG Form

```bash
body = {
   "entity_info": {
      "cryptocurrency": True,
      "msb": {
         "federal": True,
         "states": ["AL"]
      },
      "public_company": False,
      "majority_owned_by_listed": False,
      "registered_SEC": False,
      "regulated_financial": False,
      "gambling": False,
      "document_id": "2a4a5957a3a62aaac1a0dd0edcae96ea2cdee688ec6337b20745eed8869e3ac8"
   ...
}
user.create_ubo(payload:body)
```

#### Get All User Nodes

- Options[page, per_page, type]
```bash
Nodes = user.get_all_nodes(page=1, per_page=5, type='ACH-US')
```

#### Get All User Transactions

- Returns transactons instance
- Options[page, per_page, type]

```bash
# param page (optional) response will default to 1
# param per_page (optional) response will default to 20
transactions = user.get_user_transactions(page=1, per_page=5)
```

### Nodes
##### Create Node
Refer to the following docs for how to setup the payload for a specific Node type:
- [Deposit Accounts](https://docs.synapsefi.com/v3.1/docs/deposit-accounts)
- [Card Issuance](https://docs.synapsefi.com/v3.1/docs/card-issuance)
- [ACH-US with Logins](https://docs.synapsefi.com/v3.1/docs/add-ach-us-node)
- [ACH-US MFA](https://docs.synapsefi.com/v3.1/docs/add-ach-us-node-via-bank-logins-mfa)
- [ACH-US with AC/RT](https://docs.synapsefi.com/v3.1/docs/add-ach-us-node-via-acrt-s)
- [INTERCHANGE-US](https://docs.synapsefi.com/v3.1/docs/interchange-us)
- [CHECK-US](https://docs.synapsefi.com/v3.1/docs/check-us)
- [CRYPTO-US](https://docs.synapsefi.com/v3.1/docs/crypto-us)
- [WIRE-US](https://docs.synapsefi.com/v3.1/docs/add-wire-us-node)
- [WIRE-INT](https://docs.synapsefi.com/v3.1/docs/add-wire-int-node)
- [IOU](https://docs.synapsefi.com/v3.1/docs/add-iou-node)

```bash
body = {
  "type": "DEPOSIT-US",
  "info":{
      "nickname":"My Checking"
  }
}
node = user.create_node(payload:, idempotency_key='123456')
```

##### Get Node

```bash
node_id = "5bd9e7b3389f2400adb012ae"
node = user.get_user_node(node_id: node_id, full_dehydrate: true, force_refresh: true)
```

#### Get All User Nodes

- Options[page, per_page, type]
```bash
Nodes = user.get_all_nodes(page=1, per_page=5, type='ACH-US')
```

#### Update Node

- Param node_id
- Param payload

```bash
node_id = '5ba05ed620b3aa005882c52a'
body = {
  "supp_id":"new_supp_id_1234"
}
node = user.generate(node_id:node_id, payload:body)
```

#### Ship Card

```bash
node_id = '5ba05ed620b3aa005882c52a'

body = {
  "fee_node_id":"5ba05e7920b3aa006482c5ad",
  "expedite":True
}
node = user.ship_card(node_id: node_id, payload: body)
```

#### Reset Debit Cards

```bash
node_id = '5ba05ed620b3aa005882c52a'
node = user.reset_debit_card(node_id: node_id)
```

#### Verify Micro Deposit

```bash
node_id = '5ba05ed620b3aa005882c52a'
body = {
  "micro":[0.1,0.1]
}
node = user.verify_micro_deposit(node_id: node_id, payload: body)
```

#### Reinitiate Micro Deposit

```bash
node_id = '5ba05ed620b3aa005882c52a'
node = user.reinitiate_micro_deposit(node_id: node_id)
```

##### Generate Apple Pay

```bash
node_id = '5ba05ed620b3aa005882c52a'
body = {
  "certificate": "your applepay cert",
  "nonce": "9c02xxx2",
  "nonce_signature": "4082f883ae62d0700c283e225ee9d286713ef74"
}
response = user.generate_apple_pay_token(node_id: node_id, payload: body)
```

#### Delete Node

```bash
node_id = '594e606212e17a002f2e3251'
response = user.delete_node(node_id: node_id)
```

#### Get All Node Subnets

```bash
node_id = '594e606212e17a002f2e3251'
subnets = user.get_all_subnets(node_id:node_id, page=4, per_page=10)
```

#### Get All Node Transactions

```bash
node_id = '594e606212e17a002f2e3251'
nodes = user.get_all_node_transaction(node_id: node_id, page=4, per_page=10)
```


### Subnets

##### Create Subnet
```python
node_id = '594e606212e17a002f2e3251'
body = {
  "nickname":"Test AC/RT"
}
user.create_subnet(node_id: node_id, payload: body)
```

#### Get Subnet
```bash
node_id = '594e606212e17a002f2e3251'
subn_id = '59c9f77cd412960028b99d2b'
subnet = user.get_subnet(node_id:, subnet_id:)
```

### Transactions

#### Create Transaction
```bash
node_id = '594e606212e17a002f2e3251'
body = {
  "to": {
    "type": "ACH-US",
    "id": "594e6e6c12e17a002f2e39e4"
  },
  "amount": {
    "amount": 20.1,
    "currency": "USD"
  },
  "extra": {
    "ip": "192.168.0.1"
  }
}
transaction = user.create_transaction(node_id: node_id, payload: body, idempotency_key:"2435")
```

#### Get Transaction

- Param node_id
- Param trans_id

```bash
node_id = '594e606212e17a002f2e3251'
trans_id = '594e72124599e8002fe62e4f'
transaction = user.get_node_transaction(node_id: node_id, trans_id: trans_id)
```

#### Comment on status

```bash
node_id = '594e606212e17a002f2e3251'
trans_id = '594e72124599e8002fe62e4f'
body = 'Pending verification...'
transaction = user.comment_transaction(node_id: node_id, trans_id: trans_id, payload: body)
```

#### Dispute Transaction

```bash
node_id = '594e606212e17a002f2e3251'
trans_id = '594e72124599e8002fe62e4f'
dispute_reason = {
  "dispute_reason":"CHARGE_BACK"
}
response = user.dispute_user_transactions(node_id:, trans_id:)
```

#### Cancel/Delete Transaction

```bash
node_id = '594e606212e17a002f2e3251'
trans_id = '594e72124599e8002fe62e4f'
response = user.cancel_transaction(node_id: node_id, trans_id: trans_id)
```
