# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++
module Meetings
  class MeetingFiltersComponent < FiltersComponent
    def allowed_filters
      super
        .select { |f| allowed_filter?(f) }
        .sort_by(&:human_name)
    end

    protected

    def additional_filter_attributes(filter)
      case filter
      when Queries::Meetings::Filters::ProjectFilter
        ac_filters = [
          { name: "active", operator: "=", values: ["t"] }
        ]

        # if query.project
        #   ac_filters << { name: "id", operator: "=", values: [query.project.id] }
        # end

        {
          autocomplete_options: {
            component: "opce-project-autocompleter",
            filters: ac_filters
          }
        }
      when Queries::Meetings::Filters::AuthorFilter
        {
          autocomplete_options: {
            resource: "principals",
            component: "opce-user-autocompleter",
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals
          }
        }
      else
        {}
      end
    end

    private

    def allowed_filter?(filter)
      allowlist = [
        Queries::Meetings::Filters::ProjectFilter,
        # Queries::Meetings::Filters::TimeFilter,
        # Queries::Meetings::Filters::AttendedUserFilter,
        # Queries::Meetings::Filters::InvitedUserFilter,
        Queries::Meetings::Filters::AuthorFilter
        # Queries::Meetings::Filters::DatesIntervalFilter
      ]

      allowlist.detect { |clazz| filter.is_a? clazz }
    end
  end
end
