require "java_runner/version"


require 'rjb'
require 'thread'
require 'yaml'

module HiveRunner
  class Runner
    def Runner.initialize
      @@JARS3 = Dir.glob("/Users/Ian1/workspace/hive/hive-unittest-poc/target/hive-agent-poc*.jar")
                    .concat(Dir.glob("/Users/Ian1/workspace/hive/hive-unittest-poc/target/jars/*.jar"))
                    .join(':')

      Rjb::load(@@JARS3)

      @@Hconf = Rjb::import('org.apache.hadoop.hive.conf.HiveConf').new
      @@hive_properties = YAML.load_file('/Users/Ian1/workspace/ruby/java_runner/lib/java_runner/hive.yaml')['hiveserver2']['properties']
      @@hive_properties.each do |key, value|
        @@Hconf.set(key, value.to_s)
      end

      @@Hs2 = Rjb::import('org.apache.hive.service.server.HiveServer2').new
      @@Hs2.init (@@Hconf)
      @@Hs2.start


      Rjb::import('org.apache.hive.jdbc.HiveDriver')
      @@connectionUrl = 'jdbc:hive2://localhost:'.concat(@@hive_properties['hive.server2.thrift.port'].to_s).concat('/default')

    end

    def Runner.execute(ddl)
      con = Rjb::import('java.sql.DriverManager').getConnection(@@connectionUrl,@@hive_properties['user'], @@hive_properties['password'])
      stmt = con.createStatement()
      begin
        puts 'executed '.concat(ddl)
        stmt.execute(ddl)

      rescue
        stmt.close()
        con.close()
      end
    end

    def Runner.populate
      execute( "CREATE DATABASE IF NOT EXISTS csd_agent_tests")
      execute( "CREATE TABLE csd_agent_tests.csd_agent_acceptance_test_table (id int, name string, notes string) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' " )
      execute( "LOAD DATA LOCAL INPATH '/tmp/csd_agent_acceptance_test_table.csv' OVERWRITE INTO TABLE csd_agent_tests.csd_agent_acceptance_test_table" )

      @@mutex = Mutex.new
      @@condition = ConditionVariable.new

      hive_thread = Thread.new {
        @@mutex.synchronize {
          @@condition.wait(@@mutex)
        }
      }.join
    end
  end
end

HiveRunner::Runner.initialize
HiveRunner::Runner.populate





