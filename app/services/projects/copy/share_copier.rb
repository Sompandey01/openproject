#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

module Projects::Copy
  # Can be included in case the dependent service needs to be listed in the copy_dependency section for:
  # * Being an option in the UI
  # * Calculating the count
  # but does not really need to do anything beyond that.
  #
  # This is currently employed to turn the work package shares services into NoCreate services as
  # work package shares handling has been moved into the create service of WorkPackage
  module ShareCopier
    extend ActiveSupport::Concern

    class_methods do
      def share_dependent_service(service_const = nil)
        @share_dependent_service = service_const if service_const

        @share_dependent_service
      end

      def copy_dependencies
        super + [share_dependent_service]
      end
    end

    protected

    def copy_shares?
      (params.dig(:params, :only) || [])
        .any? { |k| k.to_s == self.class.share_dependent_service.identifier }
    end
  end
end
