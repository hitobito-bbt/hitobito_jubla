class CreateMissingAlumnusMembers < ActiveRecord::Migration
  def change
    puts execute(select)
    raise :oo
  end

  def select
    <<-SQL.strip_heredoc
      SELECT roles.person_id AS person_id, groups.layer_group_id AS layer_group_id
      FROM roles
      INNER JOIN groups ON roles.group_id = groups.id
      WHERE roles.deleted_at IS NOT NULL
      AND groups.deleted_at IS NULL
      AND TIMESTAMPDIFF(DAY, roles.created_at, roles.deleted_at) > 5
      AND roles.type NOT IN (
        'Group::ChildGroup::Child',
        'Group::ChildGroup::External',
        'Group::ChildGroup::External',
        'Group::FederalBoard::External',
        'Group::FederalProfessionalGroup::External',
        'Group::Federation::External',
        'Group::Flock::External',
        'Group::FlockAlumnusGroup::External',
        'Group::Region::External',
        'Group::RegionalBoard::External',
        'Group::SimpleGroup::External',
        'Group::State::External',
        'Group::StateAgency::External',
        'Group::StateBoard::External',
        'Group::StateProfessionalGroup::External',
        'Group::StateWorkGroup::External'
      )
      GROUP BY person_id, layer_group_id
      HAVING (person_id, layer_group_id) NOT IN (
        SELECT roles.person_id, groups.layer_group_id
        FROM roles
        INNER JOIN groups ON roles.group_id = groups.id
        WHERE groups.layer_group_id = layer_group_id
        AND roles.deleted_at IS NULL
      );
    SQL
  end
end
