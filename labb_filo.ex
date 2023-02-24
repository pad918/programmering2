defmodule Chopstick do
  def start() do
    stick = spawn_link(fn -> available() end) # Start at available!!!
  end

  def available() do
    #IO.puts("Available")
    IO.puts("Stick unlocked #{inspect(self())}")
    receive do
      {:request, from} ->
        send(from, {:granted, self()})
        gone()
      :quit -> :ok
    end
  end

  def gone() do
    IO.puts("Stick locked #{inspect(self())}")
    receive do
      :return -> available() #?
      {:accept, _} ->
        IO.puts("Error, delayed accept")
        gone()
      :quit -> :ok
    end
  end

  # Stick is the PID
  def request(stick) do
    send(stick, {:request, self()}) # Stick eller self
    receive do
      {:granted, _} ->
        :ok
    end
  end

  def request_timeout(stick, timeout_ms) do
    send(stick, {:request, self()}) # Stick eller self
    receive do
      {:granted, _} ->
        :ok
      after timeout_ms ->
        :no
    end
  end

  def request_async(stick, parent) do
    send(stick, {:request, parent})
  end

  # def request_async(parent, stick, timeout_ms) do
  #   send(stick, {:request, self()}) # Stick eller self
  #   receive do
  #     :granted ->
  #       # This stick was granted
  #       send(parent, {:ok, stick})
  #       :ok
  #     after timeout_ms ->
  #       send(parent, :no)
  #       :no
  #   end
  # end

  # def request_timeout(stick, timeout_ms) do
  #   send(stick, {:request, self()}) # Stick eller self
  #   case request_responce(self, stick, timeout_ms) do
  #     :ok -> :ok
  #     :no -> :no
  #   end
  # end

  # def request_async(parent, stick, timeout_ms) do
  #   send(stick, {:request, self()}) # Stick eller self
  #   request_responce(parent, stick, timeout_ms)
  # end

  # def request_responce(parent, stick, timeout_ms) do
  #   receive do
  #     :granted ->
  #       #IO.puts("Granted")
  #       send(stick, {:accept, self()})
  #       request_responce(parent, stick, timeout_ms)

  #     :accepted ->
  #       #IO.puts("Accepted")
  #       send(parent, {:ok, stick})
  #       :ok
  #     after timeout_ms ->
  #       send(parent, :no)
  #       :no
  #   end
  # end

  def quit(stick) do
    send(stick, :quit)
    #flush()
  end

  # Antagligen helt fel. Förstår inte vad fan han vill ha
  def return_stick(stick) do
    send(stick, :return)
  end

end

