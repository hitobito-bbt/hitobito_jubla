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
    SELECT DISTINCT person_id, group_id, roles.type, groups.type FROM roles 
    INNER JOIN groups ON roles.group_id = groups.id
    AND roles.deleted_at IS NOT NULL
    AND ( groups.type = 'Group::Flock' OR
        roles.type = 'Group::ChildGroup::Leader')
    AND person_id NOT IN (
      SELECT DISTINCT person_id FROM roles
      INNER JOIN groups ON roles.group_id = groups.id
      WHERE roles.deleted_at IS NULL
      AND groups.type = 'Group::Flock'
    )
    AND person_id NOT IN (
      SELECT DISTINCT person_id FROM roles
      WHERE roles.type = 'Group::Flock::Alumnus'
    )
    GROUP BY person_id, group_id
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
    list.collect do |person_id, group_id, role_type, group_type|
      "(#{now}, #{now}, #{person_id}, #{group_id},"\
        " #{role_type.constantize.model_name.human},"\
        " #{group_type}::Alumnus)"
    end
  end
end
