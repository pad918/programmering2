defmodule Hanoi do

  # Basfall
  def hanoi(0, _, _, _) do [] end

  def hanoi(n, from, aux, to) do
    # Flytta rekursivt ett torn av storleken n-1 från "from" till "aux"
    s1 = hanoi(n-1, from, to, aux)

    # Flytta ett block från "from" till "to"
    s2 = [{:move, from, to}]

    # Flytta rekurisvt ett torn av storleken n-1 från "aux" till "to"
    s3 = hanoi(n-1, aux, from, to)

    # Sätt ihop dragen i rätt ordning och returnera
    (s1 ++ s2) ++ s3

  end



  def elmInList([h|t]) do
    1+elmInList(t)
  end

  def elmInList(_) do
    0
  end
end
