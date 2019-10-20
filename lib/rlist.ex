defmodule Rlist do
  @moduledoc """
  Documentation for Rlist.
  """
  defmodule Tree do
    @type tree :: {:parent, parent} | {:leaf, any}
    @type parent :: {any, tree, tree}

    @spec new(any) :: tree
    def new(item) do
      {:leaf, item}
    end

    @spec parent(any, tree, tree) :: tree
    def parent(item, left, right) do
      {:parent, {item, left, right}}
    end

    @spec balanced(tree) :: boolean
    def balanced(t) do
      case do_balanced(t) do
        {:ok, _} -> true
        :error -> false
      end
    end

    @spec do_balanced(tree) :: {:ok, non_neg_integer} | :error
    def do_balanced(t) do
      case t do
        {:leaf, _} ->
          {:ok, 1}

        {:parent, {_, l, r}} ->
          case do_balanced(l) do
            {:ok, size_l} ->
              case do_balanced(r) do
                {:ok, size_r} ->
                  if size_l == size_r do
                    {:ok, size_l + 1}
                  else
                    :error
                  end

                :error ->
                  :error
              end

            :error ->
              :error
          end
      end
    end

    @spec index(tree, size :: non_neg_integer, index :: non_neg_integer) :: any
    def index(tree, size, index) do
      case tree do
        {:leaf, item} when index == 0 ->
          item

        {:parent, {item, left, right}} ->
          if index == 0 do
            item
          else
            subtree_size = div(size - 1, 2)

            if index <= subtree_size do
              index(left, subtree_size, index - 1)
            else
              index(right, subtree_size, index - subtree_size - 1)
            end
          end
      end
    end

    @spec modify(
            tree,
            size :: non_neg_integer,
            index :: non_neg_integer,
            update_fn :: (any -> any)
          ) ::
            tree
    def modify(tree, size, index, update_fn) do
      case tree do
        {:leaf, item} when index == 0 ->
          {:leaf, update_fn.(item)}

        {:parent, {item, left, right}} ->
          if index == 0 do
            {:parent, {update_fn.(item), left, right}}
          else
            subtree_size = div(size - 1, 2)

            if index <= subtree_size do
              {:parent, {item, modify(left, subtree_size, index - 1, update_fn), right}}
            else
              {:parent,
               {item, left, modify(right, subtree_size, index - subtree_size - 1, update_fn)}}
            end
          end
      end
    end

    @spec map(tree, (any -> any)) :: tree
    def map(tree, f) do
      case tree do
        {:leaf, item} ->
          {:leaf, f.(item)}

        {:parent, {item, left, right}} ->
          {:parent, {f.(item), map(left, f), map(right, f)}}
      end
    end

    @spec reduce(tree, any, (any, any -> any)) :: any
    def reduce(tree, acc, fun) do
      case tree do
        {:leaf, item} ->
          fun.(item, acc)

        {:parent, {item, left, right}} ->
          new_acc = fun.(item, acc)
          new_acc = reduce(left, new_acc, fun)
          reduce(right, new_acc, fun)
      end
    end

    @spec tolist_reversed(tree, [any]) :: [any]
    def tolist_reversed(tree, acc) do
      case tree do
        {:leaf, item} ->
          [item | acc]

        {:parent, {item, left, right}} ->
          tolist_reversed(right, tolist_reversed(left, [item | acc]))
      end
    end
  end

  @type element :: {non_neg_integer, Tree.tree()}
  @type rlist :: [element]

  @spec empty() :: rlist
  def empty do
    []
  end

  @spec singleton(any) :: rlist
  def singleton(x) do
    [{1, Tree.new(x)}]
  end

  @spec size(rlist) :: non_neg_integer
  def size(rlist) do
    size(0, rlist)
  end

  @spec size(non_neg_integer, rlist) :: non_neg_integer
  def size(acc, rlist) do
    case rlist do
      [] -> acc
      [{n, _} | rest] -> size(acc + n, rest)
    end
  end

  @spec naive_fromlist([any]) :: rlist
  def naive_fromlist(list) do
    Enum.reduce(Enum.reverse(list), empty(), &cons/2)
  end

  @spec naive_tolist(rlist) :: [any]
  def naive_tolist(rlist) do
    naive_tolist(rlist, [])
  end

  @spec naive_tolist(rlist, acc :: [any]) :: [any]
  def naive_tolist(rlist, acc) do
    case uncons(rlist) do
      {:ok, x, xs} -> naive_tolist(xs, [x | acc])
      :error -> Enum.reverse(acc)
    end
  end

  @spec index(rlist, non_neg_integer) :: {:ok, any} | :error
  def index(rlist, index) do
    case rlist do
      [] ->
        :error

      [{t_size, t} | rest] ->
        if index < t_size do
          Tree.index(t, t_size, index)
        else
          index(rest, index - t_size)
        end
    end
  end

  @spec modify(rlist, index :: non_neg_integer, (any -> any)) :: {:ok, rlist} | :error
  def modify(rlist, index, modify_fn) do
    case rlist do
      [] ->
        :error

      [{t_size, t} | rest] ->
        if index < t_size do
          {:ok, [{t_size, Tree.modify(t, t_size, index, modify_fn)} | rest]}
        else
          case modify(rest, index - t_size, modify_fn) do
            {:ok, new_tail} ->
              {:ok, [{t_size, t} | new_tail]}

            :error ->
              :error
          end
        end
    end
  end

  @spec cons(any, rlist) :: rlist
  def cons(item, rlist) do
    case rlist do
      [{x_size, x_tree}, {y_size, y_tree} | rest]
      when x_size == y_size ->
        [{2 * x_size + 1, Tree.parent(item, x_tree, y_tree)} | rest]

      _ ->
        [{1, Tree.new(item)} | rlist]
    end
  end

  @spec uncons(rlist) :: {:ok, any, rlist} | :error
  def uncons(rlist) do
    case rlist do
      [{1, {:leaf, item}} | rest] ->
        {:ok, item, rest}

      [{size, {:parent, {item, left, right}}} | rest] ->
        new_size = div(size - 1, 2)
        new_list = [{new_size, left}, {new_size, right} | rest]
        {:ok, item, new_list}

      [] ->
        :error
    end
  end

  @spec map(rlist, (any -> any)) :: rlist
  def map(rlist, f) do
    Enum.map(rlist, fn {t_size, t} -> {t_size, Tree.map(t, f)} end)
  end

  @spec reduce(rlist, any, (any, any -> any)) :: any
  def reduce(rlist, acc, fun) do
    Enum.reduce(rlist, acc, fn {_t_size, t}, new_acc -> Tree.reduce(t, new_acc, fun) end)
  end
end
