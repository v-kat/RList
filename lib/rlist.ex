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
        {:ok, nil, nil}
    end
  end
end
