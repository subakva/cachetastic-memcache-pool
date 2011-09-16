require 'spec_helper'

describe Cachetastic::Adapters::MemcachePool::Adapter do
  before(:each) do
    configatron.temp_start
    configatron.cachetastic.defaults.adapter = Cachetastic::Adapters::MemcachePool::Adapter
  end

  # before(:each) do
  #   pending 'JDW: This is an integration test. It requires a memcached server to be running on localhost:11211'
  # end

  after(:each) do
    configatron.temp_end
  end

  class FakeCacheClass; end
  class AnotherFakeCacheClass; end
  
  it "should pool connections across classes with the same configuration" do
    pending
  end
  
  it "should manage the namespace rather than delegating to the connection" do
    MemCache.should_receive(:new) do |servers, options|
      servers.should == ['127.0.0.1:11211']
      options[:namespace].should == :namespace_versions
      ns_cache = mock(MemCache, :get => nil)
      ns_cache.should_receive(:get).with(FakeCacheClass.name).and_return(nil)
      ns_cache.should_receive(:set).with(FakeCacheClass.name, 1)
      ns_cache
    end

    MemCache.should_receive(:new) do |servers, options|
      servers.should == ['127.0.0.1:11211']
      options[:namespace].should == nil
      mock(MemCache)
    end

    # MemCache.new(self.servers, self.mc_options.merge(:namespace => namespace))
    Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
  end
  
  def check_memcached(key, expected_value, namespace = nil)
    servers = ['127.0.0.1:11211']
    mc_options = {
      :c_threshold => 10_000,
      :compression => true,
      :debug       => true,
      :readonly    => false,
      :urlencode   => false,
      :namespace   => namespace
    }
    mc = MemCache.new(servers, mc_options)
    mc.get(key.hexdigest).should == expected_value
  end
  
  it "should set the namespace version" do
    adapter = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    adapter.set('test-key', 'test-value', 10)
    
    check_memcached(FakeCacheClass.name, '1', :namespace_versions)
  end
  
  it "should set a value in memcached" do
    adapter = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    adapter.set('test-key', 'test-value', 10)
    
    check_memcached('test-key', 'test-value', "#{FakeCacheClass.name}.1")
  end
end
