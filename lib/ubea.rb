require "ubea/config"

module Ubea
  def self.config
    @config ||= Config.default
  end
end
