#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
#++

module Queries::TimeEntries
  query = Queries::TimeEntries::TimeEntryQuery

  Queries::Register.filter query, Queries::TimeEntries::Filters::UserFilter
  Queries::Register.filter query, Queries::TimeEntries::Filters::WorkPackageFilter
  Queries::Register.filter query, Queries::TimeEntries::Filters::ProjectFilter
  Queries::Register.filter query, Queries::TimeEntries::Filters::SpentOnFilter
  Queries::Register.filter query, Queries::TimeEntries::Filters::CreatedAtFilter
  Queries::Register.filter query, Queries::TimeEntries::Filters::UpdatedAtFilter
  Queries::Register.filter query, Queries::TimeEntries::Filters::ActivityFilter

  Queries::Register.order query, Queries::TimeEntries::Orders::DefaultOrder
end
