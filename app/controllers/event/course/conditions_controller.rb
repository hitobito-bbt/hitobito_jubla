class Event::Course::ConditionsController < CrudController
  self.nesting = Group

  helper_method :group
  
  decorates :group
  
  prepend_before_filter :parent

  def create
    super(location: group_event_course_conditions_path(group))
  end
  
  def update
    super(location: group_event_course_conditions_path(group))
  end
 

  private
  
  def list_entries
    super.includes(:group).order(:label)
  end
  
  def group
    @group ||= parent
  end
  
  def assign_attributes
    super
    entry.group = group
  end

  def parent_scope
     group.course_conditions
  end

  def authorize_class
    authorize!(:index_event_course_conditions, group)
  end

  class << self
    def model_class
      Event::Course::Condition
    end
  end
end
