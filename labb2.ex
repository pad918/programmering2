defmodule EnvList do
  def new() do [] end

  #def add(map, key, value) do
  #  # Lägg till tupeln i början av listan.
  #  [{key, value}|map]
  #end

  # NY ADD:

  def add([], key, value) do
    [{key, value}]
  end

  def add([{k, v}|t], k, value) do
    [{k, value}|t]
  end

  def add([h|t], key, value) do
     [h|add(t, key, value)]
  end

  def lookup([{key, value}|_], key) do
    value
  end
#
  def lookup([_|t], key) do
    # Gör en rekursiv sökning om T inte är en tom lista
    # Annars returnera nil sökningen sökt igenom alla element
    case t do
      [] -> nil
      t  -> lookup(t, key)
    end
  end

  def remove(map, key) do
    remove_([], map, key)
  end

  # Om det första elementet i back är det som
  # ska tas bort, returnnera [front|back], annars
  # lägg till det på front och ta bort det från back.
  def remove_(front, [c|back], key) do
    {k, v} = c
    cmp = (k==key)
    #IO.puts("k = #{k}")
    case cmp do
      true -> front ++ back
      false -> remove_([c|front], back, key)
    end
  end

  def remove_(map, [], _) do
    map
  end

  #n         add      lookup      remove
#   16|    0.02    0.04    0.07|    0.07    0.04    0.07|    0.08    0.03    0.03|
#   32|    0.02    0.07    0.10|    0.07    0.05    0.08|    0.08    0.03    0.05|
#   64|    0.01    0.10    0.17|    0.07    0.05    0.08|    0.07    0.03    0.06|
#  128|    0.01    0.18    0.37|    0.09    0.06    0.10|    0.11    0.03    0.05|
#  256|    0.02    0.35    0.67|    0.09    0.06    0.09|    0.08    0.03    0.07|
#  512|    0.02    0.69    1.24|    0.10    0.07    0.11|    0.10    0.04    0.06|
# 1024|    0.02    1.58    2.80|    0.12    0.08    0.13|    0.09    0.04    0.08|
# 2048|    0.02    2.77    6.45|    0.14    0.09    0.14|    0.11    0.03    0.08|
# 4096|    0.02    5.40   20.04|    0.25    0.10    0.26|    0.13    0.03    0.15|
# 8192|    0.02   10.75   46.85|    0.31    0.11    0.33|    0.12    0.04    0.14|
#16384|    0.03   34.30   96.56|    0.41    0.19    0.55|    0.16    0.04    0.17|
#32768|    0.03   70.02  269.63|    0.61    0.17    0.54|    0.17    0.05    0.18|
#
#   16 & 0.07 &  0.04 &  0.07 & & \\
#   32 & 0.07 &  0.05 &  0.08 & & \\
#   64 & 0.07 &  0.05 &  0.08 & & \\
#  128 & 0.09 &  0.06 &  0.10 & & \\
#  256 & 0.09 &  0.06 &  0.09 & & \\
#  512 & 0.10 &  0.07 &  0.11 & & \\
# 1024 & 0.12 &  0.08 &  0.13 & & \\
# 2048 & 0.14 &  0.09 &  0.14 & & \\
# 4096 & 0.25 &  0.10 &  0.26 & & \\
# 8192 & 0.31 &  0.11 &  0.33 & & \\
#16384 & 0.41 &  0.19 &  0.55 & & \\
#32768 & 0.61 &  0.17 &  0.54 & & \\
#
#   16 & 0.08 & 0.03 & 0.03 &&\\
#   32 & 0.08 & 0.03 & 0.05 &&\\
#   64 & 0.07 & 0.03 & 0.06 &&\\
#  128 & 0.11 & 0.03 & 0.05 &&\\
#  256 & 0.08 & 0.03 & 0.07 &&\\
#  512 & 0.10 & 0.04 & 0.06 &&\\
# 1024 & 0.09 & 0.04 & 0.08 &&\\
# 2048 & 0.11 & 0.03 & 0.08 &&\\
# 4096 & 0.13 & 0.03 & 0.15 &&\\
# 8192 & 0.12 & 0.04 & 0.14 &&\\
#16384 & 0.16 & 0.04 & 0.17 &&\\
#32768 & 0.17 & 0.05 & 0.18 &&\\


  # Det makar inte sence att hålla listan sorterad
  # eftersom ingen sökalgoritm kan vara snabbare än
  # o(n) eftersom elementen måste sökas igenom linjärt.
  # Att inte hålla listan sorterad gör andra operationer
  # enklare och snabbare, därmed bör det inte sorteras.


