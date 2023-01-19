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

  def same_coeff({t, l, r}) do
    case {t, l, r} do
      #a+a = 2a
      {:add, a, a} -> {:mul, {:num, 2}, a}

      # a*a = a^2
      {:mul, a, a} -> same_coeff({:pow, a, {:num, 2}})

      {:pow, {:pow, a, p1}, p2} -> same_coeff({:pow, a, mul(p1, p2)})

      # ax+bx = (a+b)x
      {:add, {:mul, a, x}, {:mul, b, x}} -> {:mul, eval({:add, a, b}), x}
      {:add, {:mul, a, x}, {:mul, x, b}} -> {:mul, eval({:add, a, b}), x}
      {:add, {:mul, x, a}, {:mul, b, x}} -> {:mul, eval({:add, a, b}), x}
      {:add, {:mul, x, a}, {:mul, x, b}} -> {:mul, eval({:add, a, b}), x}


      {:add, {:mul, a, x}, {:mul, b, x}} -> {:mul, eval({:add, a, b}), x}
      {:add, {:mul, a, x}, {:mul, x, b}} -> {:mul, eval({:add, a, b}), x}
      {:add, {:mul, x, a}, {:mul, b, x}} -> {:mul, eval({:add, a, b}), x}
      {:add, {:mul, x, a}, {:mul, x, b}} -> {:mul, eval({:add, a, b}), x}

      #Recursive step
      {a, b, c} -> cond do
        same_coeff(b) != b or same_coeff(c) != c -> # if updated
        same_coeff({a, same_coeff(b), same_coeff(c)})
        true ->
          {a, same_coeff(b), same_coeff(c)}
        end
    end
  end

  # OBS! lös detta problemet för de två andra också!
  def same_coeff({a, b}) do {a, same_coeff(b)} end
  def same_coeff(a) do a end

  def remove_zeros({t, l, r}) do
    case {t, l, r} do
      {:add, {:num, 0}, r} -> r
      {:add, l, {:num, 0}} -> l
      {:mul, {:num, 0}, _} -> {:num, 0}
      {:mul, _, {:num, 0}} -> {:num, 0}
      {:mul, {:num, 1}, r} -> r
      {:mul, l, {:num, 1}} -> l
      {:div, {:num, 0}, _} -> {:num, 0}
      {:div, _, {:num, 0}} -> {:num, 0}
      {:pow, _, {:num, 0}} -> {:num, 1}

      #Recursive step
      {a, b, c} -> cond do
        remove_zeros(b) != b or remove_zeros(c) != c -> # if updated
        remove_zeros({a, remove_zeros(b), remove_zeros(c)})
        true ->
          {a, remove_zeros(b), remove_zeros(c)}
      end

    end
  end

  def remove_zeros({t, l}) do {t, l} end

  def eval({t, l, r}) do
    case {t, l, r} do
      #Evaluation
      {:add, {:num, v1}, {:num, v2}} -> add({:num, v1}, {:num, v2})
      {:mul, {:num, v1}, {:num, v2}} -> mul({:num, v1}, {:num, v2})
      {:pow, {:num, v1}, {:num, v2}} -> pow({:num, v1}, {:num, v2})
      {:div, {:num, v1}, {:num, v2}} -> divv({:num, v1}, {:num, v2})
      {a, b, c} -> cond do
        eval(b) != b or eval(c) != c -> # if updated
          eval({a, eval(b), eval(c)})
        true -> # else
          {a, eval(b), eval(c)}
      end
    end
  end

  # ADD SIN AND SUCH!
  def eval({t, x}) do {t, x} end

  def simpl(x) do same_coeff(remove_zeros(eval(x))) end


  def mul({:num, 1}, x) do x end
  def mul(x, {:num, 1}) do x end
#
  def mul({:num, 0}, _) do {:num, 0} end
  def mul(_, {:num, 0}) do {:num, 0} end
#
  def mul({:num, l}, {:num, r}) do {:num, l*r} end
  def mul(l, r) do {:mul, l, r} end
#
  def divv({:num, l}, {:num, r}) do {:num, l/r} end
  def divv(x, y) do {:div, x, y} end
#
  def add({:num, 0}, x) do x end
  def add(x, {:num, 0}) do x end
#
  def add({:num, l}, {:num, r}) do {:num, l+r} end
  def add(l, r) do {:add, l, r} end

  def pow({:num, x}, {:num, n}) do {:num, :math.pow(x, n)} end
  def pow(x, {:num, 1}) do x end
  def pow(_, {:num, 0}) do {:num, 0} end
  def pow(x, n) do {:pow, x, n} end

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
  def deriv({:pow, f, n}, v) do
    chain(mul(n, pow(f, add(n, {:num, -1}))), f, v)
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

end

#
