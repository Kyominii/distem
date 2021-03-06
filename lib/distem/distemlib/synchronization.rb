module Distem
  module Lib
    module Synchronization
      require 'thread'

      class Semaphore
        def initialize(max)
          @lock = Mutex.new
          @cond = ConditionVariable.new
          @used = 0
          @max = max
        end

        def acquire(n = 1)
          @lock.synchronize {
            while (n > (@max - @used)) do
              @cond.wait(@lock)
            end
            @used += n
          }
        end

        def relaxed_acquire(n = 1)
          taken = 0
          @lock.synchronize {
            while (@max == @used) do
              @cond.wait(@lock)
            end
            taken = (n + @used) > @max ? @max - @used : n
            @used += taken
          }
          return n - taken
        end

        def release(n = 1)
          @lock.synchronize {
            @used -= n
            @cond.signal
          }
        end
      end

      class SlidingWindow
        def initialize(size)
          @queue = []
          @lock = Mutex.new
          @finished = false
          @size = size
          @tids = []
          @res = {}
        end

        def add(task, tag = nil)
          @queue << [task, tag]
        end

        def run
          @lock.synchronize {
            @queue = @queue.reverse
          }
          (1..@size).each {
            @tids << Thread.new {
              while !@finished do
                task = nil
                tag = nil
                @lock.synchronize {
                  if @queue.size > 0
                    task, tag = @queue.pop
                  else
                    @finished = true
                  end
                }
                if task
                  if task.is_a?(Proc)
                    task.call
                  else
                    res = Shell.run_without_logging(task)
                    @res[tag] = res if tag
                  end
                end
              end
            }
          }
          @tids.each { |tid| tid.join }
        end

        def results
          @res
        end

        def kill
          @tids.each { |tid| tid.kill }
        end
      end
    end
  end
end
