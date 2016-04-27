require 'cucumber/core'
require 'cucumber/core/filter'
require 'thread'


# This seems to work fine for simple scenarios on MRI Ruby.
# It also is madness for more complex scenarios on JRuby.
module Cucumber
  module Core
    module Test
      class ThreadFilter < Cucumber::Core::Filter.new
        def initialize(receiver=nil)
          @receiver = receiver
          @test_cases = Queue.new
        end

        def test_case(test_case)
          @test_cases.push test_case
          self
        end

        def done
          (0...cpu_count.to_i).map do
            Thread.new do
              begin
                while test_case = @test_cases.pop(true)
                  test_case.describe_to(receiver)
                end
              rescue ThreadError
              end
            end
          end.each(&:join)
          receiver.done
          self
        end

        private
        def cpu_count
          return Java::Java.lang.Runtime.getRuntime.availableProcessors if defined? Java::Java
          return File.read('/proc/cpuinfo').scan(/^processor\s*:/).size if File.exist? '/proc/cpuinfo'
          require 'win32ole'
          WIN32OLE.connect("winmgmts://").ExecQuery("select * from Win32_ComputerSystem").NumberOfProcessors
        rescue LoadError
          Integer `sysctl -n hw.ncpu 2>/dev/null` rescue 1
        end
      end
    end
  end
end
