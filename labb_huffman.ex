defmodule Huffman do

  #def test_where(num) do
  #  text = read("benchmark_data/elixir.txt")
  #  found = Enum.find(text, false, fn(c) -> c == num end)
  #  Enum.reduce(text, 0,
  #    fn(x, acc) ->
  #      if(acc <= 0) do
  #        if(x == num)
  #          -acc
  #        else
  #          acc-1
  #        end
  #      else
  #        acc
  #      end
  #    end
  #  )
  #end


  def get_random_string_with_x_chart(x) when x<=0 do [] end
  def get_random_string_with_x_chart(x) do
    # mellan 97 och 128
    [:rand.uniform(30)+97|get_random_string_with_x_chart(x-1)]
  end

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
    encoded_table = encode_table(tree(read("benchmark_data/all.txt")))
    encoded_map   = encode_map(tree(read("benchmark_data/all.txt")))
    decoded_table = decode_table(tree(read("benchmark_data/all.txt")))
    decoded_map   = decode_map(tree(read("benchmark_data/all.txt")))
    IO.puts("map size: #{Map.size(encoded_map)}, list size = #{length(encoded_table)}")
    Enum.each(files, fn(file) -> benchmark(read(file), encoded_table, encoded_map, decoded_table, decoded_map) end)
    IO.puts("RANDOM BENCH:")
    sizes = [100, 512, 1000,2000,4000,8000,16000,32000,64000, 128000, 256000, 512000]
    Enum.each(sizes, fn(size) -> benchmark(get_random_string_with_x_chart(size),
      encoded_table, encoded_map, decoded_table, decoded_map) end)
  end


  def benchmark(text, encoded_table, encoded_map, decoded_table, decoded_map) do
    len = length(text)
    encoding_time = 0
    encoding_time_fast = 0
    decoding_time = 0
    decoding_time_fast = 0
    if(len<1000000) do
      {encoding_time,      encoded} = :timer.tc(fn -> encode(text, encoded_table) end)
      {encoding_time_fast, encoded} = :timer.tc(fn -> fast_encode(text, encoded_map) end)
      {decoding_time,      decoded} = :timer.tc(fn -> decode(encoded, decoded_table) end)
      {decoding_time_fast, decoded} = :timer.tc(fn -> fast_decode(encoded, decoded_map) end)
      # (n, enc, dec, enc_fast, dec_fast)
      IO.puts(
        "#{length(text)}, #{encoding_time/1000}, #{encoding_time_fast/1000}, #{decoding_time/1000}, #{decoding_time_fast/1000}, #{len/1000}, #{:math.pow(len/1000,2)}"
        )
    else
      # (n, enc, dec, enc_fast, dec_fast)
      {encoding_time_fast, encoded}      = :timer.tc(fn -> fast_encode(text, encoded_map) end)
      {decoding_time, decoded}      = :timer.tc(fn -> decode(encoded, decoded_table) end)
      IO.puts("#{length(text)}, nan, #{encoding_time_fast/1000}, #{decoding_time/1000}, nan, #{len/1000}, #{:math.pow(len/1000,2)}")
    end
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
      n   -> n
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
    # Merga de två första
    [{t1, f1},{t2, f2}|rest] = trees
    new_tree = {{t1, t2}, f1+f2}
    # Skapa det nya sorterade trädet och fortsätt
    sorted_new_trees = sort_key_val_list([new_tree|rest])

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

  def encode_map(tree) do
    Map.new(encode_table(tree, :top))
  end

  def encode_table(tree) do
    encode_table(tree, :top)
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

  def decode_map(tree) do
    table = encode_table(tree)
    Enum.reduce(table, %{}, fn({k, v}, dec_map) ->
      Map.put(dec_map, v, k)
    end)
  end

  def decode_table(tree) do
    encode_table(tree)
  end

  #Encode använder listor
  def encode(text, table) do encode([], text, table) end
  def encode(bits, [], _) do bits end
  def encode([], [c|h], table) do
    {_, bits} = List.keyfind(table, c, 0, {[], []})
    encode(bits, h, table)
  end
  def encode([b|h], chars, table) do
    [b|encode(h, chars, table)]
  end

  # Fast_encode använder maps
  def fast_encode(text, table) do fast_encode([], text, table) end
  def fast_encode(bits, [], _) do bits end
  def fast_encode([], [c|h], table) do
    bits = Map.get(table, c, [])
    fast_encode(bits, h, table)
  end
  def fast_encode([b|h], chars, table) do
    [b|fast_encode(h, chars, table)]
  end

  def fast_decode([], _) do [] end

  def fast_decode(seq, map) do
    {char, rest} = decode_char_fast(seq, 1, map)
    [char | fast_decode(rest, map)]
  end

  def decode([], _) do [] end

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

  def decode_char_fast(seq, n, map) do
    {code, rest} = Enum.split(seq, n)
    found = Map.get(map, code)
    case found do
      nil ->
        decode_char_fast(seq, n+1, map)
      char ->
        {char, rest}
    end
  end

end
