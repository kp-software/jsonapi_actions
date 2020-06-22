# JsonapiActions

Instantly create flexible API controllers that are compatible with [JSON:API](https://jsonapi.org/). 
Utilize your existing [JSONAPI::Serializer](https://github.com/jsonapi-serializer/jsonapi-serializer), 
[FastJsonapi](https://github.com/Netflix/fast_jsonapi), or 
[ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers) serialization library, or bring your 
own. Scope and authenticate with optional [Pundit](https://github.com/varvet/pundit) policies and/or Controller specific 
methods. 

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

Include `JsonapiActions` in your base controller.

```ruby
# app/controllers/api/v1/base_controller.rb
module Api::V1
  class BaseController < ApplicationController
    include JsonApiActions
    
    respond_to :json
  end
end
```

Define the Model for each child Controller.

```ruby
# app/controllers/api/v1/projects_controller.rb
module Api::V1
  class ProjectsController < BaseController
    self.model = Project
  end 
end
```

Define your routes.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :projects
    end
  end
end
```

### parent_scope
Index actions can be scoped by parent associations.  i.e. nested routes.

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :user 
end

# config/routes.rb
Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      # /api/v1/projects
      resources :projects
      
      resources :users do
        # /api/v1/users/:user_id/projects
        resources :projects
      end
    end
  end
end

# app/controllers/api/v1/projects_controller.rb
module Api::V1
  class ProjectsController < BaseController
    self.model = Project
    self.parent_associations = [
      # When Using using attribute on the model
      #   Project.where(user_id: params[:user_id]) 
      { param: :user_id, attribute: :user_id }, 
      
      # When using attribute on the associated model
      #   Project.joins(:user).where(users: { id: params[:user_id] }) 
      { param: :user_id, association: :user, table: :users, attribute: :id } 
    ]
  end 
end
```

### Custom Actions (Non-CRUD)
You can easily utilize JsonapiActions in custom controller actions too.  Just call `#set_record` to 
initialize `@record` and when you're done `render response(@record)`

```ruby
# app/controllers/api/v1/projects_controller.rb
module Api::V1
  class ProjectsController < BaseController
    self.model = Project
    
    def activate
      set_record
      @record.activate!
      render response(@record)
    rescue ActiveRecord::RecordInvalid
      render unprocessable_entity(@record)
    end
  end 
end
```

### #serializer
Controller actions render JSON data via a Serializer.  We assume a `Model` has a `ModelSerializer`. To use a 
different serializer, define `self.serializer = OtherSerializer` on the Controller. 

```ruby
# app/controllers/api/v1/base_controller.rb
module Api::V1
  class ProjectsController < BaseController
    self.model = Project
    self.serializer = SecretProjectSerializer
  end 
end
```

### #json_response
Response data is formatted so that it can be rendered with `JSONAPI::Serializer`, `FastJsonapi`, or `ActiveModel::Serializer`.
If you are using a different serializer, or would like to further change the response.  Then you will need to override
`#response`, which defines the arguments for `render`.

 ```ruby
# app/controllers/api/v1/base_controller.rb
module Api::V1
  class BaseController < ApplicationController
    include JsonapiActions
    
    respond_to :json
    
    private
     
       def json_response(data, options = {})
         { json: data }.merge(options)
       end
  end
end
 ```

## Pundit

JsonapiActions is built to use Pundit for authorization.  We utilize action authorization, policy scope, 
and permitted params.

```ruby
# app/policies/project_policy.rb
class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end
  
  def show?
    record.user == user
  end
   
  def create?
    record.user == user
  end
    
  def update?
    record.user == user  
  end
    
  def destroy?
    record.user == user  
  end
  
  def permitted_params
    %i[user_id name]
  end
  
  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
```

### Usage without Pundit

If you are not using Pundit for authorization, then you will need to defined `#permitted_params`.  
You can optionally override methods for `#policy_scope` and `#authorize` too.

```ruby
module Api::V1
  class BaseController < ApplicationController
    include JsonapiActions::ErrorHandling
    
    respond_to :json
    
    private
    
      def permitted_params
        %i[user_id name]
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
