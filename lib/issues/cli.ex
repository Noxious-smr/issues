defmodule Issues.CLI do
  @default_count 4
  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions that end up generating a table
  of the last _n_ issues in a github project
  """
  import Issues.TableFormatter, only: [print_table_for_columns: 2]

  def main(argv) do
    argv
    |> parse_args()
    |> process
    # |> IO.inspect()
  end

  @doc """
  `argv` can be -h or --help, which returns :help.
  otherwise it is a github username, project name, and(optionally)
  the number of entries to format.

  Return a tuple of `{user, project, count}`, or `:help` if help was given.
  """

  # def parse_args(argv) do
  #   parse = OptionParser.parse(argv, switches: [help: :boolean, man: :string], aliases: [h: :help, m: :man])

  #   case parse do
  #     {[help: true], _, _} -> :help
  #     {[man: arg], _, _} -> arg
  #     {_, [user, project, count], _} -> {user, project, String.to_integer(count)}
  #     {_, [user, project], _} -> {user, project, @default_count}
  #     _ -> :help
  #   end
  # end

  # refactoring parse_args(argv)
  def parse_args(argv) do
    OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])
    |> elem(1)
    |> args_to_internal_representation()
  end

  defp args_to_internal_representation([user, project, count]) do
    {user, project, String.to_integer(count)}
  end

  defp args_to_internal_representation([user, project]) do
    {user, project, @default_count}
  end

  defp args_to_internal_representation(_) do
    :help
  end

  defp process(:help) do
    IO.puts """
    usage: issues <user> <project> [count | #{@default_count}]
    """
    System.halt(0)
  end

  defp process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response()
    |> sort_into_descending_order()
    |> Enum.take(count)
    |> Enum.reverse()
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  defp decode_response({:ok, body}), do: body

  defp decode_response({:error, error}) do
    IO.puts("Error fetching from github: #{error["message"]}")
    System.halt(2)
  end

  def sort_into_descending_order(list_of_issues) do
    list_of_issues
    |> Enum.sort(fn i1, i2 -> i1["created_at"] >= i2["created_at"] end)
  end

end
