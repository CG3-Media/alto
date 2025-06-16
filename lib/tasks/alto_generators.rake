namespace :alto do
  desc "Show available Alto generators"
  task :generators do
    puts <<~GENERATORS
      🎯 Alto Generators

      Generate embeddable widgets:
        rails generate alto:widget

      This will:
        • Ask which board to create a widget for
        • Generate a partial at app/views/shared/alto/_BOARD_widget.html.erb
        • Give you embed code to use anywhere in your app

      Example usage:
        <%= render 'shared/alto/feature_requests_widget' %>

    GENERATORS
  end
end
