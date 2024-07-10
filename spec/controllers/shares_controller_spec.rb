# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require "spec_helper"

RSpec.describe SharesController do
  shared_let(:user) { create(:user) }
  shared_let(:view_user) { create(:user) }
  shared_let(:edit_user) { create(:user) }
  shared_let(:project_query) { create(:project_query, user:) }
  shared_let(:view_role) { create(:view_project_query_role) }
  shared_let(:edit_role) { create(:edit_project_query_role) }
  shared_let(:view_member) { create(:member, entity: project_query, principal: view_user, roles: [view_role]) }
  shared_let(:edit_member) { create(:member, entity: project_query, principal: edit_user, roles: [edit_role]) }

  before { login_as(user) }

  # We test the specifc behavior for loading the entity here. In the rest of the test we just use project_query as the
  # entity because it is easier to set up as it does not need a project. There should be no entity specific behavior
  # outside of the `load_entity` method
  describe "entity specific behavior" do
    context "for a work package" do
      let(:work_package) { create(:work_package) }
      let(:make_request) do
        get :index, params: { work_package_id: work_package.id }
      end

      context "when the user does not have permission to access the work package" do
        before do
          mock_permissions_for(user, &:forbid_everything)
        end

        it "raises a RecordNotFound error" do
          expect { make_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the user does have permission" do
        before do
          role = create(:project_role, permissions: %i[view_work_packages view_shared_work_packages])
          create(:member, project: work_package.project, principal: user, roles: [role])
          make_request
        end

        it "loads the work package and initializes correct strategy" do
          expect(assigns(:entity)).to eq(work_package)
          expect(assigns(:sharing_strategy)).to be_a(SharingStrategies::WorkPackageStrategy)
        end
      end
    end

    context "for a project query" do
      let(:project_query) { create(:project_query, user: create(:user)) }
      let(:make_request) do
        get :index, params: { project_query_id: project_query.id }
      end

      context "when the user does not have permission to access the project query (as it is not owned by the user)" do
        before do
          mock_permissions_for(user, &:forbid_everything)
        end

        it "raises a RecordNotFound error" do
          expect { make_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the user does have permission" do
        before do
          role = create(:project_query_role, permissions: %i[view_project_query])
          create(:member, entity: project_query, principal: user, roles: [role])
          make_request
        end

        it "loads the project query and initializes correct strategy" do
          expect(assigns(:entity)).to eq(project_query)
          expect(assigns(:sharing_strategy)).to be_a(SharingStrategies::ProjectQueryStrategy)
        end
      end
    end
  end

  describe "dialog" do
    let(:make_request) { get :dialog, params: { project_query_id: project_query.id }, format: :turbo_stream }

    context "when the strategy does not allow viewing or managing" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: false, manageable?: false,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "returns a 403 status" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the strategy allows viewing" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: true, manageable?: false,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:dialog)
      end
    end

    context "when the strategy allows managing" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: false, manageable?: true,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:dialog)
      end
    end
  end

  describe "index" do
    let(:make_request) { get :index, params: { project_query_id: project_query.id }, format: :turbo_stream }

    before do
      # Spy the render call to assert the right
      # components to have rendered
      allow(controller).to receive(:render).and_call_original
    end

    context "when the strategy does not allow viewing or managing but enterprise check succeeds",
            with_ee: %i[work_package_sharing] do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: false, manageable?: false,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "responds with 403" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the strategy allows viewing but enterprise check fails" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: true, manageable?: false,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "renders the upsale component" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(controller).to have_received(:render).with(an_instance_of(Shares::ModalUpsaleComponent))
      end
    end

    context "when the strategy allows viewing and enterprise check passes",
            with_ee: %i[work_package_sharing] do
      before do
        # Since this goes through and renders, we only care about
        # stubbing permission related methods
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: false)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(controller).to have_received(:render).with(
          an_instance_of(Shares::ModalBodyComponent),
          layout: nil
        )
      end
    end

    context "when the strategy allows managing but enterprise check fails" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: false, manageable?: true,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "renders the upsale component" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(controller).to have_received(:render).with(an_instance_of(Shares::ModalUpsaleComponent))
      end
    end

    context "when the strategy allows managing and enterprise check passes",
            with_ee: %i[work_package_sharing] do
      before do
        # Since this goes through and renders, we only care about
        # stubbing permission related methods
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(controller).to have_received(:render).with(
          an_instance_of(Shares::ModalBodyComponent),
          layout: nil
        )
      end
    end
  end

  describe "create" do
    shared_let(:new_shared_user) { create(:user) }
    shared_let(:new_locked_shared_user) { create(:locked_user) }

    let(:make_request) do
      post :create, params: {
        project_query_id: project_query.id,
        member: { user_ids: [shared_user.id], role_id: view_role.id }
      }, format: :turbo_stream
    end
    let(:shared_user) { new_shared_user }

    context "when the strategy allows managing" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)

        allow(controller).to receive(:create_or_update_share).and_call_original
        allow(controller).to receive(:respond_with_prepend_shares).and_call_original
        allow(controller).to receive(:respond_with_replace_modal).and_call_original
        allow(controller).to receive(:respond_with_new_invite_form).and_call_original
      end

      context "and there were no shares originally" do
        before do
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [])
        end

        it "calls respond_with_replace_modal" do
          make_request
          expect(controller).to have_received(:respond_with_replace_modal)
        end
      end

      context "and there was at least a share originally" do
        before do
          # Former + new share
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [edit_member])
        end

        it "calls respond_with_prepend_shares" do
          make_request
          expect(controller).to have_received(:respond_with_prepend_shares)
        end
      end

      context "when the user is locked" do
        let(:shared_user) { new_locked_shared_user }

        it "calls respond_with_new_invite_form" do
          make_request
          expect(controller).to have_received(:respond_with_new_invite_form)
        end
      end
    end
  end

  describe "update" do
    let(:make_request) do
      patch :update, params: {
        project_query_id: project_query.id,
        id: view_member.id,
        member: { role_id: edit_role.id }
      }, format: :turbo_stream
    end

    context "when the strategy allows managing" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)

        allow(controller).to receive(:create_or_update_share).and_call_original
        allow(controller).to receive(:respond_with_replace_modal).and_call_original
        allow(controller).to receive(:respond_with_update_permission_button).and_call_original
        allow(controller).to receive(:respond_with_remove_share).and_call_original
      end

      context "and the list of filtered shares is now empty" do
        before do
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [])
        end

        it "calls respond_with_replace_modal" do
          make_request
          expect(controller).to have_received(:respond_with_replace_modal)
        end
      end

      context "and the share is still within the list of filtered shares" do
        it "calls respond_with_update_permission_button" do
          make_request
          expect(controller).to have_received(:respond_with_update_permission_button)
        end
      end

      context "and the share no longer belongs to the list of filtered shares" do
        before do
          # Includes other share only, not the one being modified
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [edit_member])
        end

        it "calls respond_with_remove_share" do
          make_request
          expect(controller).to have_received(:respond_with_remove_share)
        end
      end
    end
  end

  describe "destroy" do
    let(:make_request) do
      delete :destroy, params: {
        project_query_id: project_query.id,
        id: view_member.id
      }, format: :turbo_stream
    end

    context "when the strategy allows managing" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)

        allow(controller).to receive(:respond_with_replace_modal).and_call_original
        allow(controller).to receive(:respond_with_remove_share).and_call_original
      end

      context "and the list of filtered shares is now empty" do
        before do
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [])
        end

        it "calls respond_with_replace_modal" do
          make_request
          expect(controller).to have_received(:respond_with_replace_modal)
        end
      end

      context "and there are still shares in the list" do
        it "calls respond_with_remove_share" do
          make_request
          expect(controller).to have_received(:respond_with_remove_share)
        end
      end
    end
  end

  describe "resend_invite" do
  end

  describe "bulk_update" do
  end

  describe "bulk_destroy" do
  end
end
