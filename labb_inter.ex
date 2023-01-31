defmodule Env do

  def inList(_, []) do
    false
  end

  def inList(id, [id|_])do
    true
  end

  def inList(id, [_|t]) do
    inList(id, t)
  end

  def new() do [] end

  def add(id, str, []) do
    [{id, str}]
  end

  # Error if value is updated
  def add(id, str, [{id, _}|t]) do
    #:error
    [{id, str} | t]
  end

  def add(id, str, [h|t]) do
    [h|add(id, str, t)]
  end

  def lookup(_, []) do
    nil
  end

  def lookup(id, [{id, str}|_]) do
    {id, str}
  end

  def lookup(id, [_|t]) do
    lookup(id, t)
  end


  def remove(_, []) do
    []
  end

  def remove(ids, [{id, val}|t]) do
    if(inList(id, ids)) do
      remove(ids, t)
    else
      [{id, val}|remove(ids, t)]
    end
  end

  # HUR FUNGERAR:
  #   Skapa en ny env där endast de fria variablernas
  #   bindningar finns kvar
  def closure(free, env) do
    #IO.puts("env = #{env}")
    closure(free, env, new())
  end

  def closure([], bindings, new_env) do
    new_env
  end

  def closure([h|t], bindings, new_env) do
    case lookup(h, bindings) do
      {k, v} -> closure(t, bindings, add(k, v, new_env))
      nil -> closure(t, bindings, new_env)
    end
  end

  # Env.args(par, strs, closure)
  # OBS ! Ganska säker på att den är rätt!
  def args([v|pars], [s|strs], closure) do
    args(pars, strs, add(v, s, closure))
  end

  def args(_, _, closure) do
    closure
  end

end

# terms and patterns
# {:var, v}
# {:atm, a}
# {:cons, head, tail} = {head, tail}
# :ignore = _

# {:cons, {:atm, :a}, {:cons, {:var, :x}, {:atm, :b}}}

# Expressions:

