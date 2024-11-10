defmodule Cen.Communications.Message do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "messages" do
    field :text, :string

    belongs_to :user, Cen.Accounts.User
    belongs_to :interaction, Cen.Communications.Interaction

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
