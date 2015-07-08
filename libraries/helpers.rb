module DeliverySugarExtras
  module Helpers
    def version_env_key(version)
      version[0..6]
    end
  end
end

module DeliverySugarExtras
  module DSL
    def version_env_key(version)
      DeliverySugarExtras::Helpers.version_env_key(version)
    end
  end
end