defmodule PhilosopherTimeout do

  def start(hunger, right, left, name, ctrl, seed) do
    IO.puts("#{name} joined the server")
    spawn_link(fn -> process_start(hunger, right, left, name, ctrl, seed) end)
  end

  def process_start(hunger, right, left, name, ctrl, seed) do
    :rand.seed(:exsplus, {seed, seed+1, seed+2})
    dreaming(hunger, right, left, name, ctrl, 20, 1000) # ttd = 2
  end


  def dreaming(_, _, _, name, ctrl, 0, _) do
    IO.puts("#{name} starved to death... big sad")
    send(ctrl, :abort) # On starv, end dinner
  end

  def dreaming(0, _, _, name, ctrl, _, _) do
    IO.puts("--------------- #{name} yeeted out ---------------")
    send(ctrl, :done)
  end

  def dreaming(hunger, right, left, name, ctrl, ttd, dream_delay) do
    IO.puts("#{name} is dreaming, has to eats #{hunger} more times")
    sleep(dream_delay)
    request_sticks_timeout(hunger, right, left, name, ctrl, ttd, dream_delay)
    #request_sticks_async(hunger, right, left, name, ctrl, ttd, dream_delay)
    receive do
      :quit -> :ok
      #{:granted, stick} ->
      #  return_stick(stick)
    end

  end

  def request_sticks_timeout(hunger, right, left, name, ctrl, ttd, dream_delay) do
    IO.puts("#{name} is reqesting chopsticks")
    # Try to get chopsticks...

    case Chopstick.request_timeout(right, 1000) do
      :ok ->
        #IO.puts("GOT FIRST!")
        case Chopstick.request_timeout(left, 1000) do
          :ok ->
            # sleep(10000) # Makes it even worse
            #IO.puts("GOT SECOND!")
            eating(hunger, right, left, name, ctrl, ttd, dream_delay)
          :no ->
            # Return right stick and go back to dreaming
            return_stick(right)
            IO.puts("#{name} could not eat TTD-2")
            dreaming(hunger, right, left, name, ctrl, ttd-1, dream_delay+300)
        end
      :no ->
        IO.puts("#{name} could not eat TTD-1")
        dreaming(hunger, right, left, name, ctrl, ttd-1, dream_delay+300)
    end

    receive do
      :quit -> :ok
      #{:granted, stick} ->
      #  return_stick(stick)
    end

  end

  def request_sticks_async(hunger, right, left, name, ctrl, ttd, dream_delay) do
    IO.puts("#{name} is reqesting chopsticks, async")
    Chopstick.request_async(left, self()) # <-- ta bort delay
    Chopstick.request_async(right, self())
    case granted([], 2, 500) do
      :granted ->
        eating(hunger, right, left, name, ctrl, ttd, dream_delay)
      :failed ->
        IO.puts("#{name} did NOT eat")
        # go back to dreaming?
        unlock(ctrl)
        dreaming(hunger, right, left, name, ctrl, ttd-1, dream_delay+300)
    end
    receive do
      #{:granted, stick} ->
      #  return_stick(stick)
    end
  end

  def granted(_, 0, timeout) do
    :granted
  end

  def granted(granted_sticks, resp, timeout) do
    receive do
      {:granted, stick} ->
        granted([stick|granted_sticks], resp-1, timeout)
      after timeout ->
        #Return sticks
        Enum.each(granted_sticks, fn(stick) -> return_stick(stick) end)
        :failed
    end
  end

  # def granted(granted_sticks, resp) when resp<=0 do
  #   # Return sticks
  #   Enum.each(granted_sticks, fn(stick) ->
  #     return_stick(stick)
  #   end)
  #   :failed
  # end

  # def granted(granted_sticks, resp) do
  #   # Wait for 2 responces?
  #   receive do
  #     {:ok, stick} ->
  #       #IO.puts("GOT STICK")
  #       #IO.inspect(stick)
  #       granted_sticks = [stick|granted_sticks]
  #       [_|rest] = granted_sticks
  #       if(rest != []) do
  #         :granted
  #       else
  #         granted(granted_sticks, resp-1)
  #       end
  #     :no ->
  #       #IO.puts("DID NOT GET STICK")
  #       granted(granted_sticks, resp-1)
  #     after
  #   end
  # end

  def unlock(waiter) do
    send(waiter, {:unlock, self()})
  end

  def lock(waiter) do
    send(waiter, {:lock, self()})
  end

  def return_stick(stick) do
    #IO.puts("Stick ... was returned")
    #IO.inspect(stick)
    Chopstick.return_stick(stick)
  end

  def return_sticks(name, right, left, ctrl) do
    IO.puts("#{name} returned her sticks")
    return_stick(right)
    return_stick(left)
    # Only if waiter is used!!!
    send(ctrl, {:unlock, self()})
  end

  def eating(hunger, right, left, name, ctrl, ttd, dream_delay) do
    IO.puts("#{name} is eating")
    # Use chopsticks for some time
    sleep(3000)
    # Go back to dreaming
    # Ändra algoritm här!!!
    return_sticks(name, right, left, ctrl)
    dreaming(hunger-1, right, left, name, ctrl, ttd, dream_delay)
    receive do
      :quit -> :ok
      #{:granted, stick} ->
      #  return_stick(stick)
    end
  end

  def quit(p) do
    send(p, :quit)
  end

  # Random sleeep
  def sleep(0) do :ok end
  def sleep(t) do
    :timer.sleep(:rand.uniform(t))
  end
