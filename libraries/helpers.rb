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

module DeliverySugarExtras
  #
  # Helpers Module for general purposes
  #
  module Helpers
    module_function

    def version_env_key(version)
      version[0..6]
    end

    def add_all_change_data_to_node(node)
      change_file = ::File.read(::File.join("/var/opt/delivery/workspace/", 'change.json'))
      change_hash = ::JSON.parse(change_file)
      node.set['delivery']['change'].merge!(change_hash)
    end

    def get_delivery_versions(node)
      require 'mixlib/install'

      # NOTE: This is using a mixlib-install private API as we still need
      #       to add returning a list of versions for a product to the
      #       public APIs.
      backend = Mixlib::Install::Backend::Bintray.new(nil)
      # The versions array returned by this API call is ordered so the
      # latest release is item zero in the array!
      backend.bintray_get("/stable/delivery")['versions']
    end
  end

  # Module that exposes multiple helpers
  module DSL
    def version_env_key(version)
      DeliverySugarExtras::Helpers.version_env_key(version)
    end

    def add_all_change_data_to_node
      DeliverySugarExtras::Helpers.add_all_change_data_to_node(node)
    end

    def get_delivery_versions
      DeliverySugarExtras::Helpers.get_delivery_versions(node)
    end
  end
end
