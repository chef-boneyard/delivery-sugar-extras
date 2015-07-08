class Chef
  class Provider
    class DeliveryPublishAppAttrs < Chef::Provider::LWRPBase
      require_relative 'helpers'

      action :create do
        safe_version = new_resource.version[0..6]
        converge_by("Publish App Attrs: version #{safe_version} for #{new_resource.app_name}") do
          new_resource.updated_by_last_action(publish_app_attrs)
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

      def publish_app_attrs
        ::Chef_Delivery::ClientHelper.enter_client_mode_as_delivery
        begin
          env_name = ::DeliveryTruck::Helpers.get_acceptance_environment(node)
          to_env = Chef::Environment.load(env_name)
        rescue Net::HTTPServerException => http_e
          raise http_e unless http_e.response.code == "404"
          Chef::Log.info("Creating Environment #{env_name}")
          to_env = Chef::Environment.new()
          to_env.name(env_name)
          to_env.create
        end

        to_env.override_attributes['applications'] = {}
        to_env.override_attributes['applications'][app_name] = safe_version

        to_env.save
        ::Chef::Log.info("Set #{app_name}'s to #{safe_version} in env #{env_name}.")
        ::Chef_Delivery::ClientHelper.leave_client_mode_as_delivery
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryPublishAppAttrs < Chef::Resource::LWRPBase
      actions :create

      default_action :create

      attribute :app_name, :kind_of => String, :name_attribute => true, :required => true
      attribute :version, :kind_of => String, :required => true

      self.resource_name = :delivery_publish_app_attrs
      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryPublishAppAttrs
      end
    end
  end
end