end

defmodule WaitedPhilosopher do

  def start(hunger, right, left, name, ctrl, seed, ttd) do
    IO.puts("#{name} joined the server")
    spawn_link(fn -> process_start(hunger, right, left, name, ctrl, seed, ttd) end)
  end

  def process_start(hunger, right, left, name, ctrl, seed, ttd) do
    :rand.seed(:exsplus, {seed, seed+1, seed+2})
    dreaming(hunger, right, left, name, ctrl,ttd)
  end

  def dreaming(0, _, _, name, ctrl, _) do
    IO.puts("--------------- #{name} yeeted out ---------------")
    send(ctrl, :done)
  end

  def dreaming(hunger, right, left, name, ctrl, ttd) do
    IO.puts("#{name} is dreaming, has to eats #{hunger} more times")
    sleep(100)
    request_sticks_async_waiter(hunger, right, left, name, ctrl, ttd)
    receive do
      :quit -> :ok
      {:granted, stick} ->
        return_stick(stick)
    end
  end

  # def request_sticks_async(hunger, right, left, name, ctrl) do
  #   IO.puts("#{name} is reqesting chopsticks, async")

  #   Chopstick.request_async(self(),  left, 100)
  #   Chopstick.request_async(self(), right, 100)
  #   case granted([], 2) do
  #     :granted ->
  #       eating(hunger, right, left, name, ctrl)
  #     :failed ->
  #       IO.puts("!!!!!!!!!!!!!!!!!!!!!! #{name} did NOT eat")
  #       # go back to dreaming?
  #       unlock(ctrl)
  #       dreaming(hunger, right, left, name, ctrl)
  #   end
  # end

  def request_sticks_async(hunger, right, left, name, ctrl, ttd) do
    IO.puts("#{name} is reqesting chopsticks, async")
    Chopstick.request_async(left, self()) # <-- ta bort delay
    Chopstick.request_async(right, self())
    case granted([], 2, 500) do
      :granted ->
        eating(hunger, right, left, name, ctrl, ttd)
      :failed ->
        IO.puts("#{name} did NOT eat")
        # go back to dreaming?
        unlock(ctrl)
        dreaming(hunger, right, left, name, ctrl, ttd-1)
    end
    receive do
      {:granted, stick} ->
        return_stick(stick)
    end
  end

  def granted(_, 0, timeout) do
    :granted
  end

  def granted(granted_sticks, resp, timeout) do
    receive do
      {:granted, stick} ->
        granted([stick|granted_sticks], resp-1, timeout)
      after timeout ->
        #Return sticks
        Enum.each(granted_sticks, fn(stick) -> return_stick(stick) end)
        :failed
    end
  end

  def unlock(waiter) do
    send(waiter, {:unlock, self()})
  end

  def lock(waiter) do
    send(waiter, {:lock, self()})
  end

  def request_sticks_async_waiter(hunger, right, left, name, ctrl, ttd) do
    IO.puts("#{name} is asking waiter if she can eat")

    lock(ctrl)
    case allowed_to_eat() do
      :granted ->
        # Use the basic request
        request_sticks_async(hunger, right, left, name, ctrl, ttd)
      :refused ->
        IO.puts("#{name} was refused from eating")
        # Go back to dreaming
        dreaming(hunger, right, left, name, ctrl, ttd)
    end

    receive do
      :quit -> :ok
      {:granted, stick} ->
        return_stick(stick)
    end
  end

  def allowed_to_eat() do
    receive do
      :granted ->
        :granted
      :refused ->
        :refused
      other ->
        IO.puts("ERROR!!! other was recived")
        IO.inspect(other)
        allowed_to_eat()
    end
  end

  # def granted(granted_sticks, resp) when resp<=0 do
  #   # Return sticks
  #   Enum.each(granted_sticks, fn(stick) ->
  #     return_stick(stick)
  #   end)
  #   :failed
  # end

  # def granted(granted_sticks, resp) do
  #   # Wait for 2 responces?
  #   receive do
  #     {:ok, stick} ->
  #       #IO.puts("Recieved ok from stick: ")
  #       #IO.inspect(stick)
  #       granted_sticks = [stick|granted_sticks]
  #       [_|rest] = granted_sticks
  #       if(rest != []) do
  #         #IO.puts("IN GRANTED------------")
  #         #IO.inspect(granted_sticks)
  #         :granted
  #       else
  #         granted(granted_sticks, resp-1)
  #       end
  #     :no ->
  #       #IO.puts("Recived a NOT signal from one stick!")
  #       granted(granted_sticks, resp-1)

  #   end

  # end

  def return_stick(stick) do
    Chopstick.return_stick(stick)
  end

  def return_sticks(name, right, left, ctrl, ttd) do
    IO.puts("#{name} returned her sticks, sending unlock signal")
    return_stick(right)
    return_stick(left)
    # Only if waiter is used!!!
    unlock(ctrl)
  end

  def eating(hunger, right, left, name, ctrl, ttd) do
    IO.puts("#{name} is eating")
    # Use chopsticks for some time
    sleep(3000)
    # Go back to dreaming

    # Ändra algoritm här!!!
    return_sticks(name, right, left, ctrl, ttd)


    dreaming(hunger-1, right, left, name, ctrl, ttd)
    receive do
      :quit -> :ok
      {:granted, stick} ->
        return_stick(stick)
    end
  end

  # Random sleeep
  def sleep(0) do :ok end
  def sleep(t) do
    :timer.sleep(:rand.uniform(t))
  end
