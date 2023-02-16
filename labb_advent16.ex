defmodule Day16 do

  def task(t) do
    start = :AA
    rows = File.stream!("advent16_input.txt")
    #rows = sample()
    #parsed_map = get_graph_map(parse(rows))
    parsed_map = Map.new(parse(rows))



    closed_taps = Map.new(Enum.filter(parsed_map,
      fn(x) ->
        {_, {rel, _}} = x
        rel != 0
      end
    ))

    #parsed
    best = optimize_path(:AA, [], parsed_map, t, closed_taps, %{})
    {moves, score, _} = best
    {score, moves}
  end


  # RETURNA: Valen vi gjort och hur bra de är!!!

  # Använd en accumulator (är det ens dynamiskt?)

  # optimize_path(current move, all made moves, time left, total released pressure, cache)

  # Måste retunera det uppbyggda cachen.


  def search_path(_, moves, graph, 0, _, cache) do
    {[], 0, cache}
  end

  def search_path(curr, moves, graph, time_left, closed_taps, cache) do
    # Testa alla möjligheter och välj den bästa!
    legal = get_legal_moves(curr, graph)

    taps_on = get_open_taps(moves)

    # Beräkna hur mycket tryck som släpptes i senaste minuten
    rate = total_pressure_release(taps_on, graph)

    # OBS!!! Borde inte vara allt för svårt
    # att lägga till detta som ett extrafall i legal
    # och göra allt i samma if-else

    # Försök bara när det är nödvändigt
    legal =
    if(Map.has_key?(closed_taps, curr)) do
      [{:on, curr}|legal]
    else
      legal
    end


    # Testa att gå alla andra möjliga vägar
    best_move = Enum.reduce(legal, {[], nil, -1, cache},
      fn(drag, acc) ->
        {_, _, _, new_cache} = acc
        {best_move, best_moves, value, new_cache} =
          case drag do
            {:on, turn_on} ->
              {best_moves, value, new_cache} =
                optimize_path(curr, [{:on, turn_on}|moves], graph, time_left-1, Map.put(closed_taps, turn_on, turn_on), new_cache)
              #new_cache = Map.put(new_cache, {kran, time_left-1, taps_on}, {best_moves, value})
              {{:on, turn_on}, best_moves, value, new_cache}
            kran ->
              {best_moves, value, new_cache} =
                optimize_path(kran, [{:move, kran}|moves], graph, time_left-1, closed_taps, new_cache)
              new_cache = Map.put(new_cache, {kran, time_left-1, taps_on}, {best_moves, value})
              {{:move, kran}, best_moves, value, new_cache}
          end

        # Add cache entry to new cache
        # cache_self_release = value-((time_left-1)*rate)

        new_acc = {best_moves, best_move, value + rate, new_cache} # FEL? OSÄKER på +rate

        {_,_, new_value, new_cache} = new_acc

        # Update acc if better
        {a_moves, a_best_move, a_max, _} = acc
        if(a_max<new_value) do
          new_acc
        else
          #Update the cache of acc
          {a_moves, a_best_move, a_max, new_cache}
        end
      end
    )

    {best_future_moves, move, value, new_cache} = best_move
    {[move | best_future_moves], value, new_cache}

  end


  # Två typer av moves:

  #   {:on,   kran_namn} # Kran_namn sätts på
  #   {:move, kran_namn} # gå till kran_namn


  def optimize_path(curr, moves, graph, time_left, closed_taps, cache) do
    open_taps = get_open_taps(moves)
    cached_result = cache[{curr, time_left, open_taps}]

    if(cached_result != nil) do

      {best_moves, released} = cached_result
      {best_moves, released, cache}
    else
      search_path(curr, moves, graph, time_left, closed_taps, cache)
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

  def get_graph_map(graph_list) do
    Enum.reduce(graph_list, %{},
      fn(line, acc) ->
        {k, v} = line
        Map.put(acc, k, v)
      end
    )
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

  # Lookup är långsam, använd en map istället för en lista med linjär sökning!!!
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

  def get_legal_moves(curr, graph) do
    case graph[curr] do
      nil -> []
      {_, list} -> list
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
    ["Valve AA has flow rate=0; tunnels lead to valves DD, II, BB",
     "Valve BB has flow rate=13; tunnels lead to valves CC, AA",
     "Valve CC has flow rate=2; tunnels lead to valves DD, BB",
     "Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE",
     "Valve EE has flow rate=3; tunnels lead to valves FF, DD",
     "Valve FF has flow rate=0; tunnels lead to valves EE, GG",
     "Valve GG has flow rate=0; tunnels lead to valves FF, HH",
     "Valve HH has flow rate=22; tunnel leads to valve GG",
     "Valve II has flow rate=0; tunnels lead to valves AA, JJ",
     "Valve JJ has flow rate=21; tunnel leads to valve II"]
    # [
    #   #"Valve AA has flow rate=10; tunnels lead to valves AA, BB",
    #   #"Valve BB has flow rate=20; tunnels lead to valves AA, BB",
    #   "Valve AA has flow rate=10; tunnels lead to valves BB, CC, DD",
    #   "Valve BB has flow rate=20; tunnels lead to valves AA, CC, DD",
    #   "Valve CC has flow rate=30; tunnels lead to valves BB, AA, DD",
    #   "Valve DD has flow rate=40; tunnels lead to valves BB, CC, AA",
    # ]
  end



end
