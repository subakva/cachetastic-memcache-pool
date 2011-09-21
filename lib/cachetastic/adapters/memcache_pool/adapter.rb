module Cachetastic # :nodoc:
  module Adapters
    module MemcachePool
      # An adapter to cache objects to the file system.
      # 
      # This adapter supports the following configuration settings,
      # in addition to the default settings:
      # 
      #   configatron.cachetastic.defaults.servers = ['127.0.0.1:11211']
      #   configatron.cachetastic.defaults.mc_options = {:c_threshold => 10_000,
      #                                                  :compression => true,
      #                                                  :debug => false,
      #                                                  :readonly => false,
      #                                                  :urlencode => false}
      #   configatron.cachetastic.delete_delay = 0
      # 
      # The <tt>servers</tt> setting defines an <tt>Array</tt> of Mecached
      # servers, represented as "<host>:<port>".
      # 
      # The <tt>mc_options</tt> setting is a <tt>Hash</tt> of settings required
      # by Memcached. See the Memcached documentation for more information on
      # what the settings mean.
      # 
      # The <tt>delete_delay</tt> setting tells Memcached how long to wait
      # before it deletes the object. This is not the same as <tt>expiry_time</tt>.
      # It is only used when the <tt>delete</tt> method is called.
      # 
      # See <tt>Cachetastic::Adapters::Base</tt> for a list of public API
      # methods.
      class Adapter < Cachetastic::Adapters::Base
        
        def initialize(klass) # :nodoc:
          define_accessor(:servers)
          define_accessor(:mc_options)
          define_accessor(:delete_delay)
          self.delete_delay = 0
          self.servers = ['127.0.0.1:11211']
          self.mc_options = {:c_threshold => 10_000,
                             :compression => true,
                             :debug => false,
                             :readonly => false,
                             :urlencode => false}
          super
          connection
        end
        
        def get(key) # :nodoc:
          connection.get(transform_key(key), false)
        end # get
        
        def set(key, value, expiry_time = configatron.cachetastic.defaults.default_expiry) # :nodoc:
          connection.set(transform_key(key), marshal(value), expiry_time, false)
        end # set
        
        def delete(key) # :nodoc:
          connection.delete(transform_key(key), self.delete_delay)
        end # delete
        
        def expire_all # :nodoc:
          increment_version
          return nil
        end # expire_all
        
        def transform_key(key) # :nodoc:
          namespace + ':' + key.to_s.hexdigest
        end
        
        # Return <tt>false</tt> if the connection to Memcached is
        # either <tt>nil</tt> or not active.
        def valid?
          return false if @_mc_connection.nil?
          return false unless @_mc_connection.active?
          return true
        end
        
        private
        def connection
          self.class.data_connection(self)
        end

        def ns_connection
          self.class.ns_connection(self)
        end

        def increment_version
          name = self.klass.name
          v = get_version
          ns_connection.set(name, v + 1)
        end

        def get_version
          name = self.klass.name
          v = ns_connection.get(name)
          if v.nil?
            ns_connection.set(name, 1)
            v = 1
          end
          v
        end
        
        def namespace
          @_ns_version = get_version
          "#{self.klass.name}.#{@_ns_version}"
        end

        class << self
          # JDW: TODO: Extract all of this into a MemCachePool class, and add the ability to do true thread-safe pooling
          def reset_connections
            @_connections_by_klass = {}
            @_connections_by_digest = {}
            @_ns_connections_by_klass = {}
            @_ns_connections_by_digest = {}
          end

          def connection_digest(adapter)
            {:servers => adapter.servers, :mc_options => adapter.mc_options}.to_s.hexdigest
          end

          def data_connection(adapter)
            @_connections_by_klass   ||= {}
            @_connections_by_digest  ||= {}
            return get_connection(adapter, @_connections_by_klass, @_connections_by_digest, nil)
          end

          def ns_connection(adapter)
            @_ns_connections_by_klass   ||= {}
            @_ns_connections_by_digest  ||= {}
            return get_connection(adapter, @_ns_connections_by_klass, @_ns_connections_by_digest, :namespace_versions)
          end

          def get_connection(adapter, connections_by_class, connections_by_digest, namespace)
            matching_connection = connections_by_class[adapter.klass.name]
            if !matching_connection || !matching_connection.active?
              digest = connection_digest(adapter)
              matching_connection = connections_by_digest[digest]
              if !matching_connection || !matching_connection.active?
                matching_connection = MemCache.new(adapter.servers, adapter.mc_options.merge(:namespace => namespace))
              end
              connections_by_digest[digest] = matching_connection
            end
            connections_by_class[adapter.klass.name] = matching_connection
            matching_connection
          end
        end

      end # Adapter
    end # MemcachePool
  end # Adapters
end # Cachetastic
