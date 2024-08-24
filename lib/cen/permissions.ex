defmodule Cen.Permissions do
  @moduledoc false
  alias Cen.Accounts.User
  alias Cen.Employers.Organization

  defmodule NoPermission do
    @moduledoc false
    defexception [:message, plug_status: 404]
  end

  @spec verify_has_permission!(term(), term(), atom()) :: :ok | no_return()
  def verify_has_permission!(subject, resource, action) do
    if has_permission?(subject, resource, action) do
      :ok
    else
      raise NoPermission, message: "Given subject doesn't have permission to #{action} resource"
    end
  end

  @spec has_permission?(term(), term(), atom()) :: boolean()
  def has_permission?(subject, resource, action)

  def has_permission?(%User{role: :admin}, _resource, _action), do: true

  def has_permission?(%User{role: :employer}, :organizations, :index), do: true
  def has_permission?(%User{role: :employer, id: author_id}, %Organization{user_id: author_id}, _action), do: true
  def has_permission?(%User{role: :employer}, %Organization{}, action) when action in ~w[create show]a, do: true
  def has_permission?(%User{role: :applicant}, %Organization{}, action) when action in ~w[show]a, do: true

  def has_permission?(_subject, _resource, _action), do: false
end
