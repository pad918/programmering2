defmodule Huffman do

  def read(file) do
    {:ok, file} = File.open(file, [:read, :utf8])
    binary = IO.read(file, :all)
    File.close(file)
    case :unicode.characters_to_list(binary, :utf8) do
      {:incomplete, list, _} ->
        list
      list ->
        list
    end
  end

  def sample() do
    'the quick brown fox jumps over the lazy dog
    this is a sample text that we will use when we build
    up a table we will only handle lower case letters and
    no punctuation symbols the frequency will of course not
    represent english but it is probably not that far off'
  end

  def text() do
    'this is something that we should encode'
  end

  def bench_files() do
    files = [
      "benchmark_data/sample.txt",
      "benchmark_data/elixir.txt",
      "benchmark_data/advent4.txt",
      "benchmark_data/train.txt",
      "benchmark_data/filosof.txt",
      "benchmark_data/czech_covid.txt",
      "benchmark_data/computer_programming.txt",
      "benchmark_data/kallocain.txt"
    ]
  end

  def bench_all() do
    files = bench_files()
    encoded_table = encode_table(tree(read("benchmark_data/advent4.txt")))
    IO.puts("Basic bench results:")
    Enum.each(files, fn(file) -> benchmark(file, encoded_table) end)
  end

  def benchmark(path, encoded_table) do
    text = read(path)
    len = length(text)
    if(len<10000) do
      {encoding_time, encoded} = :timer.tc(fn -> encode(text, encoded_table) end)
      {encoding_time_fast, encoded} = :timer.tc(fn -> fast_encode([], text, encoded_table) end)
      {decoding_time, decoded} = :timer.tc(fn -> decode(encoded, encoded_table) end)
      IO.puts("#{length(text)}, #{encoding_time/1000}, #{encoding_time_fast/1000}, #{decoding_time/1000}, #{len/1000}, #{:math.pow(len/1000,2)}")
    else
      {encoding_time_fast, encoded} = :timer.tc(fn -> fast_encode([], text, encoded_table) end)
      {decoding_time, decoded} = :timer.tc(fn -> decode(encoded, encoded_table) end)
      IO.puts("#{length(text)}, nan, #{encoding_time_fast/1000}, #{decoding_time/1000}, #{len/1000}, #{:math.pow(len/1000,2)}")
    end
  end

  def benchmark_fast(path, encoded_table) do
    text = read(path)
    {encoding_time, encoded} = :timer.tc(fn -> fast_encode([], text, encoded_table) end)
    {decoding_time, decoded} = :timer.tc(fn -> decode(encoded, encoded_table) end)
    len = length(text)
    IO.puts("#{length(text)}, #{encoding_time/1000}, #{decoding_time/1000}, #{len/1000}, #{:math.pow(len/1000,2)}")
  end


  def test do
    sample = sample()
    IO.puts("Sample = #{sample}")
    tree = tree(sample)
    IO.puts("Tree = #{inspect(tree)}")
    encode = encode_table(tree)
    IO.puts("Encode = #{inspect(encode)}")

    decode = encode #decode_table(tree)
    IO.puts("Decode = #{inspect(decode)}")

    text = text()
    seq = encode(text, encode)
    decode(seq, decode)
  end

  def sort_key_val_list(list) do
    Enum.sort(list, fn({_, v1}, {_, v2}) -> v1<v2 end)
  end

  def map_to_list(map) do
    Enum.reduce(map, [], fn(pair, acc) ->
      case pair do
        [] -> acc
        p -> [p|acc]
      end
    end)
  end

  # Find frequency of characters in a sample
  def freq(sample) do
    sort_key_val_list(map_to_list(freq(sample, %{})))
  end

  def freq([], freq) do
    freq
  end

  def freq([char | rest], freq) do
    tot = case Map.get(freq, char) do
      nil -> 0
      n -> n
    end
    freq(rest, Map.put(freq, char, tot+1))
  end

  def smallet_first(list1, list2) do
    case {list1, list2} do
      {[], []} -> :none
      {[], _} ->  :right
      {_, []} ->  :left
      {[{_, l}|_], [{_, r}|_]} ->
        if(l<r) do
          :left
        else
          :right
        end
    end
  end

  def tree(sample) do
    freq = freq(sample)
    {tree, _total_chars} = huffman(freq)
    tree
  end

  def huffman([tree]) do
    tree
  end

  # trees är alltid sorterat för att förenkla användningen!
  def huffman(trees) do
    #IO.puts("ÄR I TREE/2")
    # Merga de två första
    [{t1, f1},{t2, f2}|rest] = trees
    #IO.puts("{t1, f1} = #{inspect({t1, f1})} {t2, f2} = #{inspect({t2, f2})}")
    new_tree = {{t1, t2}, f1+f2}

    #IO.puts("new_tree = #{inspect(new_tree)}")

    # Skapa det nya sorterade trädet och fortsätt
    sorted_new_trees = sort_key_val_list([new_tree|rest])
    #IO.puts("sorted_new_tree = #{inspect(sorted_new_trees)}")

    huffman(sorted_new_trees)
  end


  def is_leaf({left, right}) do
    case {is_integer(left), is_integer(right)} do
      {true, true}   -> :both
      {true, false}  -> :left
      {false, true}  -> :right
      {false, false} -> :none
    end
  end

  def encode_table(tree) do
    Map.new(encode_table(tree, :top))
  end

  def encode_table(elm, _) when is_integer(elm) do [] end

  # Right kan endast vara ett löv om left är ett löv, annars är den inte det
  def encode_table({left, right}, origin) do
    found =
    case is_leaf({left, right}) do
      :both ->
        [{left, [0]}, {right, [1]}]
      :left ->
        [{left, [0]}] ++ encode_table(right, :right)
      :right ->
        [{right, [1]}] ++ encode_table(left, :left)
      :none ->
        encode_table(left, :left) ++ encode_table(right, :right)
    end
    # Add origin to all found entries
    Enum.reduce(found, [], fn({char, path}, acc) ->
      case origin do
        :left  -> [{char, [0|path]}|acc]
        :right -> [{char, [1|path]}|acc]
        :top   -> [{char, path}|acc]
      end
    end)
  end

  def decode_table(tree) do
    # To implement...
  end

  #Långsam encode
  def encode(text, table) do
    Enum.reduce(text, [], fn(char, acc) ->
      acc ++ Map.get(table, char, [])
    end)
  end

  def fast_encode(bits, [], _) do bits end
  def fast_encode([], [c|h], table) do
    bits = Map.get(table, c, [])
    fast_encode(bits, h, table)
  end
  def fast_encode([b|h], chars, table) do
    [b|fast_encode(h, chars, table)]
  end

  def decode([], _) do
    []
  end

  def decode(seq, table) do
    {char, rest} = decode_char(seq, 1, table)
    [char | decode(rest, table)]
  end

  def decode_char(seq, n, table) do
    {code, rest} = Enum.split(seq, n)
    found = Enum.reduce(table, nil, fn({k, v}, acc) ->
      if(acc == nil && v == code) do
        k
      else
        acc
      end
    end)
    case found do
      nil ->
        decode_char(seq, n+1, table)
      char ->
        {char, rest}
    end
  end
end
