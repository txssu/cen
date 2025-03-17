# lib/cen/communications/notification.ex
defmodule Cen.Communications.Notification do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Cen.Communications.Enums

  @type t :: %__MODULE__{}

  schema "notifications" do
    field :message, :string
    field :title, :string
    field :is_broadcast, :boolean, default: false
    field :type, Ecto.Enum, values: Enums.notification_types()
    field :is_read, :boolean, virtual: true

    belongs_to :user, Cen.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :message, :type, :is_broadcast, :user_id])
    |> validate_required([:title, :message, :type, :is_broadcast])
    |> validate_user_id()
  end

  defp validate_user_id(changeset) do
    user_id = get_field(changeset, :user_id)
    broadcast? = get_field(changeset, :is_broadcast)

    if broadcast? do
      if user_id do
        add_error(changeset, :user_id, "не должен быть указан для массовых уведомлений")
      else
        changeset
      end
    else
      changeset
      |> validate_required(:user_id)
      |> foreign_key_constraint(:user_id, name: "notifications_user_id_fkey")
    end
  end
end
