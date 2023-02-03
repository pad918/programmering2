defmodule Eval do

  #@type literal() :: {:num, n}
  #  | {:var, a} | {:q, n, m}

  #@type expr() :: {:add, expr(), expr()} |
  #  {:sub, expr(), expr()} |
  #  {:mul, expr(), expr()} |
  #  {:div, expr(), expr()} |
  #  literal()



    # Function to create a new environment from a given set of bindings.
    def new_env([{k, v}|t]) do
      EnvTree.add(new_env(t), k, v)
    end

    def new_env([]) do
      nil
    end

    # Function to find binding of variable in binding.
    def lookup(env, key) do
      EnvTree.lookup(env, key)
    end

    ####### EVALUATION FUNCTIONS #######

    def simpl({:q, a, b}) do
      g_div = gcd(a, b)
      t = div(a, g_div)
      n = div(b, g_div)
      if(n==1) do
        t
      else
        {:q, t, n}
      end

    end

    def simpl(l) do l end

    def gcd(a1, a2) do
      a1 = abs(a1)
      a2 = abs(a2)
      max = max(a1, a2)
      min = min(a1, a2)
      if(min==0 or max==min) do
        max
      else
        f = div(max, min)
        gcd(max-min*f, min)
      end
    end

    # OBS DETTA ÄR ETT MYCKET
    # LÅNGSAMT SÄTT ATT GÖRA DET PÅ
    def old_gcd(a1, a2) do
      c = common_divider(a1, a2, 2)
      if(c>1) do
        c*old_gcd(div(a1,c), div(a2,c))
      else
        1
      end
    end

    def common_divider(a1, a2, num) do
      if(num>a1 or num>a2) do
        1
      else
        if(rem(a1, num)==0 and rem(a2, num) == 0)
        do
          num
        else
          common_divider(a1, a2, num+1)
        end
      end
    end

    def add(a1, a2) do
      case {a1, a2} do
        {{:q, t1, n1}, {:q, t2, n2}}  -> {:q, t1*n2+t2*n1, n1*n2}
        {{:q, t1, n1}, a2}            -> {:q, t1+a2*n1, n1}
        {a1, {:q, t1, n1}}            -> {:q, t1+a1*n1, n1}
        {a1, a2}                      -> a1+a2
      end
    end

    def sub(a1, a2) do
      case {a1, a2} do
        {{:q, t1, n1}, {:q, t2, n2}}  -> {:q, t1*n2-t2*n1, n1*n2}
        {{:q, t1, n1}, a2}            -> {:q, t1-a2*n1, n1}
        {a1, {:q, t1, n1}}            -> {:q, a1*n1-t1, n1}
        {a1, a2}                      -> a1-a2
      end
    end

    def mul(a1, a2) do
      case {a1, a2} do
        {{:q, t1, n1}, {:q, t2, n2}}  -> {:q, t1*t2, n1*n2}
        {{:q, t1, n1}, a2}            -> {:q, t1*a2, n1}
        {a1, {:q, t1, n1}}            -> {:q, a1*t1, n1}
        {a1, a2}                      -> a1*a2
      end
    end

    def div_(a1, a2) do
      case {a1, a2} do
        {{:q, t1, n1}, {:q, t2, n2}}  -> {:q, t1*n2, t2*n1}
        {{:q, t1, n1}, a2}            -> {:q, t1, n1*a1}
        {a1, {:q, t1, n1}}            -> {:q, a1*n1, t1}
        {a1, a2}                      -> {:q, a1, a2}
      end
    end

    def eval({:num, n}, env) do n end
    def eval({:var, x}, env) do lookup(env, x) end
    def eval({:add, a1, a2}, env) do
      simpl(add(eval(a1, env), eval(a2, env)))
    end
    def eval({:sub, a1, a2}, env) do
      simpl(sub(eval(a1, env), eval(a2, env)))
    end
    def eval({:mul, a1, a2}, env) do
      simpl(mul(eval(a1, env), eval(a2, env)))
    end
    def eval({:div, a1, a2}, env) do
      simpl(div_(eval(a1, env), eval(a2, env)))
    end
    def eval({:q, l, r}, env) do {:q, l, r} end

    #Exempel
    #{:add, {:add, {:mul, {:num, 2}, {:var, :x}}, {:num, 3}}, {:q, 1, 2}}

Eval.eval(
{:div,
    {:div,
        {:div, {:var, x}, {:var, :y}},
        {:div, {:var, y}, {:var, z}}
    },
    {:div, {:q, 17, 13}, {:q, 77, 23}}
},
Eval.new_env([{:x, 1}, {:y, 10}, {:z, 100}]))

end
