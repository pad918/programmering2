defmodule Chopstick do
  def start() do
    stick = spawn_link(fn -> available() end) # Start at available!!!
  end

  def available() do
    #IO.puts("Available")
    receive do
      {:request, from} ->
        send(from, :granted)
        gone()
      :quit -> :ok
    end

  end

  def gone() do
    #IO.puts("Gone")
    receive do
      :return -> available() #?
      :quit -> :ok
    end
  end

  # Stick is the PID
  def request(stick) do
    send(stick, {:request, self()}) # Stick eller self
    receive do
      :granted ->
        #IO.puts("Granted")
        :ok
    end
  end

  def request_timeout(stick, timeout_ms) do
    send(stick, {:request, self()}) # Stick eller self
    receive do
      :granted ->
        :ok
      after timeout_ms ->
        :no
    end
  end

  def request_async(parent, stick, timeout_ms) do
    send(stick, {:request, self()}) # Stick eller self
    receive do
      :granted ->
        # This stick was granted
        send(parent, {:ok, stick})
        :ok
      after timeout_ms ->
        send(parent, :no)
        :no
    end
  end

  def quit(stick) do
    send(stick, :quit)
    #flush()
  end

  # Antagligen helt fel. Förstår inte vad fan han vill ha
  def return_stick(stick) do
    send(stick, :return)
  end

end


