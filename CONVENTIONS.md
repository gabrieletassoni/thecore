# Naming

- _ATOMS_ and *gems* are interchangeable.
- `lib/[this_atom_name].rb` and similar, indicates the file, named after the current gem name, which resides in lib.
- `require '[other_atom]'` and similar, indicates the name of another gem on which the current one is dependant.

# ATOMS

## `*.gemspec` file

An _ATOM_ can depend on these two base thecore ATOMS. They can added together or just once, be the ATOM an API only gem or a gem which delivers functionalities useful for a GUI experience.

```ruby
s.add_dependency 'thecore_ui_rails_admin', '~> 3.0'
s.add_dependency 'model_driven_api', '~> 3.0'
```

The _ATOM_ can depend also on another _ATOM_, at which point `thecore_ui_rails_admin` and/or `model_driven_api` are already included in the dependency chain and only the other _ATOM_ needs to be added as a dependency.

### Autoload the dependency

It's advised to add in the `lib/[this_atom_name].rb` file all the **requires** pointing to depending _ATOMS_, for example, whenever you add a dependency in the `*.gemspec` file, please add the relevant `require '[other_atom]'` to the `lib/[this_atom_name].rb` of the current _ATOM_ you are developing.

## Javascripts

### Action Based

### In HTML.ERB files

# THECORE APP

## Dependencies

In the thecore APP the preferred way to integrate your code is by putting in the Gemfile.base the ATOM which depends on the base thecore ATOMS: [Model Driven API](https://github.com/gabrieletassoni/model_driven_api) and [Thecore UI Rails Admin](https://github.com/gabrieletassoni/thecore_ui_rails_admin). These are added in a separate way to allow developer to focus on the needed aspects of the application, UI or API based.

```ruby
gem 'your_business_logic_atom', '~> 3.0'
```
