defmodule Cen.AccountsTest do
  use Cen.DataCase, async: true

  import Cen.AccountsFixtures

  alias Cen.Accounts
  alias Cen.Accounts.User
  alias Cen.Accounts.UserToken

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: [
                 "should be at least one digit",
                 "should be at least one upper case character",
                 "should be at least 12 character(s)"
               ]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, invalid_changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(invalid_changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()

      {:ok, user} =
        [email: email]
        |> valid_user_attributes()
        |> Accounts.register_user()

      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset for `applicant` role" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{role: :applicant})
      assert changeset.required == [:phone_number, :fullname, :birthdate, :privacy_consent, :role, :password, :email]
    end

    test "returns a changeset for `employer` role" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{role: :employer})
      assert changeset.required == [:phone_number, :fullname, :privacy_consent, :role, :password, :email]
    end

    test "allows fields to be set" do
      attrs = valid_user_attributes(role: :employer)

      changeset =
        Accounts.change_user_registration(%User{}, attrs)

      assert changeset.valid?

      assert get_change(changeset, :phone_number) == attrs.phone_number
      assert get_change(changeset, :fullname) == attrs.fullname
      assert get_change(changeset, :role) == attrs.role
      assert get_change(changeset, :birthdate) == attrs.birthdate
      assert get_change(changeset, :password) == attrs.password
      assert get_change(changeset, :email) == attrs.email

      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = user_fixture()
      password = valid_user_password()

      {:error, changeset} = Accounts.apply_user_email(user, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_user_email(user, valid_user_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => "NewValidPassword123"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "NewValidPassword123"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "should be at least one digit",
                 "should be at least one upper case character",
                 "should be at least 12 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: valid_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "NewValidPassword123"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "NewValidPassword123")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _session_token = Accounts.generate_user_session_token(user)

      {:ok, _user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "NewValidPassword123"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/1" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Accounts.confirm_user(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Accounts.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "should be at least one digit",
                 "should be at least one upper case character",
                 "should be at least 12 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "NewValidPassword123"})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "NewValidPassword123")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _session_token = Accounts.generate_user_session_token(user)
      {:ok, _user} = Accounts.reset_user_password(user, %{password: "NewValidPassword123"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "soft_delete_user/1" do
    test "soft deletes user by setting deleted_at" do
      user = user_fixture()
      assert {:ok, soft_deleted_user} = Accounts.soft_delete_user(user)
      assert soft_deleted_user.deleted_at
      refute is_nil(soft_deleted_user.deleted_at)
    end

    test "soft deleted user is not returned by get_user_by_email/1" do
      user = user_fixture()
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user)
      assert nil == Accounts.get_user_by_email(user.email)
    end

    test "soft deleted user is not returned by get_user_by_email_and_password/2" do
      user = user_fixture()
      password = valid_user_password()

      # User exists before soft delete
      assert %User{} = Accounts.get_user_by_email_and_password(user.email, password)

      # Soft delete the user
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user)

      # User should not be found after soft delete
      refute Accounts.get_user_by_email_and_password(user.email, password)
    end

    test "soft deleted user is not returned by list_users/0" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Both users should be in the list initially
      users = Accounts.list_users()
      user_ids = Enum.map(users, & &1.id)
      assert user1.id in user_ids
      assert user2.id in user_ids

      # Soft delete one user
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user1)

      # Only non-deleted user should be in the list
      users_after_delete = Accounts.list_users()
      user_ids_after_delete = Enum.map(users_after_delete, & &1.id)
      refute user1.id in user_ids_after_delete
      assert user2.id in user_ids_after_delete
    end

    test "soft delete removes all user sessions" do
      user = user_fixture()
      session_token = Accounts.generate_user_session_token(user)

      # Session token should exist
      assert Accounts.get_user_by_session_token(session_token)

      # Soft delete user
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user)

      # Session token should be removed
      refute Accounts.get_user_by_session_token(session_token)
    end

    test "get_user!/1 still returns soft deleted user" do
      user = user_fixture()
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user)

      # get_user!/1 should still work for soft deleted users (for admin purposes)
      assert %User{} = Accounts.get_user!(user.id)
    end
  end

  describe "User query scopes" do
    test "not_deleted/1 excludes soft deleted users" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Soft delete one user
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user1)

      # not_deleted scope should only return non-deleted users
      non_deleted_users =
        User
        |> User.not_deleted()
        |> Repo.all()

      user_ids = Enum.map(non_deleted_users, & &1.id)
      refute user1.id in user_ids
      assert user2.id in user_ids
    end

    test "deleted_only/1 includes only soft deleted users" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Soft delete one user
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user1)

      # deleted_only scope should only return deleted users
      deleted_users =
        User
        |> User.deleted_only()
        |> Repo.all()

      user_ids = Enum.map(deleted_users, & &1.id)
      assert user1.id in user_ids
      refute user2.id in user_ids
    end
  end

  describe "Email uniqueness with soft delete" do
    test "allows registration with same email after user is soft deleted" do
      # Create and soft delete a user
      email = unique_user_email()
      user1 = user_fixture(%{email: email})
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user1)

      # Should be able to create a new user with the same email
      attrs = valid_user_attributes(%{email: email})
      assert {:ok, user2} = Accounts.register_user(attrs)
      assert user2.email == email
      assert user2.id != user1.id
    end

    test "prevents registration with same email when user is not deleted" do
      # Create a user
      email = unique_user_email()
      _user1 = user_fixture(%{email: email})

      # Should not be able to create another user with the same email
      attrs = valid_user_attributes(%{email: email})
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end

    test "soft deleted users can have duplicate emails between them" do
      # Create two users with different emails
      email = unique_user_email()
      user1 = user_fixture(%{email: email})
      user2 = user_fixture()

      # Soft delete both users
      assert {:ok, _deleted_user1} = Accounts.soft_delete_user(user1)
      assert {:ok, _deleted_user2} = Accounts.soft_delete_user(user2)

      # Update second user to have same email as first (this simulates the scenario)
      # This should be allowed since both are deleted
      query = from(u in User, where: u.id == ^user2.id)
      Repo.update_all(query, set: [email: email])

      # Verify both deleted users have the same email
      deleted_users =
        User
        |> User.deleted_only()
        |> where([u], u.email == ^email)
        |> Repo.all()

      assert length(deleted_users) == 2
    end
  end

  describe "VK ID uniqueness with soft delete" do
    test "allows registration with same vk_id after user is soft deleted" do
      # Create and soft delete a user with VK ID
      vk_id = 12_345
      user1 = user_fixture()

      # Update user1 to have a vk_id (simulating VK registration)
      query = from(u in User, where: u.id == ^user1.id)
      Repo.update_all(query, set: [vk_id: vk_id])

      # Soft delete the user
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user1)

      # Create changeset for new user with same vk_id - should be valid
      changeset =
        User.vk_id_changeset(%User{}, %{
          "email" => unique_user_email(),
          "fullname" => valid_user_fullname(),
          "phone_number" => valid_user_phone_number(),
          "role" => "applicant",
          "birthdate" => valid_user_birthdate(),
          "vk_id" => vk_id
        })

      assert changeset.valid?
      assert {:ok, user2} = Repo.insert(changeset)
      assert user2.vk_id == vk_id
      assert user2.id != user1.id
    end

    test "prevents registration with same vk_id when user is not deleted" do
      # Create a user with VK ID
      vk_id = 54_321
      user1 = user_fixture()

      query = from(u in User, where: u.id == ^user1.id)
      Repo.update_all(query, set: [vk_id: vk_id])

      # Try to create another user with the same vk_id - should fail
      changeset =
        User.vk_id_changeset(%User{}, %{
          "email" => unique_user_email(),
          "fullname" => valid_user_fullname(),
          "phone_number" => valid_user_phone_number(),
          "role" => "applicant",
          "birthdate" => valid_user_birthdate(),
          "vk_id" => vk_id
        })

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{vk_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "get_user_by_vk_id returns nil for soft deleted users" do
      # Create user with VK ID
      vk_id = 98_765
      user = user_fixture()

      query = from(u in User, where: u.id == ^user.id)
      Repo.update_all(query, set: [vk_id: vk_id])

      # Should find user before soft delete
      assert found_user = Accounts.get_user_by_vk_id(vk_id)
      assert found_user.id == user.id

      # Soft delete the user
      assert {:ok, _soft_deleted_user} = Accounts.soft_delete_user(user)

      # Should not find user after soft delete
      refute Accounts.get_user_by_vk_id(vk_id)
    end
  end
end
