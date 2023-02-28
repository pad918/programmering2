defmodule Train do

  ### Hjälpfunktioner ###
  def len([]) do 0 end
  def len([t|h]) do
    1+len(h)
  end

  def take(_, 0) do
    []#acc
  end

  def take([], _) do
    [] #:error # ? ? ?
  end

  #Rec
  def take([h|t], n) do
    [h|take(t, n-1)]
  end

  # Ta bort första n vagnarna
  def drop(train, 0) do train end
  def drop([], _) do
    :error # Borde nog bli error
  end
  def drop([t|h], n) do
    if n>1 do
      drop(h, n-1)
    else
      h
    end
  end

  # train1 + train2 = train1 ++ train2 (OBS INGA ++)
  def append([], train2) do
    train2
  end
  def append([h|t], train2) do
    [h|append(t, train2)]
  end

  # Är y en vagn i train?
  def member([], _) do
    false
  end
  def member([h|t], y) do
    if(h==y) do
      true
    else
      member(t, y)
    end
  end

  # 1 indexerade första positionen av y i tåget
  # Anta att vagnen finns i tåget!!!
  def position([h|t], y) do
    if(y==h) do
      1
    else
      1+position(t, y)
    end
  end

  # Splitta på en vagn (inkludera inte vagnen i någon av tupelsidorna)
  def split(train, y) do
    split_pos = position(train, y)
    len = len(train)
    #IO.puts("len = #{len}, pos = #{split_pos}")
    t1 = take(train, split_pos-1)
    t2 = drop(train, split_pos)
    {t1, t2}
  end

  # Retunerar en tuppel {k, remain, take}, n är antalet vagnar som behöver tas,
  # remain är vagnarna som finns kvar, take är vagnarna som tas, k är antalet vagnar fler som
  # behöver tas för att få n vagnar.

  # {k, remain, take}
  def main(train, n) do
    case {train, n} do
       {[], n} -> {n, [], []}
       {t, 0}  -> {0,  t, []}
       {[h|t], n} ->
        #Rekurivt kall
        if(n>0) do
          {n_, r_, t_} = main(t, n)
          if(n_<=0) do
            {0, [h|r_], t_}
          else
            {n_ - 1, r_, [h|t_]} # ganska säker på -1
          end
        end
    end
  end
end

defmodule Moves do
  def single({:one, n}, {main, one, two}) do
    # n>=0 ==> main --> one
    # n<0  ==> one  --> main
    if(n>=0) do
      {k, r, t} = Train.main(main, n)
      {r, Train.append(t, one), two}
    else
      n = -n
      take = Train.take(one, n)
      new_main = Train.append(main, take)
      new_one  = Train.drop(one, n)
      #IO.puts("INSPECTION = #{inspect({take, new_main, new_one})}")
      {new_main, new_one, two}
    end
  end

  def single({:two, n}, {main, one, two}) do
    # n>=0 ==> main --> two
    # n<0  ==> two  --> main
    if(n>=0) do
      {k, r, t} = Train.main(main, n)
      {r, one, Train.append(t, two)}
    else
      n = -n
      take = Train.take(two, n)
      new_main = Train.append(main, take)
      new_two  = Train.drop(two, n)
      #IO.puts("INSPECTION = #{inspect({take, new_main, new_one})}")
      {new_main, one, new_two}
    end
  end

  def sequence([], state) do state end
  def sequence([move|t], state) do
    new_state = single(move, state)
    [state|sequence(t, new_state)]
  end


  # Transfrom xs --> ys
  def find([], []) do [] end
  #def find([x], [x]) do [] end
  def find(xs, ys) do
    [y] = Train.take(ys, 1)
    {hs, ts} = Train.split(xs, y)
    ts_len = Train.len(ts)+1
    hs_len = Train.len(hs)
    moves = [{:one, ts_len}, {:two, hs_len}, {:one, -ts_len}, {:two, -hs_len}]
    [_ | new_ys] = ys
    new_xs = Train.append(ts, hs)
    #moves
    #IO.puts("xs = #{inspect(new_xs)}, ys = #{inspect(new_ys)}")
    Train.append(moves, find(new_xs, new_ys))
  end

  # Transfrom xs --> ys
  def few([], []) do [] end
  #def find([x], [x]) do [] end
  def few(xs, ys) do
    # is next already in right position?
    [xs_n|_] = xs
    [ys_n|_] = ys

    [y] = Train.take(ys, 1)
    {hs, ts} = Train.split(xs, y)
    ts_len = Train.len(ts)+1
    hs_len = Train.len(hs)
    moves = [{:one, ts_len}, {:two, hs_len}, {:one, -ts_len}, {:two, -hs_len}]
    [_ | new_ys] = ys
    new_xs = Train.append(ts, hs)
    #moves
    #IO.puts("xs = #{inspect(new_xs)}, ys = #{inspect(new_ys)}")
    if(ys_n==xs_n) do
      few(new_xs, new_ys)
    else
      Train.append(moves, few(new_xs, new_ys))
    end

  end

  def rules([]) do [] end
  def rules([h1]) do
    {_, n} = h1
    if(n == 0) do
      []
    else
      [h1]
    end
  end
  def rules([h1, h2|t]) do
    #IO.puts("h1 = #{inspect(h1)}, h2 = #{inspect(h2)}, t= #{inspect(t)}")
    {dir1, n1} = h1
    {dir2, n2} = h2
    #Testa förs 0 fallet
    if(n1==0) do
      rules([h2|t])
    else
      # Testa om de flyttar till/från samma
      if(dir1==dir2) do
        [{dir1, n1+n2}|rules(t)]
      else
        [h1|rules([h2|t])]
      end
    end

  end

  def compress(ms) do
    #IO.puts("ms= #{inspect(ms)}")
    ns = rules(ms)
    if(ns==ms) do
      ms
    else
      compress(ns)
    end
  end


end
