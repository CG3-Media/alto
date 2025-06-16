require "rails/generators/base"

module Alto
  module Generators
    class WidgetGenerator < Rails::Generators::Base
      desc "Generate embeddable widget for an Alto board"

      def generate_widget
        @board_slug = ask_for_board
        return unless @board_slug

        create_widget_partial
        show_usage
      end

      private

      def ask_for_board
        boards = get_available_boards

        if boards.empty?
          say "❌ No boards found! Create a board first.", :red
          return nil
        end

        say ""
        say "📋 Available boards:", :cyan
        boards.each_with_index do |board, index|
          say "  #{index + 1}. #{board[:name]} (#{board[:slug]})", :blue
        end

        choice = ask("Which board?", :cyan)

        # Handle numeric choice
        if choice.match?(/^\d+$/)
          index = choice.to_i - 1
          return boards[index][:slug] if index >= 0 && index < boards.length
        end

        # Handle slug choice
        board = boards.find { |b| b[:slug] == choice }
        return board[:slug] if board

        say "❌ Invalid choice!", :red
        nil
      end

      def get_available_boards
        return [] unless defined?(::Alto::Board)

        ::Alto::Board.all.map do |board|
          { name: board.name, slug: board.slug }
        end
      rescue
        []
      end

      def create_widget_partial
        empty_directory "app/views/shared/alto"

        widget_file = "app/views/shared/alto/_#{@board_slug}_widget.html.erb"

        # Check if file exists and ask for confirmation
        if File.exist?(File.join(destination_root, widget_file))
          unless yes?("⚠️  Widget already exists! Overwrite #{widget_file}?", :yellow)
            say "❌ Skipped creating widget", :red
            return
          end
        end

        create_file widget_file, <<~ERB
          <div class="bg-white rounded-lg shadow-sm border p-6">
            <% board = ::Alto::Board.find("#{@board_slug}") %>
            <% ticket = board.tickets.build %>

            <h2 class="text-xl font-semibold mb-4 text-gray-900">
              Submit <%= board.item_label_singular.titleize %>
            </h2>

            <%= form_with model: [board, ticket],
                url: alto.board_tickets_path(board),
                local: true,
                class: "space-y-4" do |form| %>

              <!-- Title -->
              <div>
                <%= form.label :title, class: "block text-sm font-medium text-gray-700 mb-2" %>
                <%= form.text_field :title,
                    placeholder: "Brief, descriptive title for your " + board.item_label_singular,
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" %>
              </div>

              <!-- Description -->
              <div>
                <%= form.label :description, class: "block text-sm font-medium text-gray-700 mb-2" %>
                <%= form.text_area :description,
                    placeholder: "Provide detailed information about your " + board.item_label_singular,
                    rows: 4,
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" %>
              </div>

              <!-- Custom Fields -->
              <% if board.fields.any? %>
                <div class="border-t border-gray-200 pt-4">
                  <% board.fields.sort_by { |field| field.position || 0 }.each do |field| %>
                    <%= render 'alto/shared/custom_board_fields', field: field, ticket: ticket, form: form %>
                  <% end %>
                </div>
              <% end %>

              <div class="pt-4">
                <%= form.submit "Submit \#{board.item_label_singular.titleize}",
                    class: "w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
              </div>
            <% end %>
          </div>
        ERB

        say "✅ Created widget partial", :green
      end

      def show_usage
        say ""
        say "🚀 Widget created!", :cyan
        say ""
        say "📋 Usage:", :yellow
        say "  <%= render 'shared/alto/#{@board_slug}_widget' %>", :blue
        say ""
        say "📁 File location:", :green
        say "  app/views/shared/alto/_#{@board_slug}_widget.html.erb", :blue
        say ""
        say "💡 Features:", :green
        say "  • Standard HTML forms (works everywhere)", :blue
        say "  • JSON API support for custom integrations", :blue
        say "  • Progressive enhancement ready", :blue
        say ""
        say "🎨 Customize the HTML/CSS as needed!", :green
      end
    end
  end
end
