# These files create / add to the Delivery::DSL module
require_relative 'helpers'

# And these mix the DSL methods into the Chef infrastructure
Chef::Recipe.send(:include, DeliverySugarExtras::DSL)
Chef::Resource.send(:include, DeliverySugarExtras::DSL)
Chef::Provider.send(:include, DeliverySugarExtras::DSL)
