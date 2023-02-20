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
    pi = a/t * 4 #?
    :io.format("|~.7f|~.7f|\n", [pi, (pi - :math.pi())])
    rounds(k-1, j, t, r, a)
  end


  def createTasks(tasks, _, 0) do tasks end
  def createTasks(tasks, rounds, num_to_create) do
    task = Task.async(Carlo, :rounds, [1, rounds, 100000000000])
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

  def doHeavyTest(tests, roundsPerTest, threads) do
    test_list = for i <- 1..tests do 0 end
    res = Enum.map(test_list, fn(x) ->
      multiThread(threads, roundsPerTest)
    end)
    #res
    (res |> Enum.sum())/tests
  end

end
