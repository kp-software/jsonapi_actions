# JsonapiActions

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/jsonapi_actions`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi_actions'
```

And then execute:
```bash
$ bundle install
```

## Usage


### Basic Setup

Include the `JsonapiActions::ErrorHandling` module in your base controller.

```ruby
module Api::V1
  class BaseController < ApplicationController
    include JsonapiActions::ErrorHandling
    
    respond_to :json
  end
end
```

Include then `JsonapiActions::Controller` module in each API controller and specify the model.

```ruby
module Api::V1
  class ProjectsController < BaseController
    include JsonApiActions::Controller
    self.model = Project
  end 
end
```

NOTE: If you are not using Pundit, please see Usage without Pundit section below.

### Controller

#### serializer
Controller actions render JSON data via a Serializer.  We assume a `Model` has a `ModelSerializer`.  
To use a different serializer, define `self.serializer = OtherSerializer` on the Controller. 

```ruby
module Api::V1
  class ProjectsController < BaseController
    include JsonApiActions::Controller
    self.model = Project
    self.serializer = SecretProjectSerializer
  end 
end
```

### serialize
Response data is serialized via the `#serialize` method.  When using `FastJsonapi` we 
automatically form the request `current_user` into the params.  

If you are not using `FastJsonapi` or `ActiveModel::Serializer`, then you should override 
this method.

 ```ruby
module Api::V1
  class BaseController < ApplicationController
    include JsonapiActions::ErrorHandling
    
    respond_to :json
    
    private
     
       def serialize(data, options = {})
         { json: data }.merge(options)
       end
  end
end
 ```

## Usage without Pundit

If you are not using Pundit for authorization, then you will need to defined `#permitted_params`.  
You can optionally override methods for `#policy_scope` and `#authorize` too.

```ruby
module Api::V1
  class BaseController < ApplicationController
    include JsonapiActions::ErrorHandling
    
    respond_to :json
    
    private
    
      def permitted_params
        %i[name]
      end
      
      # This override is optional
      def policy_scope(scope)
        scope.where(user_id: current_user.id)
      end
     
      # This override is optional
      def authorize(record, query = nil)
        return if record.user == current_user
        
        raise NotAuthorized
      end
  end
end
````

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jsonapi_actions. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonapiActions project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/jsonapi_actions/blob/master/CODE_OF_CONDUCT.md).