defmodule Eager do
  # eval_expr(expr, env)

  # Tar en expression och en envi och ger en structure

  def eval_expr({:atm, id}, _) do {:ok, id} end

  def eval_expr({:var, id}, env) do
    case Env.lookup(id, env) do
      nil       -> :error # Lite osäker!!!
      {_, str}  -> {:ok, str}
    end
  end

  def eval_expr({:cons, h, t}, env) do
    case eval_expr(h, env) do
      :error -> :error # Tror
      {:ok, hs} ->
        case eval_expr(t, env) do
          :error -> :error
          {:ok, ts} -> {:ok, {hs, ts}} # Chansning
        end
    end
  end

  # {:case, expression, list of clauses}
  def eval_expr({:case, expr, cls}, env) do
    case eval_expr(expr, env) do
      :error ->
        :error # lite osäker om rätt
      {:ok, str} ->
        eval_cls(cls, str, env)
    end
  end

  def eval_cls([], _, _) do
    :error
  end

  def eval_cls([{:clause, ptr, seq} | cls], str, env) do
    # Två tomma rader här
    # Försöker ha lura oss eller?
    case eval_match(ptr, str, env) do
      :fail ->
        eval_cls(cls, str, env)
      {:ok, new_env} ->
        eval_seq(seq, new_env) # GIssning
    end
  end

  # TEST
    #Eager.eval_expr({:case, {:var, :x}, [{:clause, {:atm, :a}, [{:var, :x}]}, {:clause, {:atm, :b}, [{:var, :y}]}]}, [x: :b, y: :k])

  ##### LAMBDA #####
  # {:lambda, params[], free[], sequence[]}
  # Results in
  # {:closure, parameters, seqence, environment}
  # Function:
  # {:apply, expression, arguments}

  def eval_expr({:lambda, par, free, seq}, env) do
    case Env.closure(free, env) do
      :error ->
        :error
      closure ->
        {:ok, {:closure, par, seq, closure}} # Kolla definition, tror det är rätt
    end
  end

  def eval_expr({:apply, expr, args}, env) do
    case eval_expr(expr, env) do
      :error ->
        :error
      {:ok, {:closure, par, seq, closure}} ->
        #case eval_args(par, closure) do # Kanske fel
        case eval_args(par, args) do # Kanske rätt?
          :error ->
            :error
          {:ok, strs} ->
            env = Env.args(par, strs, closure)
            eval_seq(seq, env)
        end
    end
  end


  # OBS strs är en lista av datastructures
  # Som matcher argumenten !!!


  def eval_args_([p|para], [a|args]) do
    #{kk, vv} = a
    #IO.puts("p = #{p} | a = {#{kk}, #{vv}}")
    case eval([{:match, {:var, p}, a}, {:var, p}]) do
      {:ok, res} -> [res|eval_args_(para, args)]
      :error -> :error
    end
  end

  def eval_args_(_, _) do [] end

  def eval_args(para, args) do
    #print_all(para)
    #print_all(args)
    {:ok, eval_args_(para, args)}
  end



  def print_all([]) do IO.puts("Done") end
  def print_all([{k, v}|str]) do
    IO.puts("{#{k}, #{v}}")
    print_all(str)
  end
  def print_all([c|str]) do
    IO.puts(c)
    print_all(str)
  end

  # seq =
  #   [
  #     {:match, {:var, :x}, {:atm, :a}},
  #     {:match, {:var, :f},
  #       {:lambda, [:y], [:x], [{:cons, {:var, :x}, {:var, :y}}]}},
  #     {:apply, {:var, :f}, [{:atm, :b}]}
  #     # ger f = l(:b)? ==> [{:f, {:a, :b}}] vilket skrivs som {:a, :b}
  #     # FUCK YES!!!
  #   ]
    ############# eval_match/3 #############
  # {pat, str, env}
  def eval_match(:ignore, _, env) do {:ok, env} end

  def eval_match({:atm, id}, id, env) do {:ok, env} end
  def eval_match({:atm, _}, _, _) do :fail end

  def eval_match({:var, id}, s, env) do
    case Env.lookup(id, env) do
      nil -> {:ok, Env.add(id, s, env)}
      t   ->
        if (t == {id, s}) do
          {:ok, env}
        else
          :fail
        end
    end
  end

  # Ganska säker på att detta fungerar som det ska
  def eval_match({:cons, hp, tp}, {s1, s2}, env) do
    case eval_match(hp, s1, env) do
      :fail ->
        :fail
      {:ok, env_new} ->
        eval_match(tp, s2, env_new)
    end
  end


  ## ---> Failar nu? FUCK YES!!! HÄR ÄR FELET
  def eval_match(_, _, _) do :fail end



  def extract_vars({:var, v}) do [v] end

  def extract_vars({:cons, a1, a2}) do
    extract_vars(a1) ++ extract_vars(a2)
  end

  def extract_vars(_) do [] end
  ######## SEQUENCE #######
    # Består av n-1 antal pattern = expressions ; följt av ett exresssion
    # Totalt n lång
    # Match: {:match, pat, expr}

  def eval_scope(pat, env) do
    Env.remove(extract_vars(pat), env)
  end


  def eval_seq([exp], env) do
    eval_expr(exp, env)
  end

  # RETURNS A SCOPE
  def eval_seq([{:match, pat, exp} | t], env) do
    #IO.puts("pat = #{pat}")
    case eval_expr(exp, env) do # Hämtar strukturen
      :error ->
        :error # Gissning
      {:ok, str} ->
        new_scope = eval_scope(pat, env)
        case eval_match(pat, str, new_scope) do
          :fail -> :error
          {:ok, n_env} -> eval_seq(t, n_env) # Gissning 50%
        end

    end
  end

  def eval(seq) do
    eval_seq(seq, [])
  end

  # Resten av uppgiften kommer att ta ~2h

  # Tests
  #seq = [
  #  {:match,  {:var, :x}, {:atm, :foo}},
  #  {:match,  {:var, :y}, {:atm, :nil}},
  #  {:match,  {:cons, {:var, :z}, :ignore},
  #            {:cons, {:atm, :bar}, {:atm, :grk}}},
  #  {:cons, {:var, :x}, {:cons, {:var, :z}, {:var, :y}}}]
  #seq = [{:match, :ignore, {:atm, 20}}, {:match, {:var, :y}, {:atm, 20}}, {:cons, {:var, :y}, {:var, :y}}]
  #seq = [{:match, {:var, :x}, {:atm,:a}},
  #  {:match, {:var, :y}, {:cons, {:var, :x}, {:atm, :b}}},
  #  {:match, {:cons, :ignore, {:var, :z}}, {:var, :y}},
  #  {:var, :z}]

end

defmodule Interpreter do

end
