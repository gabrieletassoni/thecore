[[_TOC_]]

# Model Driven Api

## Goals

* To have a comprehensive and meaningful Model driven API right out of the box by just creating migrations in your rails app or engine. With all the CRUD operations in place out of the box and easily expandable with custom actions if needed.
* To have a plain REST implementation which adapts the returned JSON to the specific needs of the client, **without the need to change backend code**, this may overcome the biggest disadvantage of REST vs GraphQL = client driver presentation.

## TL;DR 5-10 minutes adoption

1. Add this line to your application's Gemfile or as a dependency for your engine gem: ```gem 'model_driven_api'```
2. Run from the shell: ```bundle install```
3. Add needed models, like: 
  ```bash
  rails g migration AddLocation name:string:index description:text:index
  rails g migration AddProduct name:string:index code:string:uniq location:references
  # Any other migration(s) you need... 
  ``` 
4. Run the migrations: ```rails db:migrate```
4. Run the migrations: ```rails thecore:db:seed```
5. Bring up your dev server: ```rails s```
6. Use **[Insomnia](https://github.com/Kong/insomnia)** rest client to try the endpoints by importing [the API v2 tests](../samples/insomnia/ApiV2Tests.json) and edit the environment variables as needed.

This will setup a *User* model, *Role* model, *Permissions* model and the HABTM table between these + any added model you created at the step 3.

The default admin user created during the migration step has a randomly generated password you can find in a .passwords file in the root of your project, that's the initial password, in production you can replace that one, but for testing it proved handy to have it promptly available.

## Forewords

I've always been interested in effortless, no-fuss, conventions' based development, DRYness, and pragmatic programming, I've always thought that at this point of the technology evolution, we need not to configure too much to have our software run, having the software adapt to data layers and from there building up APIs, visualizations, etc. in an automatic way. This is a first step to have a schema driven API or better model drive, based on the underlining database, the data it has to serve and some sane dafults, or conventions. This effort also gives, thanks to meta programming, an insight on the actual schema, via the info API, the translations available and the DSL which can change the way the data is presented, leading to a strong base for automatica built of UIs consuming the API (react, vue, angular based PWAs, maybe! ;-) ).

Doing this means also narrowing a bit the scope of the tools, taking decisions, at least for the first implementations and versions of this engine, so, this works well if the data is relational, this is a prerequisite (postgres, mysql, mssql, etc.).

## REST Enhanced

Thanks to the inclusion of [Ransack](https://github.com/activerecord-hackery/ransack/wiki) and [ActiveModel::Serializer](https://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html), by just adding the querystring keys **q** and **a**, you can create complex queries (q) to obtain just the records you need, which present in the returnd JSON just the attributes (a) needed.
By combining the two keys, you can obtain just the data you want.

The *json_attrs* or *a* query string passed accepts these keys (Please see [ActiveModel::Serializer](https://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html) for reference):
- only: list [] of model fields to be shown in JSON serialization
- except: exclude these fields from the JSON serialization, this is a list []
- methods: include the result of some methods defined in the model, this is a list []
- include: include associated models, it's an object {} which also accepts the keys described in this document (only, except, methods, include)

### Example

```
{{ base_url  }}/{{ controller  }}?a[only][]=locked&a[only][]=username&a[methods][]=jwe_data
```

Is translated to:

```
{a: {only: ["locked", "username"], methods: ["jwe_data"]}}
```

Which tells the API controller just to return this optimized serialization:

```
[
  {
    "username": "Administrator",
    "locked": false,
    "jwe_data": "eyJhbGciOiJkaXIiLCJlbmMiOiJSMTI4R0NNIn0..yz0tnC6y3BzgoOsO.BjHb9CRIb0vrv7nnEx54Ac8-cATPJ9sTlQSSxRbTmtcPHc5KhvtyE_hyBRnIcK92bzUBRwdy6ASB2XJVy1VfWxAmO8E.4tOzJlfuXi-shaRhDSkOyg"
  }
]
```

By combinig with Ransack's **q** query string key (please read [Ransack](https://github.com/activerecord-hackery/ransack/wiki) documentation to discover all the possible and complex searches you can make), you can obtain right what you want:

```
{{ base_url  }}/{{ controller  }}?a[only][]=locked&a[only][]=username&a[methods][]=jwe_data&q[email_cont][]=adm
```

Which translates to:

```
{a: {only: ["locked", "username"], methods: ["jwe_data"]}, q: { email_cont: ["adm"]}}
```

For bigger searches, which may over crowd the querystring length, you can always use the default [Search](#Search) POST endpoint.

## v2?

Yes, this is the second version of such an effort and you can note it from the api calls, which are all under the ```/api/v2``` namespace the [/api/v1](https://github.com/gabrieletassoni/thecore_api) one, was were it all started, many ideas are ported from there, such as the generation of the automatic model based crud actions, as well as custom actions definitions and all the things that make also this gem useful for my daily job were already in place, but it was too coupled with [thecore](https://github.com/gabrieletassoni/thecore)'s [rails_admin](https://github.com/sferik/rails_admin) UI, making it impossible to create a complete UI-less, API only application, out of the box and directly based of the DB schema, with all the bells and whistles I needed (mainly self adapting, data and schema driven API functionalities).
So it all began again, making a better thecore_api gem into this model_driven_api gem, more polished, more functional and self contained.

## What has changed

* Replace v1 with **v2** in the url
* **Custom actions** defined in model's concerns now are triggered by a do querystring, for example: ```/api/v2/:model?do=custom_action``` or ```/api/v2/:model/:id?do=custom_action```
* Searches using Ransack can be done either by GET or POST, but POST is preferred.

## Standards Used

* [JWT](https://github.com/jwt/ruby-jwt) for authentication.
* [CanCanCan](https://github.com/CanCanCommunity/cancancan) for authorization.
* [Ransack](https://github.com/activerecord-hackery/ransack) query engine for complex searches going beyond CRUD's listing scope.
* Catch all routing rule to automatically add basic crud operations to any AR model in the app.

## API

All the **Models** of *WebApp* follow the same endpoint specification as a standard. The only deviations to the normally expected **CRUD** endpoints are for the **authenticate** controller and the **info** controller described below. This is due to their specific nature, which is not the common **CRUD** interaction, but to provide specifically a way to retrieve the **[JWT](https://jwt.io/)** or retrieve low level information on the **structure** of the API.

### Return Values

The expected return values are:

 - **200** *success*: the request performed the expected action.
 - **401** *unauthenticated*: username, password or token are invalid.
 - **403** *unauthorized*: the user performing the action is authenticated, but doesn't have the permission to perform it.
 - **404** *not found*: the record or custom action is not present in the 
 - **422** *invalid*: the specified body of the request has not passed the validations for the model.
 - **500** *errors on the platform*: usually this means you found a bug in the code.

### Getting the Token

The first thing that must be done by the client is to get a Token using the credentials:

```bash
POST http://localhost:3000/api/v2/authenticate
```

with a POST body like the one below:

```json
{
	"auth": {
		"email": "<REPLACE>",
		"password": "<REPLACE>"
	}
}
```

This action will return in the **header** a *Token* you can use for the following requests.
Bear in mind that the *Token* will expire within 15 minutes and that at **each successful** request a ***new*** token is returned using the same **header**, so, at each interaction between client server, just making an authenticated and successful request, will give you back a way of continuing to make **authenticated requests** without the extra overhead of an authentication for each one and without having to keep long expiry times for the *Token*.

Keep in mind that the Token, if decoded, bears the information about the expiration time as part of the payload.

#### Authenticated Requests

Once the JWT has been retrieved, the **Authenticated Request**s must use it in a header of Bearer Type like this one:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE1OTA3NzQyMzR9.Z-1yECp55VD560UcB7gIhgVWJNjn8HUerG5s4TVSRko
```

 #### Token Refresh
 
If issued during the token validity period, this will just return a new JWT to be used during following API request.

```bash
:GET http://localhost:3000/api/v2/info/heartbeat
```

### CRUD Actions

All the interactions with the **Models** are **Authenticated Request** (see below for reference on **Getting the Token**), all the models have the following six **CRUD** actions and the **custom** actions defined for them in addition (see below for reference to custom actions in the **Schema** section of the **Info** controller):

#### List

Returns a list of all the records for the models specified by the expected fields as per **DSL** section below.
Example request for **users** model:

```bash
GET http://localhost:3000/api/v2/users
```

#### Search

Returns a list of all the records for the models specified by the expected fields as per **DSL** section below, the returned records are **filtered** by the **search predicates** you can find in the body of the request:
Example request for **users** model:

```bash
POST http://localhost:3000/api/v2/users/search
```

Example of the body of the request (*q* means **question**, the *_eq* particle means **equals**, so in this simple example I'm looking for records which have the *id* attribute set to 1, mimicking the **Show** action below):

```json
{
  "q":{
    "id_eq": 1
  }
}
```

The complete documentation of the predicates that can be used is provided by the **[Ransack](https://github.com/activerecord-hackery/ransack)** library, the filtering, ordering, grouping options are really infinite.

#### Create

Creates a record for the specified **Model**.
Validations on the data sent are triggered.
Example request for **users** model:

```bash
POST http://localhost:3000/api/v2/users
```

Example of the body of the request:

```json
{
  "user":  {
    "email": "prova@example.com",
    "admin": false,
    "password": "prova63562",
    "password_confirmation": "prova63562"
  }
}
```

#### Show

Retrieves a single record as specified by the expected fields as per **DSL** section below.
Example request for **users** model (retrieves the record with ID = 1):

```bash
GET http://localhost:3000/api/v2/users/1
```

#### Edit

Changes the value of one or more attributes for the specified model. In the body of the PUT request you can just use the attributes you want to change, it's **not** necessary to use all the attributes of the record.
Example request for **users** model with ID = 1:

```bash
PUT http://localhost:3000/api/v2/users/1
```

Example of the body of the request:

```json
{
  "user": {
    "email": "ciao@example.com"
  }
}
```

#### Delete

Deletes the specified record.
Example request for **users** model with ID = 1:

```bash
DELETE http://localhost:3000/api/v2/users/1
```

#### Custom Actions

Are triggered by a **do** querystring, for example: `GET /api/v2/:model?do=custom_action` or `GET /api/v2/:model/:id?do=custom_action` respectively for a custom action which works on the entire records collection or a custom action which works on the specific record identified by :id.

### Info API

The info API **/api/v2/info/** can be used to retrieve general information about the REST API.

#### Version

By issuing a GET on this api, you will get a response containing the version of *WebApp*. 
This is a request which **doesn't require authentication**, it could be used as a checkpoint for consuming the resources exposed by this engine.

Example:

```bash
GET http://localhost:3000/api/v2/info/version
```

Would produce a response body like this one:

```json
{
  "version": "2.1.14"
}
```

#### Roles

**Authenticated Request** by issuing a GET request to */api/v2/info/roles*:

```bash
GET http://localhost:3000/api/v2/info/roles
```

Something like this can be retrieved:

```json
[
  {
    "id": 1,
    "name": "role-1586521657646",
    "created_at": "2020-04-10T12:27:38.061Z",
    "updated_at": "2020-04-10T12:27:38.061Z",
    "lock_version": 0
  },
  {
    "id": 2,
    "name": "role-1586522353509",
    "created_at": "2020-04-10T12:39:14.276Z",
    "updated_at": "2020-04-10T12:39:14.276Z",
    "lock_version": 0
  }
]
```

#### Schema

**Authenticated Request** This action will send back the *authorized* models accessible by the **User** owner of the *Token* at least for the [:read ability](https://github.com/ryanb/cancan/wiki/checking-abilities). The list will also show the field types of the model and the associations.

By issuing this GET request:

```bash
GET http://localhost:3000/api/v2/info/schema
```

You will get something like:

```json
{
  "users": {
    "id": "integer",
    "email": "string",
    "encrypted_password": "string",
    "admin": "boolean",
    "lock_version": "integer",
    "associations": {
      "has_many": [
        "role_users",
        "roles"
      ],
      "belongs_to": []
    },
    "methods": null
  },
  "role_users": {
    "id": "integer",
    "created_at": "datetime",
    "updated_at": "datetime",
    "associations": {
      "has_many": [],
      "belongs_to": [
        "user",
        "role"
      ]
    },
    "methods": null
  },
  "roles": {
    "id": "integer",
    "name": "string",
    "created_at": "datetime",
    "updated_at": "datetime",
    "lock_version": "integer",
    "associations": {
      "has_many": [
        "role_users",
        "users"
      ],
      "belongs_to": []
    },
    "methods": null
  }
}
```

The ***associations***: key lists the relations between each model and the associated models, be them a n:1 (belongs_to) or a n:m (has_many) one.
The ***methods*** key will list the **custom actions** that can be used in addition to normal CRUD operations, these are usually **bulk actions** or any computation that can serve a specific purpose outside the basic CRUD scope used usually to simplify the interaction between client and server (i.e. getting in one request the result of a complex computations which usually would be sorted out using more requests).

#### DSL

**Authenticated Request** This action will send back, for each model, which are the fields to be expected in the returning JSON of each request which has a returning value.
This information can complement the **Schema** action above output by giving information on what to expect as returned fields, associations and aggregates (methods) from each **READ** action of the **CRUD**.  It can be used both to *validate* the returned values of a **LIST** or a **SHOW** or to *drive* UI generation of the clients.

By issuing this GET request:

```bash
GET http://localhost:3000/api/v2/info/dsl
```

You will get something like:

```json
{
  "users": {
    "except": [
      "lock_version",
      "created_at",
      "updated_at"
    ],
    "include": [
      "roles"
    ]
  },
  "roles": {
    "except": [
      "lock_version",
      "created_at",
      "updated_at"
    ],
    "include": [
      {
        "users": {
          "only": [
            "id"
          ]
        }
      }
    ]
  },
  "role_users": null
}
```

#### Translations

**Authenticated Request** This action will send back, all the **translations** of *model* names, *attribute* names and any other translation defined in the backend.
This can be used by the UI clients to be aligned with the translations found in the Backend.
The locale for which the translation is requested can be specified by the querystring *locale*, it defaults to **it**.
For **Model** translations, the ones used more, the key to look for is ***activerecord*** and subkeys **models** and **attributes**.

By issuing this GET request:

```bash
GET http://localhost:3000/api/v2/info/translations?locale=it
```

You will get smething like (incomplete for briefness):

```json
{
  "activerecord": {
    "attributes": {
      "user": {
        "confirmation_sent_at": "Conferma inviata a",
        "confirmation_token": "Token di conferma",
        "confirmed_at": "Confermato il",
        "created_at": "Data di Creazione",
        "current_password": "Password corrente",
        "current_sign_in_at": "Accesso corrente il",
        "current_sign_in_ip": "IP accesso corrente",
        "email": "E-Mail",
        "encrypted_password": "Password criptata",
        "failed_attempts": "Tentativi falliti",
        "last_sign_in_at": "Ultimo accesso il",
        "last_sign_in_ip": "Ultimo IP di accesso",
        "locked_at": "Bloccato il",
        "password": "Password",
        "password_confirmation": "Conferma Password",
        "remember_created_at": "Ricordami creato il",
        "remember_me": "Ricordami",
        "reset_password_sent_at": "Reset password inviata a",
        "reset_password_token": "Token di reset password",
        "sign_in_count": "Numero di accessi",
        "unconfirmed_email": "Email non confermata",
        "unlock_token": "Token di sblocco",
        "updated_at": "Aggiornato il",
        "username": "Nome Utente",
        "code": "Codice",
        "roles": "Ruoli",
        "admin": "Amministratore?",
        "locked": "Bloccato?",
        "third_party": "Ente Terzo?"
      },
      "role": {
        "users": "Utenti",
        "name": "Nome",
        "permissions": "Permessi"
      },
      "permission": {
        "predicate": "Predicato",
        "action": "Azione",
        "model": "Modello"
      },

      [ ... ]
}
```

## Testing

If you want to manually test the API using [Insomnia](https://insomnia.rest/) you can find the chained request in Insomnia v4 json format inside the **test/insomnia** folder.
Once loaded the tests inside the insomnia application, please right click on the folder, then in the menu select *</> Environment* and change ```base_url```, ```email``` and ```password``` as needed to set them for all the subsequent actions.

## TODO

## References
Thanks to all these people for ideas:

* [Billy Cheng](https://medium.com/@billy.sf.cheng/a-rails-6-application-part-1-api-1ee5ccf7ed01) For a way to have a nice and clean implementation of the JWT on top of Devise.
* [Daniel](https://medium.com/@tdaniel/passing-refreshed-jwts-from-rails-api-using-headers-859f1cfe88e9) For a smart way to manage token expiration.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
