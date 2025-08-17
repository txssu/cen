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
    field :archived_at, :utc_datetime

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

  @doc """
  Archives the interaction by setting `archived_at`.
  """
  @spec archive_changeset(t() | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def archive_changeset(interaction) do
    now = DateTime.utc_now(:second)
    change(interaction, archived_at: now)
  end
end
