defmodule Morse do

  # Benchmark:
    # Encoda 88kB text  -> 16ms
    # Decoda samma text -> 9ms

    # Encoda 1MB text   -> 270ms
    # Decoda samma text -> 170ms

    # Encoda 10MB text  ->

  def bench(len, n) do
    rnd = rnd_text(len)
    enc = encode_map()
    tup = encode_tuple()
    dec = decode_table()
    ln = List.duplicate(nil, n)

    {map, tup, dec} = Enum.reduce(ln, {0,0,0}, fn(x, {a,b,c}) ->
      {enc_time_map, encoded} = :timer.tc(fn() -> encode_with_map(rnd, enc) end)
      {enc_time_tuple, encoded} = :timer.tc(fn() -> encode_with_tuple(rnd, tup) end)
      {dec_time, _} = :timer.tc(fn() -> decode(encoded, dec) end)
      {a+enc_time_map/1000, b+enc_time_tuple/1000, c+dec_time/1000}
    end)

    IO.puts("#{len}, #{map/n}, #{tup/n}, #{dec/n}")
  end

  def bench_all() do
    benchs = [1000, 2000, 4000, 8000, 16000, 32000, 64000, 128000, 256000, 512000,
    1024000]#, 2048000]#, 4096000, 8192000]
    Enum.each(benchs, fn(len) -> bench(len, 3) end)
  end

  def rnd_text(len) do
    rnd_text(len, [])
  end
  def rnd_text(0, acc) do acc end
  def rnd_text(len, acc) do
    c = :rand.uniform(24)+97
    rnd_text(len-1, [c|acc])
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


def encode_map() do
  tree = decode_tree()
  list = encode_list(tree, :top)
  Map.new(list)
  # Create a map of the characters from [symbol] --> [morse[]]
end

def encode_tuple() do
  tree = decode_tree()
  list = encode_list(tree, :top)
  tuple = Tuple.duplicate(nil, 130)
  Enum.reduce(list, tuple, fn({k, v}, t_acc) ->
    put_elem(t_acc, k, v)
  end)
end

def encode_list(nil, _) do [] end

def encode_list({:node, :na, l, r}, origin) do
  found = encode_list(l, :da) ++ encode_list(r, :di)
  Enum.reduce(found, [], fn({v, path}, acc) ->
    case origin do
      :da  -> [{v, [45|path]}|acc]
      :di  -> [{v, [46|path]}|acc]
      :top -> [{v, path}|acc]
    end
  end)
end

def encode_list({:node, v, l, r}, origin) do
  found = [{v, []}] ++ encode_list(l, :da) ++ encode_list(r, :di)
  Enum.reduce(found, [], fn({v, path}, acc) ->
    case origin do
      :da  -> [{v, [45|path]}|acc]
      :di  -> [{v, [46|path]}|acc]
      :top -> [{v, path}|acc]
    end
  end)
end


def encode_with_tuple(string, encode_tuple) do
  encode_acc_tuple(reverse_list(string, []), encode_tuple, [])
end

# Must reverse the string first!
def encode_with_map(string, encode_map) do
  encode_acc_map(reverse_list(string, []), encode_map, [])
end

def reverse_list([], acc) do acc end
def reverse_list([h|t], acc) do
  reverse_list(t, [h|acc])
end

def encode_acc_map([], _, acc) do acc end
def encode_acc_map([c|t], encode_map, acc) do
  morse = Map.get(encode_map, c)
  new_acc = morse ++ [?\s|acc]
  encode_acc_map(t, encode_map, new_acc)
end

def encode_acc_tuple([], _, acc) do acc end
def encode_acc_tuple([c|t], encode_tuple, acc) do
  morse = elem(encode_tuple, c)
  new_acc = morse ++ [?\s|acc]
  encode_acc_tuple(t, encode_tuple, new_acc)
end


# k = antalet symboler, m = längden av en moorsekod.
# För att få O(m) lookup måste ett träd användas. Den kommer alltid söka
# m steg ner i trädet för att hitta rätt ==> O(m) tidskomplexitet

def decode_table() do
  tree = decode_tree()
  decode_table(tree)
end

