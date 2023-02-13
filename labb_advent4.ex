defmodule Advent4 do
  def readFile(path) do
    rows = File.stream!(path)
    rows
  end

  def parse(stream) do
    Enum.reduce(stream, [],
      fn(row, acc) ->

        #Splitta upp raden
        [elf1, elf2] = String.split(row, ",")
        [e1_s, e1_e] = String.split(elf1, "-")
        [e2_s, e2_e] = String.split(elf2, "-")

        # Parsa till integers
        {e1_start, _} = Integer.parse(e1_s)
        {e1_end, _}   = Integer.parse(e1_e)
        {e2_start, _} = Integer.parse(e2_s)
        {e2_end, _}   = Integer.parse(e2_e)

        # Return
        [{e1_start, e1_end, e2_start, e2_end} |acc]
      end
    )
  end

  # Del 1
  def count_fully_contained(pairs) do
    Enum.reduce(pairs, 0,
      fn(pair, acc) ->
        {e1_s, e1_e, e2_s, e2_e} = pair
        e1_contains_e2 = a_fully_contains_b({e1_s, e1_e}, {e2_s, e2_e})
        e2_contains_e1 = a_fully_contains_b({e2_s, e2_e}, {e1_s, e1_e})
        if e1_contains_e2 || e2_contains_e1 do
          1+acc
        else
          acc
        end
      end
    )
  end

  # Del 2
  def count_overlapping(pairs) do
    Enum.reduce(pairs, 0,
      fn(pair, acc) ->
        if overlaps(pair) do
          1+acc
        else
          acc
        end
      end
    )
  end


  def a_fully_contains_b({e1_s, e1_e}, {e2_s, e2_e}) do
    if(e2_s>=e1_s && e2_e<=e1_e) do
      true
    else
      false
    end
  end
  def fully_contains(_, _) do
    :error
  end

  def in_range(num, {min, max}) do
    num>=min && num<=max
  end

  def overlaps({e1_s, e1_e, e2_s, e2_e}) do
    in_range(e1_s, {e2_s, e2_e}) || in_range(e1_e, {e2_s, e2_e})
    || in_range(e2_s, {e1_s, e1_e}) || in_range(e2_e, {e1_s, e1_e})
  end

end
