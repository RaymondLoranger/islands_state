# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.State do
  @moduledoc """
  A state struct and functions for the _Game of Islands_.

  The state struct contains the fields `game_state`, `player1_state` and
  `player2_state` for implementing a state machine in the _Game of Islands_.

  ##### Based on the book [Functional Web Development](https://pragprog.com/titles/lhelph/functional-web-development-with-elixir-otp-and-phoenix/) by Lance Halvorsen.
  """

  @behaviour Access

  alias __MODULE__
  alias Islands.PlayerID

  @player_ids [:player1, :player2]
  @player_turns [:player1_turn, :player2_turn]
  @position_actions [:position_island, :position_all_islands]

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  defstruct game_state: :initialized,
            player1_state: :islands_not_set,
            player2_state: :islands_not_set

  @typedoc "State machine event"
  @type event ::
          :add_player
          | {:position_island, PlayerID.t()}
          | {:position_all_islands, PlayerID.t()}
          | {:set_islands, PlayerID.t()}
          | {:guess_coord, PlayerID.t()}
          | {:stop, PlayerID.t()}
          | {:win_check, :no_win | :win}
  @typedoc "Game state"
  @type game_state ::
          :initialized
          | :players_set
          | :player1_turn
          | :player2_turn
          | :game_over
  @typedoc "Player state"
  @type player_state :: :islands_not_set | :islands_set
  @typedoc "A state struct for the Game of Islands"
  @type t :: %State{
          game_state: game_state,
          player1_state: player_state,
          player2_state: player_state
        }

  # Access behaviour
  defdelegate fetch(state, key), to: Map
  defdelegate get_and_update(state, key, fun), to: Map
  defdelegate pop(state, key), to: Map

  @doc """
  Creates a new state struct.

  ## Examples

      iex> Islands.State.new()
      %Islands.State{
        game_state: :initialized,
        player1_state: :islands_not_set,
        player2_state: :islands_not_set
      }
  """
  @spec new :: t
  def new, do: %State{}

  @doc """
  Decides whether to permit the `state`/`event` combination. Also decides
  whether to transition to a new state. Returns `{:ok, new_state}` if the
  combination is permissible. Returns `:error` if it is not.
  """
  @spec check(t, event) :: {:ok, t} | :error
  def check(state, event)

  def check(%State{game_state: :initialized} = state, :add_player),
    do: {:ok, put_in(state.game_state, :players_set)}

  def check(%State{game_state: :players_set} = state, {action, player_id})
      when action in @position_actions and player_id in @player_ids do
    case state[player_state_key(player_id)] do
      :islands_not_set -> {:ok, state}
      :islands_set -> :error
    end
  end

  def check(%State{game_state: :players_set} = state, {:set_islands, player_id})
      when player_id in @player_ids do
    state = put_in(state[player_state_key(player_id)], :islands_set)

    if both_players_islands_set?(state),
      do: {:ok, put_in(state.game_state, :player1_turn)},
      else: {:ok, state}
  end

  def check(
        %State{game_state: :player1_turn} = state,
        {:guess_coord, :player1}
      ),
      do: {:ok, put_in(state.game_state, :player2_turn)}

  def check(
        %State{game_state: :player2_turn} = state,
        {:guess_coord, :player2}
      ),
      do: {:ok, put_in(state.game_state, :player1_turn)}

  def check(%State{game_state: :player1_turn} = state, {:stop, :player1}),
    do: {:ok, put_in(state.game_state, :game_over)}

  def check(%State{game_state: :player2_turn} = state, {:stop, :player2}),
    do: {:ok, put_in(state.game_state, :game_over)}

  def check(%State{game_state: player_turn} = state, {:win_check, :no_win})
      when player_turn in @player_turns,
      do: {:ok, state}

  def check(%State{game_state: player_turn} = state, {:win_check, :win})
      when player_turn in @player_turns,
      do: {:ok, put_in(state.game_state, :game_over)}

  # Catchall clause
  def check(_state, _event), do: :error

  ## Private functions

  @spec both_players_islands_set?(t) :: boolean
  defp both_players_islands_set?(state) do
    state.player1_state == :islands_set and state.player2_state == :islands_set
  end

  @spec player_state_key(PlayerID.t()) :: atom
  defp player_state_key(:player1), do: :player1_state
  defp player_state_key(:player2), do: :player2_state
end
