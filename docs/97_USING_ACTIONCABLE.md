[[_TOC_]]

# Topics and Namespaces

If the message has a `namespace: "subscriptions"` key in the message sent, it defaults to a conventional behaviour of PING - PONG from sender to server.

Any message sent in a **Thecore** application must have a `topic` key, i.e. `{ topic: "record" }`, otherwise, only in cas of `namespace: "subscriptions"`, it can be automatically set to **general** if not provided.

Any **topic** can be added to the message. The Channel is always **ActivityLogChannel**.

## Existing Topics

- **{ topic: "general" }**: If no topic is defined in the message, it defaults to this one only if the message has a `namespace: "subscriptions"` key/value.
- **{ topic: "record" }**: This topic sends a message whenever an ActiveRecord record is created succesfully in the DB, in the message these keys are also mandatory:
  - **action**: This key holds information about the action executed on the record, be it: *create*, *update* or *destroy*.
  - **class**: This is the class of the ActiveRecord Model on which the *action* was performed.
  - **success**: Boolean indicating whether or not the *action* performed succesfully.
  - **valid**: Boolean indicating if there where validation errors.
  - **errors**: An array of validation errors.
  - **record**: The ActiveRecord Model object.
- **{ topic: "tcp_debug" }**: Exists only if the _ATOM_ [Thecore TCP Debug](https://github.com/gabrieletassoni/thecore_tcp_debug) is included in your project, it characterizes messages dealing with the PING or TCP Port Connection tests present in that Root Action. Other mandatory keys are:
  - **status**: It indicates if the test performed correctly, can assume these values:
    - *200*: The other end responded to ping or TCP connection.
    - *400*: Invalid test, thus the requested test does not exist among the available ones.
    - *503*: The other end didn't respond to ping or TCP connection.
  - **message**: A descriptive message of the test performed.

# From a Ruby script

Works also for ActiveRecord Models.

Add to the `Gemfile`, `Gemfile.base` or `*.gemspec` file the following dependency: `action_cable_client`

## Gemfile

```ruby
gem 'action_cable_client'
```

## *.gemspec file

```ruby
spec.add_dependency 'action_cable_client'
```

Then add to the `lib/[gemname].rb` the needed require:

```ruby
require 'action_cable_client'
```

## Example of usage

The following example uses the provided gem to recieve messages using ActionCable, it can be in a Model or a standalone ruby script, it does not depend on Ruby on Rails.
This example checks in the message received event for a specific topic for which to enable the business logic: **rfid_raw_tag_reading** this is a custom topic taken from an actual application, but the important thing here is that the topic key always exists in the messages which arrive through the ActionCable Channel.
The **Authorization** token is assumed received using JWT in a previous step.
The `timeout`, `websocket_url` and `channel_name` are variables assumed to be set in previous code.

```ruby
EventMachine.run do
  # Stop EventMachine after timeout seconds
  timer = EventMachine::Timer.new(timeout) { 
    EventMachine.stop 
  }

  # Create a new ActionCableClient
  # client = ActionCableClient.new(websocket_url, channel_name)
  client = ActionCableClient.new(websocket_url, channel_name, true, { 
    'Authorization' => "Bearer #{token}" 
  })
  # called whenever a welcome message is received from the server
  client.connected { 
    # Send a connection message to the server
    client.perform('receive', { message: 'On Demand Inventory Client is connected', topic: "home", namespace: "subscriptions" }) 
  }

  # called whenever a message is received from the server
  client.received do | message |
    # Accumulate the message in the array only if the message is a rfid_raw_tag_reading and the tag matches the regex and the rssi is greater than the threshold and the tag is not already present in the array and the number of unique tags is less than the expected number of unique tags and the interface is still in on_demand_inventory mode
    # Assume that the interesting topic is rfid_raw_tag_reading:
    @messages << message["message"]["message"]["uuid"] if message["message"]["topic"] == "rfid_raw_tag_reading"
    # Stop the EventMachine if the number of unique tags is equal to the expected number of unique tags
    EventMachine.stop if @messages.count >= expected_unique_tags
  end
end
```

# From a javascript node page

...