defmodule Philosopher do

  def start(hunger, right, left, name, ctrl, seed) do
    IO.puts("#{name} joined the server")
    spawn_link(fn -> process_start(hunger, right, left, name, ctrl, seed) end)
  end

  def process_start(hunger, right, left, name, ctrl, seed) do
    :rand.seed(:exsplus, {seed, seed+1, seed+2})
    dreaming(hunger, right, left, name, ctrl)
  end

  def dreaming(0, _, _, name, ctrl) do
    IO.puts("--------------- #{name} yeeted out ---------------")
    send(ctrl, :done)
  end

  def dreaming(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is dreaming, has to eats #{hunger} more times")
    sleep(1000)
    #request_sticks(hunger, right, left, name, ctrl)
    #request_sticks_async(hunger, right, left, name, ctrl)
    request_sticks_async_waiter(hunger, right, left, name, ctrl)
    receive do
      :quit -> :ok
    end

  end

  def request_sticks(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is reqesting chopsticks")
    # Try to get chopsticks...

    case Chopstick.request_timeout(right, :rand.uniform(500)) do
      :ok ->
        #IO.puts("GOT FIRST!")
        case Chopstick.request_timeout(left, :rand.uniform(500)) do
          :ok ->
            # sleep(10000) # Makes it even worse
            #IO.puts("GOT SECOND!")
            eating(hunger, right, left, name, ctrl)
          :no ->
            # Return right stick and go back to dreaming
            return_stick(right)
            dreaming(hunger, right, left, name, ctrl)
        end
      :no ->
        dreaming(hunger, right, left, name, ctrl)
    end

    receive do
      :quit -> :ok
    end

  end

  def request_sticks_async(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is reqesting chopsticks, async")

    Chopstick.request_async(self(),  left, 500)
    Chopstick.request_async(self(), right, 500)
    case granted() do
      :granted ->
        eating(hunger, right, left, name, ctrl)
      :failed ->
        IO.puts("!!!!!!!!!!!!!!!!!!!!!! #{name} did NOT eat")
        # go back to dreaming?
        dreaming(hunger, right, left, name, ctrl)
    end
  end

  def request_sticks_async_waiter(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is reqesting chopsticks, async")

    send(ctrl, {:lock, self()})
    case allowed_to_eat(ctrl) do
      :granted ->
        # Use the basic request
        request_sticks(hunger, right, left, name, ctrl)
      :refused ->
        # Go back to dreaming
        dreaming(hunger, right, left, name, ctrl)
    end
  end

  def allowed_to_eat(waiter) do

    receive do
      :granted ->
        :granted
      :refused ->
        :refused
      other ->
        IO.puts("ERROR!!! other was recived")
        IO.inspect(other)
        allowed_to_eat(waiter)
    end
  end

  def granted() do
    granted_sticks = []
    receive do
      {:ok, stick} ->
        granted_sticks = [stick|granted_sticks]
        [_|rest] = granted_sticks
        if(rest!=[]) do
          :granted
        else
          granted()
        end

      :no ->
        # Return all sticks
        Enum.each(granted_sticks, fn(stick) ->
          return_stick(stick)
        end)
        :failed
    end

  end

  def return_stick(stick) do
    Chopstick.return_stick(stick)
  end

  def return_sticks(name, right, left, ctrl) do
    IO.puts("#{name} returned her sticks")
    return_stick(right)
    return_stick(left)
    # Only if waiter is used!!!
    send(ctrl, {:unlock, self()})
  end

  def eating(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is eating")
    # Use chopsticks for some time
    sleep(3000)
    # Go back to dreaming

    # Ändra algoritm här!!!
    return_sticks(name, right, left, ctrl)


    dreaming(hunger-1, right, left, name, ctrl)
    receive do
      :quit -> :ok
    end



  end

  # Random sleeep
  def sleep(0) do :ok end
  def sleep(t) do
    :timer.sleep(:rand.uniform(t))
  end
end

defmodule WaitedPhilosopher do

  def start(hunger, right, left, name, ctrl, seed) do
    IO.puts("#{name} joined the server")
    spawn_link(fn -> process_start(hunger, right, left, name, ctrl, seed) end)
  end

  def process_start(hunger, right, left, name, ctrl, seed) do
    :rand.seed(:exsplus, {seed, seed+1, seed+2})
    dreaming(hunger, right, left, name, ctrl)
  end

  def dreaming(0, _, _, name, ctrl) do
    IO.puts("--------------- #{name} yeeted out ---------------")
    send(ctrl, :done)
  end

  def dreaming(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is dreaming, has to eats #{hunger} more times")
    sleep(1000)
    request_sticks_async_waiter(hunger, right, left, name, ctrl)
    receive do
      :quit -> :ok
    end

  end

  def request_sticks_async(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is reqesting chopsticks, async")

    Chopstick.request_async(self(),  left, 100)
    Chopstick.request_async(self(), right, 100)
    case granted([], 2) do
      :granted ->
        eating(hunger, right, left, name, ctrl)
      :failed ->
        IO.puts("!!!!!!!!!!!!!!!!!!!!!! #{name} did NOT eat")
        # go back to dreaming?
        unlock(ctrl)
        dreaming(hunger, right, left, name, ctrl)
    end
  end

  def unlock(waiter) do
    send(waiter, {:unlock, self()})
  end

  def lock(waiter) do
    send(waiter, {:lock, self()})
  end

  def request_sticks_async_waiter(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is asking waiter if she can eat")

    lock(ctrl)
    case allowed_to_eat() do
      :granted ->
        # Use the basic request
        request_sticks_async(hunger, right, left, name, ctrl)
      :refused ->
        IO.puts("#{name} was refused from eating")
        # Go back to dreaming
        dreaming(hunger, right, left, name, ctrl)
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

  def granted(granted_sticks, resp) when resp<=0 do
    # Return sticks
    Enum.each(granted_sticks, fn(stick) ->
      return_stick(stick)
    end)
    :failed
  end

  def granted(granted_sticks, resp) do
    # Wait for 2 responces?
    receive do
      {:ok, stick} ->
        #IO.puts("Recieved ok from stick: ")
        #IO.inspect(stick)
        granted_sticks = [stick|granted_sticks]
        [_|rest] = granted_sticks
        if(rest != []) do
          #IO.puts("IN GRANTED------------")
          #IO.inspect(granted_sticks)
          :granted
        else
          granted(granted_sticks, resp-1)
        end
      :no ->
        #IO.puts("Recived a NOT signal from one stick!")
        granted(granted_sticks, resp-1)

    end

  end

  def return_stick(stick) do
    Chopstick.return_stick(stick)
  end

  def return_sticks(name, right, left, ctrl) do
    IO.puts("#{name} returned her sticks, sending unlock signal")
    return_stick(right)
    return_stick(left)
    # Only if waiter is used!!!
    unlock(ctrl)
  end

  def eating(hunger, right, left, name, ctrl) do
    IO.puts("#{name} is eating")
    # Use chopsticks for some time
    sleep(3000)
    # Go back to dreaming

    # Ändra algoritm här!!!
    return_sticks(name, right, left, ctrl)


    dreaming(hunger-1, right, left, name, ctrl)
    receive do
      :quit -> :ok
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
    Philosopher.start(5, c1, c2, "Arendt",    ctrl, 100)
    Philosopher.start(5, c2, c3, "Hypatia",   ctrl, 101)
    Philosopher.start(5, c3, c4, "Simone",    ctrl, 102)
    Philosopher.start(5, c4, c5, "Elisabeth", ctrl, 103)
    Philosopher.start(5, c5, c1, "Ayn",       ctrl, 104)
    wait(5, [c1, c2, c3, c4, c5])
    IO.puts(" WAINTG IS DONE!!! !!! !!! !!! !!! !!!")
  end

  def wait(0, chopsticks) do
    Enum.each(chopsticks, fn(c) -> Chopstick.quit(c) end)
  end

  def wait(n, chopsticks) do
    receive do
      :done ->
        wait(n-1, chopsticks)
      :abort ->
        Process.exit(self(), :kill)
    end

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

    p1 = WaitedPhilosopher.start(5, c1, c2, "Arendt",    ctrl, 100)
    p2 = WaitedPhilosopher.start(5, c2, c3, "Hypatia",   ctrl, 101)
    p3 = WaitedPhilosopher.start(5, c3, c4, "Simone",    ctrl, 102)
    p4 = WaitedPhilosopher.start(5, c4, c5, "Elisabeth", ctrl, 103)
    p5 = WaitedPhilosopher.start(5, c5, c1, "Ayn",       ctrl, 104)
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
        #IO.puts("TOT len = #{tot_len}")
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
