# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Provider
    class DeliveryCreateAppDb < Chef::Provider::LWRPBase
      require_relative 'helpers'

      action :create do
        converge_by("Create App Databag: version #{safe_version} for #{new_resource.app_name}") do
          new_resource.updated_by_last_action(create_databag)
        end
      end

      private

      def app_name
        @app_name ||= new_resource.app_name
      end

      def version
        @version ||= new_resource.version
      end

      def safe_version
        @safe_version ||= version_env_key(new_resource.version)
      end

      def data
        @data ||= new_resource.data
      end

      def create_databag
        # Create the data bag
        ::Chef_Delivery::ClientHelper.enter_client_mode_as_delivery
        begin
          bag = Chef::DataBag.new
          bag.name(app_name)
          bag.create
        rescue Net::HTTPServerException => e
          if e.response.code == "409"
            ::Chef::Log.info("DataBag #{app_name} already exists.")
          else
            raise
          end
        end

        dbi_hash = {
          "id"       => safe_version,
          "version"  => version,
          "data" => data
        }

        bag_item = Chef::DataBagItem.new
        bag_item.data_bag(app_name)
        bag_item.raw_data = dbi_hash
        bag_item.save
        ::Chef::Log.info("Saved bag item #{dbi_hash} in data bag #{app_name}.")
        ::Chef_Delivery::ClientHelper.leave_client_mode_as_delivery
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryCreateAppDb < Chef::Resource::LWRPBase
      actions :create

      default_action :create

      attribute :app_name, :kind_of => String, :name_attribute => true, :required => true
      attribute :version, :kind_of => String, :required => true
      attribute :data, :kind_of => Hash

      self.resource_name = :delivery_create_app_db
      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryCreateAppDb
      end
    end
  end
end
