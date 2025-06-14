require "test_helper"

module Alto
  class TicketArchiveTest < ActiveSupport::TestCase
    def setup
      @user1 = users(:one)
      @status_set = alto_status_sets(:default)
      @board = alto_boards(:bugs)
    end

    test "should not be archived by default" do
      ticket = Ticket.create!(
        title: "Regular Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        field_values: {
          "severity" => "medium",
          "steps_to_reproduce" => "Test archive default steps"
        }
      )

      assert_not ticket.archived?
      assert_not ticket.locked? # Should not be locked if only regular
    end

    test "should be archived when archived flag is true" do
      ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        archived: true,
        field_values: {
          "severity" => "high",
          "steps_to_reproduce" => "Test archive flag steps"
        }
      )

      assert ticket.archived?
    end

    test "archived tickets should be locked" do
      ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        archived: true,
        field_values: {
          "severity" => "high",
          "steps_to_reproduce" => "Test archive locked steps"
        }
      )

      # Archived tickets should automatically be locked
      assert ticket.locked?
      assert_not ticket.can_be_voted_on?
      assert_not ticket.can_be_commented_on?
    end

    test "should filter active tickets" do
      active_ticket = Ticket.create!(
        title: "Active Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        field_values: {
          "severity" => "medium",
          "steps_to_reproduce" => "Test active ticket steps"
        }
      )

      archived_ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        archived: true,
        field_values: {
          "severity" => "high",
          "steps_to_reproduce" => "Test archived ticket steps"
        }
      )

      active_tickets = Ticket.active
      assert_includes active_tickets, active_ticket
      assert_not_includes active_tickets, archived_ticket
    end

    test "should filter archived tickets" do
      active_ticket = Ticket.create!(
        title: "Active Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        field_values: {
          "severity" => "medium",
          "steps_to_reproduce" => "Test filter active steps"
        }
      )

      archived_ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        archived: true,
        field_values: {
          "severity" => "high",
          "steps_to_reproduce" => "Test filter archived steps"
        }
      )

      archived_tickets = Ticket.archived
      assert_includes archived_tickets, archived_ticket
      assert_not_includes archived_tickets, active_ticket
    end

    test "should archive and unarchive tickets" do
      ticket = Ticket.create!(
        title: "Toggle Archive Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        field_values: {
          "severity" => "medium",
          "steps_to_reproduce" => "Test toggle archive steps"
        }
      )

      # Initially not archived
      assert_not ticket.archived?

      # Archive it
      ticket.update!(archived: true)
      assert ticket.archived?
      assert ticket.locked?

      # Unarchive it
      ticket.update!(archived: false)
      assert_not ticket.archived?
      assert_not ticket.locked? # Should be unlocked after unarchiving
    end

    test "manually locked and archived ticket should remain locked when unarchived" do
      ticket = Ticket.create!(
        title: "Locked and Archived Ticket",
        description: "Description",
        user: @user1,
        board: @board,
        locked: true,
        archived: true,
        field_values: {
          "severity" => "critical",
          "steps_to_reproduce" => "Test locked and archived steps"
        }
      )

      # Should be locked due to both manual lock and archive
      assert ticket.locked?
      assert ticket.archived?

      # Unarchive but keep manual lock
      ticket.update!(archived: false)
      assert_not ticket.archived?
      assert ticket.locked? # Should remain locked due to manual lock
    end
  end
end
