Cachetastic Memcache Pool Adapter
----------

This is a memcached adapter for cachetastic that shares connections for caches with the same server list and mc_options configuration. The configuration for this adapter is the same as for the built-in memcached adapter.

~~~~~{ruby}
configatron.cachetastic.defaults.adapter = Cachetastic::Adapters::MemcachePool::Adapter
~~~~~
