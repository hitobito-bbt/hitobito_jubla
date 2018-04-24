
require 'pry'

desc 'tries to fix failed ehemaligen migration'
task :fix => :environment do
	binding.pry
end

def check id
	layers = layers_with_missed_alumni(Person.find(id))
	layers.map { |layer, roles| puts "#{layer.id} #{layer.name}" }

	puts "#{layers.count} found"
end

def missed_assignments 
	# => 3786
	potentials = unassigned_people_ids
	results = []
	potentials.each do |entry|
		person = Person.find(entry["person_id"])
		layers_with_missed_alumni(person).each do |layer|
			results << {person: person.name, person_id: person.id, layer: layer.name, layer_id: layer.id}
		end
	end
	results
end

def group_missed_assignements assignments
	assignments.each_with_object(Hash.new { |h, k| h[k] = [] }) do |assignment, memo|
	  memo[assignment[:layer_name] << {person: person.name, person_id: person.id }
 	end
end

def count_missed_assignments_with_all
	# => 20658 so, I guess there are still some errors… childroles maybe?
	results = 0
	Person.all[0..100].each do |entry|
		results += layers_with_missed_alumni(entry).count
	end
	results
end


def layers_with_missed_alumni person
	result =  []

	roles = active_flock_roles_with_deleted person
	layers = group_roles_by_layer roles
	layers = layers.select do |layer, roles|
		if probable_missed_allumnus?(roles)
			puts "had active roles in #{layer.name}"
			true
		end
	end
	
	events = get_role_events(person)
	recovered_alumni_roles = alumni_roles_from_events events
	layers_from_events = get_layers_from_grouped_events recovered_alumni_roles
	layers_from_events.map { |current| puts "recovered alumnus role for #{current.name}"}

	layers.each do |layer, roles|
		if layers_from_events.any? { |layer_from_events| layer.id == layer_from_events.id }
			result << layer
		end
	end
end

## CONCERNING ROLES

def active_flock_roles_with_deleted person
	person.roles.with_deleted.where(type: active_flock_roles)
end

def group_roles_by_layer roles
	roles.each_with_object(Hash.new { |h, k| h[k] = [] }) do |role, memo|
	  memo[role.group.layer_group] << role
 	end
end

def active_flock_roles
	Group::Flock.roles.select { |role| role.kind == :member } +	
	Group::ChildGroup.roles.select { |role| role.kind == :member }
end

def deprecated_alumnus_roles
     ["Group::ChildGroup::Alumnus",
     "Group::Flock::Alumnus" ]
  end

def probable_missed_allumnus? roles
	roles.all? { |role| role.deleted_at } &&
	roles.any? { |role| role.type.match("Group::ChildGroup::")}
end

## CONCERING EVENTS


def get_role_events person
	PaperTrail::Version.where(main_id: person.id, main_type: "Person", item_type: "Role")
end

def grouped_role_events events
	events.each_with_object(Hash.new { |h, k| h[k] = [] }) do |event, memo|
	  memo[event.item_id] << event
 	end
end

def match_array text, arr
	arr.any? { |elem| text.match(elem) }
end

def alumni_roles_from_events events
	grouped_role_events(events).select do |role_id, role_events| 
		from_deprecated_alumnus_role?(role_events) &&
		!destroyed?(role_events) &&
		!from_child?(role_events)
	end
end

def from_deprecated_alumnus_role? events
	events.any? { |event| match_array(event.object_changes, deprecated_alumnus_roles) if event.object_changes }
end

def destroyed? events
	events.any? { |event| event.event == "destroy" }
end

def from_child? events # TODO: TEST THIS PART
	events.any? { |event| event.object_changes.match "Kind" if event.object_changes }
end

def get_layer_from_object_changes object_changes
	match = object_changes.match /group_id:\s..\s..([0-9]*)/
	group_id = match[1]
	Group.find(group_id).layer_group
end

def get_layers_from_grouped_events grouped_events
	layers = []
	grouped_events.each do |role_id, role_events|
		with_object_changes = role_events.select do |event|
			event.object_changes
		end
		layers << get_layer_from_object_changes(with_object_changes.first.object_changes)
	end
	layers
end


# gives a list of arrays 
def unassigned_people_ids
	results = ActiveRecord::Base.connection.exec_query(unassigned_people_finder)
end

def unassigned_people_finder
	"SELECT roles.person_id AS person_id, groups.layer_group_id AS layer_group_id
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
	"
end
