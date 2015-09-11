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
    class DeliveryStageDb < Chef::Provider::LWRPBase
      provides :delivery_stage_db

      use_inline_resources

      action :create do
        converge_by("Create Stage Databag Item: #{node['delivery']['stage']} from node.run_state['delivery']['stage']['data']") do
          new_resource.updated_by_last_action(create_databag)
        end
      end

      action :download do
        converge_by("Downloading Stage Databag Item: #{node['delivery']['stage']} to node.run_state['delivery']['stage']['data']") do
          new_resource.updated_by_last_action(download_databag)
        end
      end

      private

      def create_databag
        # Create the data bag
        begin
          bag = Chef::DataBag.new
          bag.name(db_name)

          DeliverySugar::ChefServer.new.with_server_config do
            bag.create
          end
        rescue Net::HTTPServerException => e
          if e.response.code == "409"
            ::Chef::Log.info("DataBag #{db_name} already exists.")
          else
            raise
          end
        end

        dbi_hash = {
          "id"       => dbi_id,
          "data" => node.run_state['delivery']['stage']['data']
        }

        ## TODO: Merge instead of always creating a new one?
        bag_item = Chef::DataBagItem.new
        bag_item.data_bag(db_name)
        bag_item.raw_data = dbi_hash

        DeliverySugar::ChefServer.new.with_server_config do
          bag_item.save
        end
        ::Chef::Log.info("Saved bag item #{dbi_id} in data bag #{db_name}.")
      end

      def download_databag
        dbi = DeliverySugar::ChefServer.new.with_server_config do
          data_bag_item(db_name, dbi_id)
        end

        node.run_state['delivery'] ||= {}
        node.run_state['delivery']['stage'] ||= {}
        node.run_state['delivery']['stage']['data'] ||= dbi['data']
      end

      def db_name
        @db_name ||= 'delivery_stages'
      end

      def dbi_id
        @dbi_id if @dbi_id

        ::DeliverySugarExtras::Helpers.add_all_change_data_to_node(node)

        change = node['delivery']['change']

        delivery_server = URI(node['delivery']['change']['delivery_api_url'])
          .host

        @dbi_id = "#{delivery_server}_#{change['enterprise']}" \
                  "_#{change['organization']}_#{change['project']}" \
                  "_#{change['pipeline']}"
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryStageDb < Chef::Resource::LWRPBase
      actions :create, :download

      default_action :create

      self.resource_name = :delivery_stage_db

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryStageDb
      end
    end
  end
end

class Chef
  module DSL
    module Recipe
      @@next_delivery_stage_db_index = 0

      def delivery_stage_db_name
        @@next_delivery_stage_db_index += 1
        if @@next_delivery_stage_db_index > 1
          "default#{@@next_delivery_stage_db_index}"
        else
          "default"
        end
      end

      def delivery_stage_db(name = nil, &block)
        name ||= delivery_stage_db_name
        declare_resource(:delivery_stage_db, name, caller[0]) do
          instance_eval(&block) if block_given?
        end
      end
    end
  end
end
