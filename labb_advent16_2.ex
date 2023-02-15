defmodule Day16 do

  def task(t) do
    start = :AA
    #rows = File.stream!("day16.csv")
    rows = sample()
    parsed = parse(rows)
    parsed
    best = optimize_path(:AA, [], parsed, t, 0, %{})
    {moves, score, _} = best
    {score, moves}
  end


  # RETURNA: Valen vi gjort och hur bra de är!!!

  # Använd en accumulator (är det ens dynamiskt?)

  # optimize_path(current move, all made moves, time left, total released pressure, cache)

  # Måste retunera det uppbyggda cachen.

  def optimize_path(_, moves, graph, 0, relesed_presure, cache) do
    # Add released pressure from open taps
    open_taps = get_open_taps(moves)
    # Add presure of open taps
    total_realeased = relesed_presure + total_pressure_release(open_taps, graph)
    {[], total_realeased, cache}
  end

  # Två typer av moves:

  #   {:on, kran_namn} # Kran_namn sätts på
  #   {:move, kran_namn} # gå till kranamn


  def optimize_path(curr, moves, graph, time_left, relesed_pressure, cache) do

    # Testa alla möjligheter och välj den bästa!
    legal = get_legal_moves(curr, graph)


    taps_on = get_open_taps(moves)

    # Beräkna hur mycket tryck som släpptes i senaste minuten

    rate = total_pressure_release(taps_on, graph)
    total = relesed_pressure + rate
    # Låt den inte sätta på om kranen redan är påsatt.
    turn_on_tap_move = optimize_path(curr, [{:on, curr}|moves], graph, time_left-1, total, cache)
    {_, _, new_cache} = turn_on_tap_move



    # Testa att gå alla andra möjliga vägar
    best_move = Enum.reduce(legal, {[], nil, -10, new_cache},
      fn(kran, acc) ->
        {_, _, _, new_cache} = acc
        # is_tap_on = if(is_tap_on(kran, taps_on)) do :on else :off end
        # Kolla om vägen redan finns i cachen
        cached_result = new_cache[{kran, time_left, taps_on}]

        IO.puts("-------------------")
        IO.puts("Curr: #{curr}, DEAPTH: #{time_left}")
        IO.inspect(cache)
        IO.inspect(taps_on)

        new_acc =
        if(cached_result != nil) do
          # IO.puts("+")
          {best_moves, value} = cached_result
          total_release_if_taken = value + (time_left)*rate # ska det vara -1?
          {best_moves, kran, value, new_cache}
        else
          # IO.puts("-")
          {best_moves, value, new_cache} = optimize_path(kran, [{:move, kran}|moves], graph, time_left-1, total, new_cache)
          # Add cache entry to new cache
          cache_self_release = value-(time_left*rate)
          new_cache = Map.put(new_cache, {kran, time_left-1, taps_on}, {best_moves, cache_self_release})
          {best_moves, kran, value, new_cache}
        end
        #IO.inspect(new_acc)
        {_,_, new_value, new_cache} = new_acc
        # Update acc if better
        {a_moves, a_kran, a_max, _} = acc
        if(a_max<new_value) do
          new_acc
        else
          #Update the cache
          {a_moves, a_kran, a_max,  new_cache}
        end
      end
    )



    {_, _, best_move_realeased, new_cache} = best_move
    {_, turn_on_released, _} = turn_on_tap_move


    # LÄGG ÄVEN TILL DET NYA MOVET!!!
    if(best_move_realeased >= turn_on_released) do
      {best_future_moves, kran, value, _} = best_move
      {[{:move, kran} | best_future_moves], value, new_cache}
    else
      {best_future_moves, value, _} = turn_on_tap_move
      {[{:on,   curr} | best_future_moves], value, new_cache}
    end

  end

  def total_pressure_release(open_taps, graph) do
    Enum.reduce(open_taps, 0,
      fn(tap_tap, acc) ->
        {tap, _} = tap_tap
        {ppm, _} = lookup(tap, graph)
        acc + ppm
      end
    )
  end

  def get_open_taps(moves) do
    taps_on = Enum.reduce(moves, %{},
      fn(move, acc) ->
        {type, kran} = move
        if(type==:on) do
          # Get pressure release per minute of kran
          Map.put(acc, kran, :on)
        else
          acc
        end
      end
    )
    taps_on
  end

  def is_in_map(_, []) do false end
  def is_in_map(key, map) do
    Enum.reduce(map, false,
      fn({k, v}, acc) ->
        acc || k==key
      end
    )
  end

  def is_tap_on(tap, taps) do
    Map.has_key?(taps, tap)
  end

  def lookup(_, []) do [] end
  def lookup(key, map) do
    filterd = Enum.filter(map, fn({x,_}) -> x==key end)
    if (filterd==[]) do
      []
    else
      [pair] = filterd
      {k, v} = pair
      v
    end
  end

  def get_legal_moves(curr, moves) do
    tups = lookup(curr, moves)
    if(tups==nil) do
      []
    else
      {_, list} = tups
      list
    end
  end

  ## turning rows
  ##
  ##  "Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE"
  ##
  ## into tuples
  ##
  ##  {:DD, {20, [:CC, :AA, :EE]}
  ##

  def parse(input) do
    Enum.map(input, fn(row) ->
      [valve, rate, valves] = String.split(String.trim(row), ["=", ";"])
      [_Valve, valve | _has_flow_rate ] = String.split(valve, [" "])
      valve = String.to_atom(valve)
      {rate,_} = Integer.parse(rate)
      [_, _tunnels,_lead,_to,_valves| valves] = String.split(valves, [" "])
      valves = Enum.map(valves, fn(valve) -> String.to_atom(String.trim(valve,",")) end)
      {valve, {rate, valves}}
    end)
  end

  def sample() do
    # OBS FLOW RATE AV AA = 0 från början!!!
    ["Valve AA has flow rate=1; tunnels lead to valves DD, II, BB",
     "Valve BB has flow rate=13; tunnels lead to valves CC, AA",
     "Valve CC has flow rate=2; tunnels lead to valves DD, BB",
     "Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE",
     "Valve EE has flow rate=3; tunnels lead to valves FF, DD",
     "Valve FF has flow rate=0; tunnels lead to valves EE, GG",
     "Valve GG has flow rate=0; tunnels lead to valves FF, HH",
     "Valve HH has flow rate=22; tunnel leads to valve GG",
     "Valve II has flow rate=0; tunnels lead to valves AA, JJ",
     "Valve JJ has flow rate=21; tunnel leads to valve II"]
  end



end
