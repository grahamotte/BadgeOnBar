class Sync
  class << self
    def call
      Linear.sync_statuses
      Linear.sync_tags
    end
  end
end
