class CreateMissingAlumnusMembers < ActiveRecord::Migration
  include Rails.application.routes.url_helpers

  def down; end

  def up
    missing_alumni = select_rows(find_missing_people_sql)

    return unless missing_alumni
    
    execute(insert_roles_sql(missing_alumni))
  end

  private

  def find_missing_people_sql
    <<-SQL
    SELECT DISTINCT person_id, layer_group_id, roles.type FROM roles 
    INNER JOIN groups ON roles.group_id = groups.id
    WHERE roles.type IN (#{sanitize(role_types)})
    AND roles.deleted_at IS NOT NULL
    AND person_id NOT IN (
      SELECT DISTINCT person_id FROM roles
      INNER JOIN groups g ON roles.group_id = g.id
      WHERE g.layer_group_id = layer_group_id
      AND roles.deleted_at IS NULL
      AND (
        roles.type IN (#{sanitize(role_types)}) OR
        roles.type IN ('Group::FlockAlumnusGroup::Member', 'Group::ChildGroup::Child'))
    )
    GROUP BY person_id, layer_group_id
    SQL
  end
  
  def insert_roles_sql(list)
    now = Role.sanitize(Time.zone.now)
    <<-SQL
    INSERT INTO roles(created_at, updated_at, person_id, group_id, label, type)
    VALUES #{values(list, now).join(',')}
    SQL
  end

  def values(list, now)
    list.collect do |person_id, group_id, role_type|
      "(#{now}, #{now}, #{person_id}, #{group_id},"\
        " #{role_type.constantize.model_name.human},"\
        " Group::FlockAlumnusGroup::Member)"
    end
  end

  def role_types
    ["Group::Flock::President",
     "Group::Flock::Guide",
     "Group::Flock::Leader",
     "Group::Flock::Treasurer",
     "Group::Flock::GroupAdmin",
     "Group::Flock::DispatchAddress",
     "Group::Flock::CampLeader",
     "Group::Flock::Advisor",
     "Group::Flock::Coach",
     "Group::ChildGroup::Leader",
     "Group::ChildGroup::GroupAdmin",
     "Group::ChildGroup::DispatchAddress"]
  end

  def sanitize(list)
    list.collect { |item| ActiveRecord::Base.sanitize(item) }.join(',')
  end

end
