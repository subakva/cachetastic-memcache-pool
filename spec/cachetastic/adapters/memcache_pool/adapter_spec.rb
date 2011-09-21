require 'spec_helper'

describe Cachetastic::Adapters::MemcachePool::Adapter do
  before(:each) do
    configatron.temp_start
    configatron.cachetastic.defaults.adapter = Cachetastic::Adapters::MemcachePool::Adapter
    clear_test_cache_keys
  end

  before(:each) do
    pending 'JDW: This is an integration test. It requires a memcached server to be running on localhost:11211'
  end

  after(:each) do
    Cachetastic::Adapters::MemcachePool::Adapter.reset_connections
    configatron.temp_end
  end

  class FakeCacheClass; end
  class AnotherFakeCacheClass; end

  def clear_test_cache_keys
    # Clear namespace values
    cache_classes = [FakeCacheClass, AnotherFakeCacheClass]
    ns_connection = memcached_connection(:namespace_versions)
    cache_classes.each do |cache_classs|
      ns_connection.delete(cache_classs.name)
    end

    # Clear data values
    data_connection = memcached_connection(nil)
    cache_classes.each do |cache_class|
      %w{key1 key2}.each do |key|
        (1..2).each do |version|
          data_connection.delete("#{cache_class.name}.${version}:#{key.to_s.hexdigest}")
        end
     end
    end
  end 
 
  def expect_connection_creation(namespace)
    mock_cache = mock(MemCache, :get => nil, :active? => true)
    MemCache.should_receive(:new) do |servers, options|
      servers.should == ['127.0.0.1:11211']
      options[:namespace].should == namespace
      mock_cache
    end
    mock_cache
  end

  def memcached_connection(namespace)
    servers = ['127.0.0.1:11211']
    mc_options = {
      :c_threshold => 10_000,
      :compression => true,
      :debug       => true,
      :readonly    => false,
      :urlencode   => false,
      :namespace   => namespace
    }
    MemCache.new(servers, mc_options)
  end

  def check_memcached(key, expected_value, namespace = nil)
    mc = memcached_connection(namespace)
    mc.get(key.hexdigest).should == expected_value
  end

  it "should set a value in memcached" do
    adapter = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    adapter.set('test-key', 'test-value', 10)
    
    check_memcached('test-key', 'test-value', "#{FakeCacheClass.name}.1")
  end

  it "should get a value in memcached" do
    memcached_connection(nil).set("#{FakeCacheClass.name}.1:#{'key1'.hexdigest}", 'value1', 86400, false)

    adapter = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    adapter.get('key1').should == 'value1'
  end

  it "should delete a value in memcached" do
    key = "#{FakeCacheClass.name}.1:#{'key1'.hexdigest}"
    conn = memcached_connection(nil)
    conn.set(key, 'value1', 86400, false)

    adapter = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    adapter.delete('key1')
    conn.get('key').should be_nil
  end

  it "should not see the old value in memcached after expire_all is called" do
    memcached_connection(nil).set("#{FakeCacheClass.name}.1:#{'key1'.hexdigest}", 'value1', 86400, false)

    adapter = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    adapter.get('key1').should == 'value1'
    adapter.expire_all
    adapter.get('key1').should be_nil
  end

  it "should create a namespace connection and a data connection" do
    data_connection = expect_connection_creation(nil)
    ns_connection = expect_connection_creation(:namespace_versions)

    ns_connection.should_receive(:set).with(FakeCacheClass.name, 1)
    data_connection.should_receive(:set).with("#{FakeCacheClass.name}.1:#{'key1'.hexdigest}", "value1", 86400, false)

    cache = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    cache.set('key1', 'value1')
  end

  it "should create only one namespace and data connection for caches with the same configuration" do
    data_connection = expect_connection_creation(nil)
    ns_connection = expect_connection_creation(:namespace_versions)

    ns_connection.should_receive(:set).with(FakeCacheClass.name, 1)
    data_connection.should_receive(:set).with("#{FakeCacheClass.name}.1:#{'key1'.hexdigest}", "value1", 86400, false)
    cache1 = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    cache1.set('key1', 'value1')

    ns_connection.should_receive(:set).with(AnotherFakeCacheClass.name, 1)
    data_connection.should_receive(:set).with("#{AnotherFakeCacheClass.name}.1:#{'key2'.hexdigest}", "value2", 86400, false)
    cache2 = Cachetastic::Adapters::MemcachePool::Adapter.new(AnotherFakeCacheClass)
    cache2.set('key2', 'value2')
  end

  it "should create a new namespace connection if the configuration is different" do
    configatron.cachetastic.fake_cache_class.mc_options = {:c_threshold => 20_000}

    data_connection1 = expect_connection_creation(nil)
    data_connection1.should_receive(:set).with("#{FakeCacheClass.name}.1:#{'key1'.hexdigest}", "value1", 86400, false)
    ns_connection1 = expect_connection_creation(:namespace_versions)
    ns_connection1.should_receive(:set).with(FakeCacheClass.name, 1)

    cache1 = Cachetastic::Adapters::MemcachePool::Adapter.new(FakeCacheClass)
    cache1.set('key1', 'value1')


    data_connection2 = expect_connection_creation(nil)
    data_connection2.should_receive(:set).with("#{AnotherFakeCacheClass.name}.1:#{'key2'.hexdigest}", "value2", 86400, false)
    ns_connection2 = expect_connection_creation(:namespace_versions)
    ns_connection2.should_receive(:set).with(AnotherFakeCacheClass.name, 1)
    cache2 = Cachetastic::Adapters::MemcachePool::Adapter.new(AnotherFakeCacheClass)
    cache2.set('key2', 'value2')
  end
end