end

defmodule Dinner do
  def start, do: spawn(fn -> init() end)

  def init() do
    c1 = Chopstick.start()
    c2 = Chopstick.start()
    c3 = Chopstick.start()
    c4 = Chopstick.start()
    c5 = Chopstick.start()
    ctrl = self()
    p1 = PhilosopherTimeout.start(5, c1, c2, "Arendt",    ctrl, 100)
    p2 = PhilosopherTimeout.start(5, c2, c3, "Hypatia",   ctrl, 101)
    p3 = PhilosopherTimeout.start(5, c3, c4, "Simone",    ctrl, 102)
    p4 = PhilosopherTimeout.start(5, c4, c5, "Elisabeth", ctrl, 103)
    p5 = PhilosopherTimeout.start(5, c5, c1, "Ayn",       ctrl, 104)
    wait(5, [c1, c2, c3, c4, c5], [p1, p2, p3, p4, p5])
    IO.puts(" WAINTG IS DONE!!! !!! !!! !!! !!! !!!")
  end

  def wait(0, chopsticks, _) do
    #Enum.each(chopsticks, fn(c) -> Chopstick.quit(c) end)
    kill_all(chopsticks)
  end

  def wait(n, chopsticks, philosophers) do
    receive do
      :done ->
        wait(n-1, chopsticks, philosophers)
      :abort ->
        # Kill all other philosophers first
        kill_all(philosophers)
        IO.puts("Deadlock occured, terminating processes...")
        Process.exit(self(), :kill)
    end

  end

  def kill_all(processes) do
    IO.puts("Killing all processes")
    Enum.each(processes, fn(p) -> PhilosopherTimeout.quit(p) end)
  end

end

