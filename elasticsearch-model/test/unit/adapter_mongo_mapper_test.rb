require 'test_helper'

class Elasticsearch::Model::AdapterMongoMapperTest < Test::Unit::TestCase
  context "Adapter MongoMapper module: " do
    class ::DummyClassForMongoMapper
      RESPONSE = Struct.new('DummyMongoMapperResponse') do
        def response
          { 'hits' => {'hits' => [ {'_id' => 2}, {'_id' => 1} ]} }
        end
      end.new

      def response
        RESPONSE
      end

      def ids
        [2, 1]
      end
    end

    setup do
      @records = [ stub(id: 1, inspect: '<Model-1>'), stub(id: 2, inspect: '<Model-2>') ]
      ::Symbol.any_instance.stubs(:in).returns(@records)
    end

    should "have the register condition" do
      assert_not_nil Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::MongoMapper]
      assert_equal false, Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::MongoMapper].call(DummyClassForMongoMapper)
    end

    context "Records" do
      setup do
        DummyClassForMongoMapper.__send__ :include, Elasticsearch::Model::Adapter::MongoMapper::Records
      end

      should "have the implementation" do
        assert_instance_of Module, Elasticsearch::Model::Adapter::MongoMapper::Records

        instance = DummyClassForMongoMapper.new
        instance.expects(:klass).returns(mock('class', where: @records))

        assert_equal @records, instance.records
      end

      should "reorder the records based on hits order" do
        @records.instance_variable_set(:@records, @records)

        instance = DummyClassForMongoMapper.new
        instance.expects(:klass).returns(mock('class', where: @records))

        assert_equal [1, 2], @records.        to_a.map(&:id)
        assert_equal [2, 1], instance.records.to_a.map(&:id)
      end

      should "not reorder records when SQL order is present" do
        @records.instance_variable_set(:@records, @records)

        instance = DummyClassForMongoMapper.new
        instance.expects(:klass).returns(stub('class', where: @records)).at_least_once
        instance.records.expects(:asc).returns(@records)

        assert_equal [2, 1], instance.records.to_a.map(&:id)
        assert_equal [1, 2], instance.asc.to_a.map(&:id)
      end
    end

    context "Callbacks" do
      should "register hooks for automatically updating the index" do
        DummyClassForMongoMapper.expects(:after_create)
        DummyClassForMongoMapper.expects(:after_update)
        DummyClassForMongoMapper.expects(:after_destroy)

        Elasticsearch::Model::Adapter::MongoMapper::Callbacks.included(DummyClassForMongoMapper)
      end
    end

    context "Importing" do
      should "implement the __find_in_batches method" do
        DummyClassForMongoMapper.expects(:all).returns([])

        DummyClassForMongoMapper.__send__ :extend, Elasticsearch::Model::Adapter::MongoMapper::Importing
        DummyClassForMongoMapper.__find_in_batches do; end
      end
    end

  end
end
