# frozen_string_literal: true

module IncidentManagement
  class TimelineEvent < ApplicationRecord
    include CacheMarkdownField

    self.table_name = 'incident_management_timeline_events'

    cache_markdown_field :note,
      pipeline: :'incident_management/timeline_event',
      issuable_reference_expansion_enabled: true

    belongs_to :project
    belongs_to :author, class_name: 'User', foreign_key: :author_id
    belongs_to :incident, class_name: 'Issue', foreign_key: :issue_id, inverse_of: :incident_management_timeline_events
    belongs_to :updated_by_user, class_name: 'User', foreign_key: :updated_by_user_id
    belongs_to :promoted_from_note, class_name: 'Note', foreign_key: :promoted_from_note_id

    validates :project, :incident, :occurred_at, presence: true
    validates :action, presence: true, length: { maximum: 128 }
    validates :note, presence: true, length: { maximum: 10_000 }
    validates :note_html, length: { maximum: 10_000 }

    has_many :timeline_event_tag_links, class_name: 'IncidentManagement::TimelineEventTagLink'
    has_many :timeline_event_tags,
      class_name: 'IncidentManagement::TimelineEventTag',
      through: :timeline_event_tag_links

    scope :order_occurred_at_asc_id_asc, -> { reorder(occurred_at: :asc, id: :asc) }
  end
end
