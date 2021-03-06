# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

module JublaOst
  class KursTnStatus < Struct.new(:id, :role)
    cattr_reader :all

    def self.new(id, role)
      instance = super
      @@all ||= {}
      @@all[id] = instance
    end

    None = new(0, Event::Course::Role::Participant)
    Kurshauptleiter = new(10, Event::Role::Leader)
    LeiterExperte = new(20, Event::Role::AssistantLeader)
    LeiterAusbildner = new(30, Event::Role::AssistantLeader)
    LeiterInklFKModul = new(40, Event::Role::AssistantLeader)
    LeiterExklFKModul = new(50, Event::Role::AssistantLeader)
    LeiterAlsTN = new(80, Event::Role::AssistantLeader)
    Teilnehmer = new(90, Event::Course::Role::Participant)
    Kueche = new(100, Event::Role::Cook)
    GKTeilnehmer = new(200, Event::Course::Role::Participant)
    GLKTeilnehmer = new(210, Event::Course::Role::Participant)
    SLKTeilnehmer = new(220, Event::Course::Role::Participant)
    Kurspersonal = new(45, Event::Role::AssistantLeader)
  end
end
