require "application_system_test_case"

class ConnectionsFormTest < ApplicationSystemTestCase
  setup do
    @user = users(:owner)
    sign_in @user
  end

  test "new buttons have btn-success class" do
    visit new_connection_path(locale: :en)

    # Find the source "New" button and verify it has btn-success class
    source_new_button = find("a[href*='sources'][href*='new_modal']", wait: 5)
    assert source_new_button[:class].include?("btn-success"), "Source New button should have btn-success class"

    # Find the destination "New" button and verify it has btn-success class
    destination_new_button = find("a[href*='destinations'][href*='new_modal']")
    assert destination_new_button[:class].include?("btn-success"), "Destination New button should have btn-success class"
  end

  test "edit buttons have btn-warning class" do
    visit new_connection_path(locale: :en)

    # Find the source "Edit" button and verify it has btn-warning class
    source_edit_button = find("a[data-connection-form-target='sourceEditLink']", visible: :all, wait: 5)
    assert source_edit_button[:class].include?("btn-warning"), "Source Edit button should have btn-warning class"

    # Find the destination "Edit" button and verify it has btn-warning class
    destination_edit_button = find("a[data-connection-form-target='destinationEditLink']", visible: :all)
    assert destination_edit_button[:class].include?("btn-warning"), "Destination Edit button should have btn-warning class"
  end

  test "buttons use btn-outline style" do
    visit new_connection_path(locale: :en)

    # Verify all buttons use btn-outline
    source_new_button = find("a[href*='sources'][href*='new_modal']", wait: 5)
    assert source_new_button[:class].include?("btn-outline"), "Source New button should have btn-outline class"

    destination_new_button = find("a[href*='destinations'][href*='new_modal']")
    assert destination_new_button[:class].include?("btn-outline"), "Destination New button should have btn-outline class"

    source_edit_button = find("a[data-connection-form-target='sourceEditLink']", visible: :all)
    assert source_edit_button[:class].include?("btn-outline"), "Source Edit button should have btn-outline class"

    destination_edit_button = find("a[data-connection-form-target='destinationEditLink']", visible: :all)
    assert destination_edit_button[:class].include?("btn-outline"), "Destination Edit button should have btn-outline class"
  end

  private

  def sign_in(user)
    visit new_user_session_path(locale: :en)
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Login"
    assert_no_current_path new_user_session_path(locale: :en), wait: 5
  end
end