defmodule DinnerWaiter do
  def start, do: spawn(fn -> init() end)

  def init() do

    c1 = Chopstick.start()
    c2 = Chopstick.start()
    c3 = Chopstick.start()
    c4 = Chopstick.start()
    c5 = Chopstick.start()
    waiter = Waiter.init(2, self())
    ctrl = waiter #self()

    p1 = WaitedPhilosopher.start(5, c1, c2, "Arendt",    ctrl, 100, 20)
    p2 = WaitedPhilosopher.start(5, c2, c3, "Hypatia",   ctrl, 101, 20)
    p3 = WaitedPhilosopher.start(5, c3, c4, "Simone",    ctrl, 102, 20)
    p4 = WaitedPhilosopher.start(5, c4, c5, "Elisabeth", ctrl, 103, 20)
    p5 = WaitedPhilosopher.start(5, c5, c1, "Ayn",       ctrl, 104, 20)
    # Add to waiter
    add_philosophers(waiter, [p1, p2, p3, p4, p5])
    wait(5, [c1, c2, c3, c4, c5])
    IO.puts(" WAINTG IS DONE!!! !!! !!! !!! !!! !!!")
  end

  def add_philosophers(waiter, pilo) do
    Enum.each(pilo, fn(p) -> send(waiter, {:add, p}) end)
  end

  def wait(0, chopsticks) do
    Enum.each(chopsticks, fn(c) -> Chopstick.quit(c) end)
  end

  def wait(n, chopsticks) do
    receive do
      :done ->
        IO.puts("Recived :done signal!!!")
        wait(n-1, chopsticks)
      :abort ->
        Process.exit(self(), :kill)
    end

  end

end


defmodule Waiter do
  #{max, eating[], all[]}
  def init(max_eaters, ctrl) do
    spawn_link(fn -> run(max_eaters, [], [], ctrl) end)
  end

  def run(max, eating, all, ctrl) do
    # p is the PID of the philosopher
    receive do
      {:add,  p} ->
        IO.puts("Added one")
        run(max, eating, [p|all], ctrl)
      {:lock, p} ->
        # om inte brevid varandra
        len = list_len(eating)
        tot_len = list_len(all)
        if(len < max  && tot_len==5 && !next_to_any(p, eating, all)) do
          IO.puts("lock granted")
          send(p, :granted)
          run(max, [p|eating], all, ctrl)
        else
          IO.puts("lock redjected")
          send(p, :refused)
          run(max, eating, all, ctrl)
        end
      {:unlock, p} ->
        IO.puts("lock unlocked")
        run(max, remove_from_list(eating, p), all, ctrl)
      other ->
        IO.puts("_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_Other was sent_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_")
        send(ctrl, other)
        run(max, eating, all, ctrl)
    end
  end

  def get_last([]) do :error end
  def get_last([h]) do h end
  def get_last([h|t]) do
    get_last(t)
  end

  def get_prev(p, [p|t]) do
    get_last(t)
  end

  def get_prev(p, list) do
    {found, prev} = Enum.reduce(list, {false, nil}, fn(x, {on, acc}) ->
      on = on || (x==p)
      if(on) do
        {true, acc}
      else
        {on, x}
      end
    end)
    prev

  end

  def contains(p, list) do
    Enum.any?(list, fn(x) -> x==p end)
  end

  def get_next(p, list) do
    {_, next} = Enum.reduce(list, {true, nil}, fn(x, {on, acc}) ->
      n_on = (p==x)
      if(on) do
        {n_on, x}
      else
        {n_on, acc}
      end
    end)
    next
  end

  def next_to_any(p, on, all) do
    #IO.inspect(all)
    #IO.inspect(on)
    prev = get_prev(p, all)
    next = get_next(p, all)
    #IO.puts("P, prev, next = ")
    #IO.inspect(p)
    #IO.inspect(prev)
    #IO.inspect(next)
    if(contains(prev, on) || contains(next, on)) do
      true
    else
      false
    end
  end

  def list_len(list) do
    Enum.reduce(list, 0, fn(x, acc) -> 1+acc end)
  end

  def remove_from_list(list, key) do
    Enum.reduce(list, [], fn(x, l) ->
      if(x==key) do
        l
      else
        [x|l]
      end
    end)
  end

end
