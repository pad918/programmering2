defmodule Huffman do
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

  def test do
    sample = sample()
    tree = tree(sample)
    encode = encode_table(tree)
    decode = decode_table(tree)
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
