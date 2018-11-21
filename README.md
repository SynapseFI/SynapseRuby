# SynapseFI-Ruby-v2

Native API library for SynapsePay REST v3.x

Not all API endpoints are supported.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'synapse_pay_rest'
```

And then execute:

```bash
$ bundle
```

Or install it yourself by executing:

```bash
$ gem install synapse_pay_rest
```
## Documentation

- [API docs](http://docs.synapsefi.com/v3.1)

## Initializing Client

- Returns Client instance 

```bash
args = {
	client_id:        "client_id",
	client_secret:    "client_secret",
	fingerprint:      "fp",
	ip_address:       'ip',
	development_mode: true
}

client  = SynapsePayRest::Client.new(args) 
```

## Creating USER

- A user is authenticated upon creation
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

## Authenticate a USER

- Grabs a user refresh_token using get_user
- Post to Oauth to authenticate user, with optional params such as scope 
- returns USER instance 

```bash
user.authenticate(** options)
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
client.get_users(** options)
```

## Gets all transactions on a platform

- returns Transactions instance 
- array of Transaction instance

```bash
trans = client.get_transaction(page: nil, per_page: nil, query: nil)
```

## Get all user specific transactions 
- User is authenticated in order for developer to fetch their transaction
- returns Transactions instance 
- array of Transaction instance

```bash
client.get_transactions(user_id)
```

## Get all User nodes
- User is authenticated in order for developer to fetch their transaction
- returns Nodes instance 
- array of Node instance

```bash
client.get_all_nodes(** options)
```

## Create subscription
- scope must be an array or else method will raise an error
- returns subscription instace 

```bash
scope = ["TRAN|PATCH"]
url = "webhooks.com"
client.create_subscriptions(scope: scope, url: url )
```

## Get all platforms subscription
- Developer has option to 

```bash
client.get_all_subscriptions(** options)
```

## Geta subscription by id
- returns a subscription instance 

```bash
subscription_id = "2342324"
client.get_subscription(subscriptions_id)
```

## Update Subscription 

- updates a subscription scope or url 
- returns a subscription instance 

```bash
subscription_id = "2342324"
scope = ["TRAN|PATCH"]
client.update_subscriptions(subscription_id: subscription_id , scope: scope)
```

## Issue Public Key
- returns api response 

```bash
scope = ["USERS|GET"]
client.issue_public_key(scope: scope)
```

## Dummy Transactions 

- initiates a dummy transaction to a node

```bash
user_id = "1234"
node = "4321"
client.dummy_transactions(user_id: user_id,node_id: node_id)
```




