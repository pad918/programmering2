defmodule Carlo do


  def dart(radius) do
    x = Enum.random(0..radius)
    y = Enum.random(0..radius)
    :math.pow(x, 2) + :math.pow(y, 2) < :math.pow(radius, 2)
  end

  def round(0, _, a) do a end

  def round(k, r, a) do
    if(dart(r)) do
      round(k-1, r, a+1)
    else
      round(k-1, r, a)
    end
  end

  def rounds(k, j, r) do
    rounds(k, j, 0, r, 0)
  end

  def rounds(0, _, t, _, a) do a/t * 4 end # beräkna medel?

  # Variabel betydelser
  #   k -> antalet rounds att göra
  #   j -> antalet test per round
  #   t -> totalt gjorda test
  #   r -> radius
  #   a -> ackumulator

  def rounds(k, j, t, r, a) do
    a = round(j, r, a)
    t = t+j
    pi = a/t * 4.0 #?
    #:io.format("~w, ~.7f, ~.7f\n", [t, pi, (pi - :math.pi())])
    :io.format("~w, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f\n", [t, Kernel.abs(pi - :math.pi()), 0.05, 0.005, 0.0005, 0.00005 , 0.000005, 0.0000005])
    rounds(k-1, j, t, r, a)
  end

  def rounds_double(k, j, r) do
    rounds_double(k, j, 0, r, 0)
  end

  def rounds_double(0, _, t, _, a) do a/t * 4 end # beräkna medel?

  # Variabel betydelser
  #   k -> antalet rounds att göra
  #   j -> antalet test per round
  #   t -> totalt gjorda test
  #   r -> radius
  #   a -> ackumulator

  def rounds_double(k, j, t, r, a) do
    a = round(j, r, a)
    t = t+j
    pi = a/t * 4.0 #?
    #:io.format("~w, ~.7f, ~.7f\n", [t, pi, (pi - :math.pi())])
    :io.format("~w, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f\n", [t, Kernel.abs(pi - :math.pi()), 0.05, 0.005, 0.0005, 0.00005 , 0.000005, 0.0000005])
    rounds_double(k-1, j*2, t, r, a)
  end


  def createTasks(tasks, _, 0) do tasks end
  def createTasks(tasks, rounds, num_to_create) do
    task = Task.async(Carlo, :rounds, [1, rounds, 1000000000])
    createTasks([task|tasks], rounds, num_to_create-1)
  end

  def multiThread(threads, rounds) do
    tasks = createTasks([], rounds, threads)
    sum = Enum.reduce(tasks, 0,
      fn(task, acc) ->
        acc + Task.await(task, 1000*3600*24) # one day timeout
      end
    )
    sum / threads
  end

  def doHeavyTest(rounds_per_thread, darts_per_round, threads) do
    test_list = for i <- 1..rounds_per_thread do i end
    res = Enum.map(test_list, fn(x) ->
      IO.puts("#{x/rounds_per_thread*100.0}% done")
      multiThread(threads, darts_per_round)
    end)
    #res
    appr = (res |> Enum.sum())/rounds_per_thread
    IO.puts("DONE")
    :io.format("~w, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f, ~.7f\n", [threads*rounds_per_thread*darts_per_round, Kernel.abs(appr - :math.pi()), 0.05, 0.005, 0.0005, 0.00005 , 0.000005, 0.0000005])
  end

end
