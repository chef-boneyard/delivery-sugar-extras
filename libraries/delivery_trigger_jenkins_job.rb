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
    class DeliveryTriggerJenkinsJob < Chef::Provider::LWRPBase
      action :run do
        converge_by("Trigger Jenkins Job: #{new_resource.job} for #{new_resource.name}") do
          new_resource.updated_by_last_action(run_jenkins_job)
        end
      end

      private

      SLEEP_TIME ||= 15

      def server
        @server ||= new_resource.server
      end

      def port
        @port ||= new_resource.port
      end

      def username
        @username ||= new_resource.username
      end

      def password
        @password ||= new_resource.password
      end

      def password_base64
        @password_base64 ||= new_resource.password_base64
      end

      def job
        @job ||= new_resource.job
      end

      def params
        @params ||= new_resource.params
      end

      def timeout
        @timeout ||= new_resource.timeout
      end

      def dec_timeout(number)
        @timeout -= number
      end

      def run_jenkins_job
        origin = timeout

        ::Chef::Log.info("Will wait up to #{timeout/60} minutes for " +
                         "jenkins job to complete...")

        jenkins_client = ::JenkinsApi::Client.new(:server_url => server,
                                                  :server_port => port,
                                                  :username => username,
                                                  :password => password,
                                                  :password_base64 => password_base64)
        job_opts = {'build_start_timeout' => timeout}
        job_params = params
        jenkins_client.job.build(job, job_params, job_opts)

        previous_status = 'running'
        ::Chef::Log.info("Jenkins Job Status: #{previous_status}")

        begin
          # Sleep unless this is our first time through the loop.
          sleep(SLEEP_TIME) unless timeout == origin

          status = jenkins_client.job.get_current_build_status(job)
          if status != previous_status
            ::Chef::Log.info("Jenkins Job Status: #{status}")
            previous_status = status
          end

          ## Check for success
          if status == 'success'
            ::Chef::Log.info("Jenkins Job Successful.")
            break
          elsif status == 'failure'
            ::Chef::Log.info("Jenkins Job Failed.")
            raise "Jenkins Job Failed!!!"
          end

          dec_timeout(SLEEP_TIME)
        end until timeout <= 0
        raise "Jenkins Job Timed Out!!!" if status != 'success'
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryTriggerJenkinsJob < Chef::Resource::LWRPBase
      actions :run

      default_action :run

      attribute :server, :kind_of => String
      attribute :port, :kind_of => Integer, :default => 8080
      attribute :username, :kind_of => String
      attribute :password, :kind_of => String
      attribute :password_base64, :kind_of => String
      attribute :job,  :kind_of => String
      attribute :params,  :kind_of => Hash, :default => {}
      attribute :timeout, :kind_of => Integer,  :default => 30 * 60 # 30 mins

      self.resource_name = :delivery_search_trigger_jenkins_job
      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryTriggerJenkinsJob
      end
    end
  end
end
