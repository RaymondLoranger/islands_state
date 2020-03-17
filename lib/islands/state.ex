# ┌───────────────────────────────────────────────────────────────────────┐
# │ Inspired by the book "Functional Web Development" by Lance Halvorsen. │
# └───────────────────────────────────────────────────────────────────────┘
defmodule Islands.State do
  @behaviour Access

  use PersistConfig

  @book_ref Application.get_env(@app, :book_ref)

  @moduledoc """
  Implements a `state machine` for the _Game of Islands_.
  \n##### #{@book_ref}
  """

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

  @type game_state ::
          :initialized
          | :players_set
          | :player1_turn
          | :player2_turn
          | :game_over
  @type player_state :: :islands_not_set | :islands_set
  @type request ::
          :add_player
          | {:position_island, PlayerID.t()}
          | {:position_all_islands, PlayerID.t()}
          | {:set_islands, PlayerID.t()}
          | {:guess_coord, PlayerID.t()}
          | {:win_check, :no_win | :win}
          | :stop
  @type t :: %State{
          game_state: game_state,
          player1_state: player_state,
          player2_state: player_state
        }
  # Access behaviour
  defdelegate fetch(state, key), to: Map
  defdelegate get(state, key, default), to: Map
  defdelegate get_and_update(state, key, fun), to: Map
  defdelegate pop(state, key), to: Map

  @spec new :: t
  def new, do: %State{}

  @spec check(t, request) :: {:ok, t} | :error
  def check(
        %State{game_state: :initialized} = state,
        {:position_all_islands, :player1}
      ),
      do: {:ok, state}

  def check(%State{game_state: :initialized} = state, :add_player),
    do: {:ok, put_in(state.game_state, :players_set)}

  def check(%State{game_state: :players_set} = state, {action, player_id})
      when action in @position_actions and player_id in @player_ids do
    case state[state_key(player_id)] do
      :islands_not_set -> {:ok, state}
      :islands_set -> :error
    end
  end

  def check(%State{game_state: :players_set} = state, {:set_islands, player_id})
      when player_id in @player_ids do
    state = put_in(state[state_key(player_id)], :islands_set)

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

  def check(%State{game_state: player_turn} = state, {:win_check, :no_win})
      when player_turn in @player_turns,
      do: {:ok, state}

  def check(%State{game_state: player_turn} = state, {:win_check, :win})
      when player_turn in @player_turns,
      do: {:ok, put_in(state.game_state, :game_over)}

  def check(%State{game_state: player_turn} = state, :stop)
      when player_turn in @player_turns,
      do: {:ok, put_in(state.game_state, :game_over)}

  def check(_state, _request), do: :error

  ## Private functions

  @spec both_players_islands_set?(t) :: boolean
  defp both_players_islands_set?(state) do
    state.player1_state == :islands_set and state.player2_state == :islands_set
  end

  @spec state_key(PlayerID.t()) :: atom
  defp state_key(player_id), do: :"#{player_id}_state"
end
