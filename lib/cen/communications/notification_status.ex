# lib/cen/communications/notification_status.ex
defmodule Cen.Communications.NotificationStatus do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "notification_statuses" do
    belongs_to :notification, Cen.Communications.Notification
    belongs_to :user, Cen.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:notification_id, :user_id])
    |> validate_required([:notification_id, :user_id])
    |> unique_constraint([:notification_id, :user_id])
  end
end
