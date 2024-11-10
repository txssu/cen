defmodule Cen.Communications.Interaction do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Cen.Communications.Message
  alias Cen.Publications.Resume
  alias Cen.Publications.Vacancy

  @type t :: %__MODULE__{}

  schema "interactions" do
    belongs_to :resume, Resume
    belongs_to :vacancy, Vacancy

    field :initiator, Ecto.Enum, values: [:resume, :vacancy]
    field :status, Ecto.Enum, values: [:pending, :accepted, :rejected], default: :pending

    has_many :messages, Message

    field :latest_message, :map, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(interaction, attrs) do
    interaction
    |> cast(attrs, [])
    |> unique_constraint([:resume_id, :vacancy_id, :initiator])
  end
end
