require "active_support/cache"

# Rails 4 builtin mem_cache_store broke hit reporting for fetch.
# This has been fixed in Rails 5.
# The dalli time consumer makes sure to require this file only for Rails 4.

class ActiveSupport::Cache::Store
  private
  # only called by fetch
  def find_cached_entry(key, name, options)
    instrument(:read, name, options) do |payload|
      payload[:super_operation] = :fetch if payload
      res = read_entry(key, options)
      payload[:hit] = !!res if payload
      res
    end
  end
end
