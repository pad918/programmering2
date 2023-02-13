defmodule High do

  ############# Simple examples ##############
  # def double([]) do [] end
  # def double([i|t]) do
  #   [2*i|double(t)]
  # end

  # def five([]) do [] end
  # def five([i|t]) do
  #   [(i+5)|five(t)]
  # end

  # def animal([]) do [] end
  # def animal([ani|t]) do
  #   case ani do
  #     :dog -> [:fido|animal(t)]
  #     _ -> [ani|animal(t)] # OBS TESTAR INTE ATT ALLA ÄR RÄTT DJUR
  #   end
  # end

  ########## All in one ##############
  def double_five_animal([], _) do [] end
  def double_five_animal([h|t], type) do
    case type do
      :five   -> [(5+h)|double_five_animal(t, :five)]
      :double -> [(2*h)|double_five_animal(t, :double)]
      :animal -> if a==:dog, do: :fido, else: a end
    end
  end

  def double(list) do
    double_five_animal(list, :double)
  end
  def five(list) do
    double_five_animal(list, :five)
  end
  def animal(list) do
    double_five_animal(list, :animal)
  end

  ########### FUNCTIONS AS DATA (samma som Enum.map/2) ############
  def apply_to_all([], _) do [] end
  def apply_to_all([h|t], f) do
    [f.(h)|apply_to_all(t, f)]
  end

  # Bara för att komma spara alla funktioner
  def apply_functions(type) do
    case type do
      :double -> fn(x) -> 2*x end
      :five   -> fn(x) -> 5+x end
      :animal -> fn(a) -> if a==:dog, do: :fido, else: a end
    end
  end

  ######### Reducing a list (same as List.foldl=Enum.reduce() and List.foldr) #########
  def sum_basic([]) do 0 end
  def sum_basic([s|t]) do
    s+sum_basic(t)
  end

  def fold_right([], base, _) do base end

  def fold_right([h|t], base, fun) do
    fun.(h, fold_right(t, base, fun))
  end

  def fold_left([], acc, _) do acc end

  def fold_left([h|t], acc, fun) do
    fold_left(t, fun.(h, acc), fun)
  end

  def fold_sum(list) do
    fold_right(list, 0, fn(x, y) -> x+y end)
  end

  def fold_prod(list) do
    fold_right(list, 1, fn(x, y) -> x*y end)
  end

  ############# Filter out the good ones? ###############
  def odd_basic([]) do [] end
  def odd_basic([h|t]) do
    if(rem(h,2)==1) do
      [h|odd_basic(t)]
    else
      odd_basic(t)
    end
  end

  def filter([], _) do [] end
  def filter([h|t], fun) do
    if(fun.(h)) do
      [h|filter(t, fun)]
    else
      filter(t, fun)
    end
  end

  def odd(list) do
    filter(list, fn(e) -> rem(e, 2)==1 end)
  end

  def even(list) do
    filter(list, fn(e) -> rem(e, 2)==0 end)
  end

  def greater_than_five(list) do
    filter(list, fn(e) -> e>5 end)
  end

  ######## Summary #########


end