def decode_table(nil) do nil end
def decode_table({:node, value, l, r}) do
  {value, decode_table(l), decode_table(r)}
end

def lookup([?\s|t], dec_table) do
  {v, _, _} = dec_table;
  {v, t} # Return value and the rest of the characters to decode
end
def lookup([c|t], {_v, r, l}) do
  # Go to direction of c
  case c do
    ?. -> lookup(t, l)
    ?- -> lookup(t, r)
  end
end

def decode(string, dec_table) do
  result = decode(string, dec_table, [])
  reverse_list(result, [])
end

def decode([], _, acc) do acc end

def decode(string, dec_table, acc) do
  {v, rest} = lookup(string, dec_table)
  decode(rest, dec_table, [v|acc])
end


def base() do
  '.- .-.. .-.. ..-- -.-- --- ..- .-. ..-- -... .- ... . ..-- .- .-. . ..-- -... . .-.. --- -. --. ..-- - --- ..-- ..- ... '
end

def rolled() do
  '.... - - .--. ... ---... .----- .----- .-- .-- .-- .-.-.- -.-- --- ..- - ..- -... . .-.-.- -.-. --- -- .----- .-- .- - -.-. .... ..--.. ...- .----. -.. .--.-- ..... .---- .-- ....- .-- ----. .--.-- ..... --... --. .--.-- ..... ---.. -.-. .--.-- ..... .---- '
end

#The decoding tree.

def decode_tree() do
  na = :na # varför inte så i koden?
  node = :node
  {node, na,
      {node,116,
            {node,109,
                  {node,111,
                        {node,na,{node,48,nil,nil},{node,57,nil,nil}},
                        {node,na,nil,{node,56,nil,{node,58,nil,nil}}}},
                  {node,103,
                        {node,113,nil,nil},
                        {node,122,
                              {node,na,{node,44,nil,nil},nil},
                              {node,55,nil,nil}}}},
            {node,110,
                  {node,107,{node,121,nil,nil},{node,99,nil,nil}},
                  {node,100,
                        {node,120,nil,nil},
                        {node,98,nil,{node,54,{node,45,nil,nil},nil}}}}},
      {node,101,
            {node,97,
                  {node,119,
                        {node,106,
                              {node,49,{node,47,nil,nil},{node,61,nil,nil}},
                              nil},
                        {node,112,
                              {node,na,{node,37,nil,nil},{node,64,nil,nil}},
                              nil}},
                  {node,114,
                        {node,na,nil,{node,na,{node,46,nil,nil},nil}},
                        {node,108,nil,nil}}},
            {node,105,
                  {node,117,
                        {node,32,
                              {node,50,nil,nil},
                              {node,na,nil,{node,63,nil,nil}}},
                        {node,102,nil,nil}},
                  {node,115,
                        {node,118,{node,51,nil,nil},nil},
                        {node,104,{node,52,nil,nil},{node,53,nil,nil}}}}}}
  end
# The codes in an ordered list.
# def codes() do
#     [{32,"..--"},
#      {37,".--.--"},
#      {44,"--..--"},
#      {45,"-....-"},
#      {46,".-.-.-"},
#      {47,".-----"},
#      {48,"-----"},
#      {49,".----"},
#      {50,"..---"},
#      {51,"...--"},
#      {52,"....-"},
#      {53,"....."},
#      {54,"-...."},
#      {55,"--..."},
#      {56,"---.."},
#      {57,"----."},
#      {58,"---..."},
#      {61,".----."},
#      {63,"..--.."},
#      {64,".--.-."},
#      {97,".-"},
#      {98,"-..."},
#      {99,"-.-."},
#      {100,"-.."},
#      {101,"."},
#      {102,"..-."},
#      {103,"--."},
#      {104,"...."},
#      {105,".."},
#      {106,".---"},
#      {107,"-.-"},
#      {108,".-.."},
#      {109,"--"},
#      {110,"-."},
#      {111,"---"},
#      {112,".--."},
#      {113,"--.-"},
#      {114,".-."},
#      {115,"..."},
#      {116,"-"},
#      {117,"..-"},
#      {118,"...-"},
#      {119,".--"},
#      {120,"-..-"},
#      {121,"-.--"},
#      {122,"--.."}]
#   end

end
