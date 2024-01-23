External models are models which reside in other _ATOMS_ or gems. To deal with them the best practice is to put a `concern_[model_name].rb` file in config/initializers and add the relevant `[ModelName].send(:include, Concern[GemName][ModelName])` to the file in `config/initializers/after_initialize.rb`.