defmodule Main do
  #Types
  @type literal() :: {:num, number()} | {:var, atom()}
  @type expr() :: {:add, expr(), expr()}
  | {:mul, expr(), expr()}
  | literal()

  ### Functions ###

  # SIMPLA VÄNSTER, SIMPLA HÖGER, SIMPLA DIG SJÄLV!!!
  # SIMPLIFICATION CODE:

  # OBS! LÖSNINGEN PÅ VÄRLDENS ALLA PROBLEM ÄR ATT REKURSIVT KALLA
  # PÅ SIG SJÄLV NÄR EN ÄNDRIGNG GÖRS?

  # ADD SIN AND SUCH!
  def eval({t, x}) do {t, x} end

  #def simpl(x) do same_coeff(remove_zeros(eval(x))) end

  def mul(l, r) do {:mul, l, r} end

  def divv(x, y) do {:div, x, y} end


  def add(x, {:num, 0}) do x end

  def add(l, r) do {:add, l, r} end

  def pow(x, n) do {:pow, x, n} end

  def simplify({type, x, y}) do
    case type do
      :add -> simplify_add(simplify(x), simplify(y))
      :mul -> simplify_mul(simplify(x), simplify(y))
      :pow -> simplify_pow(simplify(x), simplify(y))
      :div -> simplify_div(simplify(x), simplify(y))
      true -> {type, x, y}
    end
  end

  def simplify({type, x}) do
    case type do
      :num -> {type, x}
      :var -> {type, x}
      :sin -> {type, simplify(x)}
      :cos -> {type, simplify(x)}
      :ln  -> simplify_ln(simplify(x))
      type -> {type, x}
    end
  end

  def simplify_add(x, y) do
    case {x, y} do
      {{:num, 0}, y1} -> y1
      {x1, {:num, 0}} -> x1
      {{:num, a}, {:num, b}} -> {:num, a+b}

      # a + (:x + b) = :x + (a+b)
      {{:add, x1, {:num, n1}}, {:num, n2}} -> simplify_add(x1, {:num, n1+n2})
      {{:num, n2}, {:add, x1, {:num, n1}}} -> simplify_add(x1, {:num, n1+n2})

      {{:add, {:num, n1}, x1}, {:num, n2}} -> simplify_add(x1, {:num, n1+n2})
      {{:num, n2}, {:add, {:num, n1}, x1}} -> simplify_add(x1, {:num, n1+n2})

      {x, y} -> {:add, x, y}
    end
  end

  def simplify_mul(x, y) do
    case {x, y} do
      # 0*x
      {{:num, 0}, _} -> {:num, 0}
      {_, {:num, 0}} -> {:num, 0}

      # 1*x
      {x1, {:num, 1}} -> x1
      {{:num, 1}, y1} -> y1

      # x * x^a = x^(a+1)
      {a, {:pow, a, n}} -> {:pow, x, simplify_add({:num, 1}, n)}

      {{:num, a}, {:num, b}} -> {:num, a*b}
      {x, y} -> {:mul, x, y}
    end
  end

  def simplify_div(x, y) do
    case {x, y} do
      {x1, {:num, 1}} -> x1
      {{:num, n1}, {:num, n2}} -> {:num, n1/n2}
      # Kan lägga till att ta bort multiplar av x exempelvis
      {x, y} -> {:div, x, y}
    end
  end

  def simplify_pow(x, y) do
    case {x, y} do
      {{:num, 0}, _} -> {:num, 0}
      {{:num, 1}, _} -> {:num, 1}
      {_, {:num, 0}} -> {:num, 1}
      {y1, {:num, 1}} -> y1
      {{:num, n1}, {:num, n2}} -> {:num, :math.pow(n1, n2)}
      {x, y} -> {:pow, x, y}
    end
  end

  def simplify_ln(x) do
    case x do
      {:num, n} -> {:num, :math.log(n)}
      {:pow, x1, y1} -> {:mul, y1, {:ln, x1}}
      x -> {:ln, x}
    end
  end


  # CHAIN RULE
  def chain(f_prim, g, v) do
    mul(f_prim, deriv(g, v))
  end

  # RULES
  def deriv({:num, _}, _) do {:num, 0} end
  def deriv({:var, v}, v) do {:num, 1} end
  def deriv({:var, _}, _) do {:num, 0} end # Är det 0?
  def deriv({:add, l, r}, v) do
    add(deriv(l, v), deriv(r, v))
  end
  def deriv({:mul, f, g}, v) do
    add(mul(deriv(f, v), g), mul(f, deriv(g, v)))
  end

  # f(x) = g(x)^n
  def deriv({:pow, g, n}, v) do
    chain(mul(n, pow(g, add(n, {:num, -1}))), g, v)
  end

  # ln(g(x))
  def deriv({:ln, g}, v) do
    chain(divv({:num, 1}, g), g, v)
  end

  # f/g
  def deriv({:div, f, g}, v) do
    divv(add(mul(deriv(f, v), g), mul({:num, -1}, mul(deriv(g, v), f))),pow(g, {:num, 2}))
  end

  # Sin med kedjeregel
  # sin(g(x)) = f(x)
  def deriv({:sin, g}, v) do
    #mul({:cos, f}, deriv(f, v))
    chain({:cos, g}, g, v)
  end

  def deriv({:sqrt, g}, v) do
    deriv({:pow, g, {:div, {:num, 1}, {:num, 2}}}, v)
  end

  def pprint(expr) do
    IO.puts(pprint_(expr))
  end

  def pprint_(expr) do
    case expr do
       {:add, x, y} -> "(#{pprint_(x)} + #{pprint_(y)})"
       {:mul, x, y} -> "(#{pprint_(x)} * #{pprint_(y)})"
       {:div, x, y} -> "(#{pprint_(x)} / #{pprint_(y)})"
       {:pow, x, y} -> "(#{pprint_(x)} ^ #{pprint_(y)})"
       {:var, x} -> "#{x}"
       {:num, x} -> "#{x}"
       {:sin, x} -> "sin(#{pprint_(x)})"
       {:cos, x} -> "cos(#{pprint_(x)})"
       {:ln, x} -> "ln(#{pprint_(x)})"
       x -> "#{x}"
    end
  end

end



#
