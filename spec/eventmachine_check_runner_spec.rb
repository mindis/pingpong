require 'spec_helper'

describe EventmachineCheckRunner do
  let(:check_url) { 'http://bark.meow' }
  let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }
  let(:config) { PingpongConfig }

  it 'should run the check with eventmachine' do
    now = Time.now
    Time.stub(:now).and_return(now)
    stub_request(:get, check_url).
      to_return(:status => 200, :body => 'ok')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, status, response|
        begin
          WebMock.should have_requested(:get, check_url)
          status.should == 200
          start_time.should == now
          duration.should == 0
          response[:content_length].should == 'ok'.length
        rescue => exception          
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }
    actually_ran.should be_true
    failed_exception.should be_nil
  end

  it 'should use timeout settings from config' do
    stub_request(:get, check_url).
        to_return(:status => 200, :body => 'ok')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do
        begin
          # also check that it's picking up our settings
          config[:check_runner_connect_timeout].should == 15
          http.instance_variable_get(:@conn).instance_variable_get(:@connopts).instance_variable_get(:@connect_timeout).should == 15
          config[:check_runner_inactivity_timeout].should == 60
          http.instance_variable_get(:@conn).instance_variable_get(:@connopts).instance_variable_get(:@inactivity_timeout).should == 60
        rescue => exception          
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }

    actually_ran.should be_true
    failed_exception.should be_nil
  end
end
