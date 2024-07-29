defmodule CenWeb.UserControllerTest do
  use CenWeb.ConnCase, async: true

  import Cen.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "DELETE /users" do
    test "deletes the user and logs out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Account deleted successfully."

      # Can't create session for deleted user
      assert_raise Ecto.ConstraintError, fn ->
        log_in_user(conn, user)
      end
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Account deleted successfully."
    end
  end
end
