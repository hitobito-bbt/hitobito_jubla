# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

require 'spec_helper'
require_relative '../support/fabrication.rb'
describe EventsController, type: :controller  do

  render_views

  let(:be) { groups(:be) }
  let(:no) { groups(:no) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    Fabricate(Group::State::GroupAdmin.name.to_sym, group: be, person: people(:top_leader))
    sign_in(people(:top_leader))
  end

  context 'application contact' do

    describe 'new course' do

      it 'should not be possible to select the contact group if only one option is available' do
        get :new, params: { group_id: be.id, event: { type: 'Event::Course' } }
        expect(dom).to have_no_selector('#event_application_contact_id')
      end

      it 'should be possible to select the contact group if multiple state agencies are available' do
        # add an additonal state agency to be
        Fabricate(Group::StateAgency.name.to_sym, parent: be)

        get :new, params: { group_id: be.id, event: { type: 'Event::Course' } }
        expect(dom.all('select#event_application_contact_id option').count).to eq 3
      end
    end

    describe 'edit course' do
      it "should be possible to select one of the assigned group's state agencies as application contact" do
        course = Fabricate(:jubla_course, groups: [be, no])
        get :edit, params: { group_id: be.id, id: course.id }
        expect(dom).to have_selector('select#event_application_contact_id')
        expect(dom.all('select#event_application_contact_id option').count).to eq 3
      end
    end

    describe 'view course' do
      it 'should display application contact address' do
        course = Fabricate(:jubla_course, groups: [be, no])
        course.save!

        get :show, params: { group_id: be.id, id: course.id }
        expect(dom).to have_selector('dt', text: 'Anmeldung an')
        expect(dom).to have_selector('dt', text: 'J+S Bezeichnung')
      end
    end

  end
end
