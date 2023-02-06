defmodule Hanoi do

  #Base case
  def hanoi(0, _, _, _) do
    []
  end

  def hanoi(n, from, aux, to) do
    # Move tower of size n-1 times from "from" to "aux" rekursivt såklart
    toAux = hanoi(n-1, from, to, aux)
    #toAux = doNTimes({:move, from, aux}, n-1)
    ## move one from "from" to "to"
    toTo = [{:move, from, to}]

    # Move tower of size n-1
    recersiveStep = hanoi(n-1, aux, from, to) # Verkar lite knas?

    # Return
    (toAux ++ toTo) ++ recersiveStep

  end



  def elmInList([h|t]) do
    1+elmInList(t)
  end

  def elmInList(_) do
    0
  end
end
