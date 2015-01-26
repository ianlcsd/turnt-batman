require "java_runner/version"


require 'rjb'
require 'thread'

module JavaRunner

  ## shaded jar
  JARS1  = Dir.glob("/Users/Ian1/workspace/hive/hive-unittest-poc/target/hive-agent-poc*.jar")
  ## due to classloading issue, datanucleus* jar can not be shaded!!
  JARS2  = Dir.glob("/Users/Ian1/workspace/hive/hive-unittest-poc/target/jars/*.jar")

  JARS3 = JARS1.concat(JARS2).join(':')


  Rjb::load(JARS3)
  @@runnerClass = Rjb::import('com.clearstorydata.hive.HiveServer2Runner')
  @@runner = @@runnerClass.new(10003)


  @@runner.start()
  @@runner.execute( "CREATE DATABASE IF NOT EXISTS csd_agent_tests")
  @@runner.execute( "CREATE TABLE csd_agent_tests.csd_agent_acceptance_test_table (id int, name string, notes string) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' " )
  @@runner.execute( "LOAD DATA LOCAL INPATH '/tmp/csd_agent_acceptance_test_table.csv' OVERWRITE INTO TABLE csd_agent_tests.csd_agent_acceptance_test_table" )
  @@mutex = Mutex.new
  @@condition = ConditionVariable.new

  hive_thread = Thread.new {
    @@mutex.synchronize {
      @@condition.wait(@@mutex)
    }
  }.join

=begin
   def stop()
     mutex.synchronize {
       @@condition.signal
     }
   end
=end
end





