[[_TOC_]]

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
  @messages << message["message"]["message"]["uuid"] if message["message"]["topic"] == "rfid_raw_tag_reading" && message["message"]["message"]["uuid"].match(regex) && message["message"]["message"]["rssi"].to_i > threshold.to_i && !@messages.include?(message["message"]["message"]["uuid"]) && @messages.count < expected_unique_tags && Interface.find_by(address: address).on_demand_inventory
  # Stop the EventMachine if the number of unique tags is equal to the expected number of unique tags
  EventMachine.stop if @messages.count >= expected_unique_tags
end
```

# From a javascript node page

...