module Alto
  module Searchable
    extend ActiveSupport::Concern

    included do
      # Main search scope with fuzzy matching
      scope :search, ->(query) {
        return all if query.blank?

        # Use appropriate search method based on database
        if connection.adapter_name.downcase.include?("postgresql")
          search_postgresql_trigram(query.strip)
        else
          search_generic_like(query.strip)
        end
      }
    end

        class_methods do
            # PostgreSQL trigram-based fuzzy search
      def search_postgresql_trigram(query)
        sanitized_query = sanitize_sql_like(query)

        # For PostgreSQL, we'll use similarity scoring
        # This requires the pg_trgm extension to be enabled
        # Build the search with proper SQL escaping
        select_clause = Arel.sql(
          sanitize_sql_array([
            "#{table_name}.*, (COALESCE(similarity(title, ?), 0) * 2 + COALESCE(similarity(description, ?), 0)) as search_score",
            query, query
          ])
        )

        where_clause = sanitize_sql_array([
          "(title % ? OR description % ? OR LOWER(title) LIKE ? OR LOWER(description) LIKE ?)",
          query, query, "%#{sanitized_query.downcase}%", "%#{sanitized_query.downcase}%"
        ])

        select(select_clause)
          .where(where_clause)
          .order("search_score DESC, created_at DESC")
      rescue ActiveRecord::StatementInvalid => e
        # If pg_trgm is not installed, fall back to simple LIKE search
        if e.message.include?("operator does not exist") || e.message.include?("function similarity")
          Rails.logger.warn "[Alto] pg_trgm not available, falling back to LIKE search"
          search_generic_like(query)
        else
          raise e
        end
      end

      # Generic database search using LIKE
      def search_generic_like(query)
        sanitized_query = "%#{sanitize_sql_like(query.strip)}%"

        where(
          "LOWER(title) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)",
          sanitized_query, sanitized_query
        ).order(created_at: :desc)
      end
    end
  end
end
