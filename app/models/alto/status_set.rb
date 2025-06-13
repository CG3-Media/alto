module Alto
  class StatusSet < ApplicationRecord
    has_many :statuses, -> { order(:position) }, dependent: :destroy
    has_many :boards, dependent: :nullify

    accepts_nested_attributes_for :statuses,
                                  allow_destroy: true,
                                  reject_if: ->(attributes) {
                                    # Reject if marked for destruction
                                    return true if attributes["_destroy"] == "1" || attributes["_destroy"] == true

                                    # Reject if all key fields are blank
                                    attributes["name"].blank? &&
                                    attributes["slug"].blank? &&
                                    attributes["color"].blank?
                                  }

    validates :name, presence: true, length: { maximum: 100 }
    validates :name, uniqueness: true

    scope :default_set, -> { where(is_default: true) }
    scope :ordered, -> { order(:name) }

    def self.default
      default_set.first
    end

    def has_statuses?
      statuses.any?
    end

    def first_status
      statuses.first
    end

    def status_by_slug(slug)
      statuses.find_by(slug: slug)
    end

    def status_slugs
      statuses.pluck(:slug)
    end

    def status_options_for_select
      statuses.map { |status| [ status.name, status.slug ] }
    end

    def public_statuses
      statuses.publicly_viewable
    end

    def status_options_for_select_filtered(is_admin: false)
      filtered_statuses = is_admin ? statuses : public_statuses
      filtered_statuses.map { |status| [ status.name, status.slug ] }
    end
  end
end
