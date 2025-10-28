module Alto
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Conditionally connect to Alto's dedicated database if configured
    # This is set during installation based on user preference
    if Alto.configuration.use_separate_database
      connects_to database: { writing: :alto, reading: :alto }
    end
  end
end