end

# {:node, key, value, left, right}

defmodule EnvTree do

  ############### ADD ###############

  # Add to empty tree
  def add(nil, key, value) do
    {:node, key, value, nil, nil}
  end

  # Key is found
  def add({:node, key, _, left, right}, key, value) do
    {:node, key, value, left, right}
  end

  # Add to left branch
  def add({:node, k, v, left, right}, key, value) when key < k do
    {:node, k, v, add(left, key, value), right}
  end

  # Add to the right branch
  def add({:node, k, v, left, right}, key, value) do
    {:node, k, v, left, add(right, key, value)}
  end

  ############ LOOKUP ###############

  # If key is found
  def lookup({:node, key, value, _, _}, key) do
    value
  end

  # Search to the left
  def lookup({:node, k, _, left, _}, key) when key < k do
    lookup(left, key)
  end

  # Seach to the right
  def lookup({:node, _, _, _, right}, key) do
    lookup(right, key)
  end

  # If tree is in wrong format of empty (or the key is not pressent)
  # Return nil
  def lookup(_, _) do
    nil
  end

  ############ REMOVE #############
  def remove(nil, _) do nil end

  # When left is empty and key is found
  def remove({:node, key, _, nil, right}, key) do right end

  # When right is empty and key  is found
  def remove({:node, key, _, left, nil}, key) do left end

  # When key is found (Höger av e är f)
  def remove({:node, key, _, left, right}, key) do

    {new_key, new_value, :node, k, v, l, r} = leftmost(right) # Right = f
    #IO.puts("")
    if (new_key != k) do
      {:node, new_key, new_value, left, {:node, k, v, l, r}} # LITE OSÄKER!!!
    else
      {:node, new_key, new_value, left, r} # FEL HÄR?
    end
  end

  # Remove on the left
  def remove({:node, k, v, left, right}, key) when key < k do
    {:node, k, v, remove(left, key), right}
  end

  # Remove on the right
  def remove({:node, k, v, left, right}, key) do
    {:node, k, v, left, remove(right, key)}
  end

  # Left most is found
  def leftmost({:node, key, value, nil, rest}) do
    {key, value, :node, key, value, nil, rest}
  end

  # Vi kan bara ta bort element åvanifrån,
  # Men om den vänstraste kommer diekt måste vi ha ett speialfall!!!
  def leftmost({:node, k, v, left, right}) do
    #IO.puts("K = #{k}")
    {key, value, :node, k1, v1, l, r} = leftmost(left)
    {:node, k2, _, _, _} = left
    #IO.puts("k2 = #{k2}")
    # If leftmost is the next node to the left
    # remove it
    if  k2 == key do
      {key, value, :node, k, v, r, right} # Korrekt
    else
      {key, value, :node, k, v, {:node, k1, v1, l, r}, right} # Fel?
    end
  end


end


