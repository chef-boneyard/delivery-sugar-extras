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
  module Helpers
    def version_env_key(version)
      version[0..6]
    end

    def add_all_change_data_to_node(node)
      change_file = ::File.read(::File.join("/var/opt/delivery/workspace/", 'change.json'))
      change_hash = ::JSON.parse(change_file)
      node.set['delivery']['change'].merge!(change_hash)
    end

    def get_delivery_versions(node)
      require 'artifactory'

      client = Artifactory::Client.new(
        endpoint: 'http://artifactory.opscode.us',
      )

      ## Note the version here. We are appending '-1' because artifactory
      ## returns the version as 0.3.73 in the outer versions call even though
      ## the artifact is 0.3.37-1. We'd have to make an additional call for
      ## each to get the version with '-1'. We should never have anything other
      ## than '-1' so we are encuring a bit of calculated risk here for the sake
      ## of not having to call multiple apis.
      client.get('/api/search/versions',
        repos: 'omnibus-stable-local',
        g: 'com.getchef',
        a: 'delivery')['results'].map { |e| "#{e["version"]}-1" }
    end
  end
end

module DeliverySugarExtras
  module DSL
    def version_env_key(version)
      DeliverySugarExtras::Helpers.version_env_key(version)
    end

    def add_all_change_data_to_node(node)
      DeliverySugarExtras::Helpers.add_all_change_data_to_node(node)
    end

    def get_delivery_versions(node)
      DeliverySugarExtras::Helpers.get_delivery_versions(node)
    end
  end
end
