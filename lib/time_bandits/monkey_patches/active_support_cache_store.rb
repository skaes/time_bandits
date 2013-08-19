require "active_support/cache"

# rails 4 builtin mem_cache_store broke hit reporting for fetch
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