defmodule Benchmarks do

  def bench_all(n) do
    ls = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 1024*16, 1024*32]
    :io.format("# benchmark with ~w operations, time per operation in us\n", [n])
    :io.format("~6.s~12.s~12.s~12.s\n", ["n", "add", "lookup", "remove"])

    Enum.each(ls, fn(i) ->
      {i, tla, tll, tlr, tta, ttl, ttr, tma, tml, tmr} = bench_all(i, n)
      :io.format("~6.w|~8.2f~8.2f~8.2f|~8.2f~8.2f~8.2f|~8.2f~8.2f~8.2f|\n", [i, tla/n, tll/n, tlr/n,
      tta/n, ttl/n, ttr/n, tma/n, tml/n, tmr/n])
    end)
  end

  def bench_all(i, n) do
    seq = Enum.map(1..i, fn(_) -> :rand.uniform(i) end)

    list = Enum.reduce(seq, EnvList.new(), fn(e, list) ->
      EnvList.add(list, e, :foo) end)

    tree = Enum.reduce(seq, EnvTree.add(nil, :_a, 0), fn(e, tree) ->
      EnvTree.add(tree, e, :foo) end)

    map = Enum.reduce(seq, %{}, fn(e, map) -> Map.put(map, e, :foo) end)

    seq = Enum.map(1..n, fn(_) -> :rand.uniform(i) end)

    {map_add, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      Map.put(map, e, :foo) end) end)

    {map_lookup, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      Map.get(map, e)
      end) end)

    {map_remove, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      Map.delete(map, e)
      end) end)

    {tree_add, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvTree.add(tree, e, :foo) end) end)

    {tree_lookup, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvTree.lookup(tree, e)
      end) end)

    {tree_remove, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvTree.remove(tree, e)
      end) end)

    {list_add, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvList.add(list, e, :foo) end) end)

    {list_lookup, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvList.lookup(list, e)
      end) end)

    {list_remove, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvList.remove(list, e)
      end) end)

    {i, list_add, list_lookup, list_remove,
      tree_add, tree_lookup, tree_remove,
      map_add, map_lookup, map_remove}
  end

  def bench_list(n) do
    ls = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]
    :io.format("# benchmark with ~w operations, time per operation in us\n", [n])
    :io.format("~6.s~12.s~12.s~12.s\n", ["n", "add", "lookup", "remove"])

    Enum.each(ls, fn(i) ->
      {i, tla, tll, tlr} = bench_list(i, n)
      :io.format("~6.w~12.2f~12.2f~12.2f\n", [i, tla/n, tll/n, tlr/n])
    end)
  end

  def bench_list(i, n) do
    seq = Enum.map(1..i, fn(_) -> :rand.uniform(i) end)

    list = Enum.reduce(seq, EnvList.new(), fn(e, list) ->
      EnvList.add(list, e, :foo) end)

    seq = Enum.map(1..n, fn(_) -> :rand.uniform(i) end)

    {add, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvList.add(list, e, :foo) end) end)

    {lookup, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvList.lookup(list, e)
      end) end)

    {remove, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvList.remove(list, e)
      end) end)

    {i, add, lookup, remove}
  end

  def bench_tree(n) do
    ls = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]
    :io.format("# benchmark with ~w operations, time per operation in us\n", [n])
    :io.format("~6.s~12.s~12.s~12.s\n", ["n", "add", "lookup", "remove"])

    Enum.each(ls, fn(i) ->
      {i, tla, tll, tlr} = bench_tree(i, n)
      :io.format("~6.w~12.2f~12.2f~12.2f\n", [i, tla/n, tll/n, tlr/n])
    end)
  end

  def bench_tree(i, n) do

    # En map med i element?
    seq = Enum.map(1..i, fn(_) -> :rand.uniform(i) end)

    # En lista av key-value pairs
    list = Enum.reduce(seq, EnvTree.add(nil, :_a, 0), fn(e, list) ->
      EnvTree.add(list, e, :foo) end)


    # seq är en lista av ints 1 till i stora, n stycken
    seq = Enum.map(1..n, fn(_) -> :rand.uniform(i) end)


    {add, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvTree.add(list, e, :foo) end) end)

    {lookup, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvTree.lookup(list, e)
      end) end)

    {remove, _} = :timer.tc(fn() -> Enum.each(seq, fn(e) ->
      EnvTree.remove(list, e)
      end) end)

    {i, add, lookup, remove}
  end

end


#  0.03    0.05|    0.05    0.04    0.06|    0.06    0.03    0.03|
#  0.04    0.06|    0.06    0.05    0.06|    0.06    0.02    0.03|
#  0.08    0.13|    0.09    0.05    0.08|    0.08    0.03    0.06|
#  0.14    0.18|    0.08    0.05    0.09|    0.12    0.03    0.05|
#  0.28    0.39|    0.09    0.06    0.10|    0.14    0.03    0.06|
#  0.58    0.74|    0.10    0.07    0.10|    0.10    0.03    0.07|
#  1.06    1.63|    0.14    0.08    0.12|    0.10    0.03    0.07|
#  2.11    3.62|    0.14    0.09    0.15|    0.10    0.04    0.07|
#  4.29   14.31|    0.17    0.10    0.17|    0.12    0.03    0.13|
#   8.30   22.73|    0.19    0.11    0.19|    0.12    0.04    0.14|
#  23.96   69.91|    0.41    0.12    0.56|    0.15    0.04    0.17|
#   49.23  173.52|    0.53    0.17    0.82|    0.18    0.05    0.16|

0.04
0.06
0.13
0.21
0.44
0.84
1.83
3.72
6.84
17.55
63.62
141.20
