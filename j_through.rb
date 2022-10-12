# Default declerations
mod = Sketchup.active_model # Open model
ent = mod.entities # All entities in model
sel = mod.selection # Current selection
df = mod.definitions # Groups, components
vw = mod.active_view
#msg = UI.messagebox("Pick edges you want your joint extend to.")
icon = File.join(__dir__, "images", "multiple-32.png")

# Standart API hook
require "sketchup.rb"

# Show Ruby console at start
SKETCHUP_CONSOLE.show

# Add a menu item and run
j_tools_menu = UI.menu("Extensions")
j_tools_submenu = j_tools_menu.add_submenu("J_Tools")
j_tools_submenu.add_item("J_Through"){
msg
main_j_through
}

# Add a toolbar and run
toolbar = UI::Toolbar.new "J_Tools"
cmd = UI::Command.new("J_Through"){
msg
main_j_through
}
# TODO : change image file
cmd.small_icon = icon
cmd.large_icon = icon
cmd.tooltip = "J_Through"
cmd.status_bar_text = "Extends your joint line through selected edges."
toolbar = toolbar.add_item cmd
toolbar.show

# Messagebox alert
def msg()
  UI.messagebox("Pick edges you want your joint extend to")
end

class LineTool
  # Pre-initialization
  def activate
    @picked_first_ip = Sketchup::InputPoint.new
    @mouse_ip = Sketchup::InputPoint.new
    #call utility method for appropriate statusbar instructions
    update_ui
  end # activate
  
  # Switching to another tool
  def deactivate(view)
    view.invalidate
  end # deactivate
  
  # Temporary suspend and resume : orbit etc.
  def resume(view)
    update_ui
    view.invalidate
  end # resume
  
  def suspend(view)
    view.invalidate
  end # suspend
  
  # Reset case
  def onCancel(reason, view)
    reset_tool
    view.invalidate
  end # onCancel
  
  def onLButtonDown(flags, x, y, view)
    #TODO
  end # onLButtonDown
  
  def draw(view)
    draw_preview(view)
    @mouse_ip.draw(view) if @mouse_ip.display?
  end # draw
  
  def getExtents
    bounds = Geom::BoundingBox.new
    bounds.add(picked_points)
    bounds
  end # getExtents
  
  private
  
  def update_ui
    if picked_first_point?
      Sketchup.status_text = 'Select end point.'
    else
      Sketchup.status_text = 'Select start point.'
    end
  end # update_ui
  
  def reset_tool
    @picked_first_ip.clear
    update_ui
  end
  
  def picked_first_point?
    @picked_first_ip.valid?
  end
  
  def picked_points
    points = []
    pt1 = project_to_line @picked_first_ip
    pt2 = project_to_line pt1
    pt3 = project_to_line pt2
    points << @picked_first_ip.position if picked_first_point?
    points << pt1
    points << pt2
    points << pt3
    points
  end
  
  def draw_preview(view)
    points = picked_points
    return unless points.size == 4
    view.set_color_from_line(*points)
    view.line_width = 1
    view.line_stipple = ''
    view.draw(GL_LINES, points)
  end
  
  def create_edge
    mod.start_operation('Edge', true)
    edge = ent.add_line(picked_points)
    num_faces = edge.find_faces || 0 # API returns nil instead of 0.
    model.commit_operation

    num_faces
  end # create_edge

end # class LineTool

## MAIN BODY : UTILITY COMMAND
# Start Transaction (Useful in case od an undo)
mod.start_operation "J_Through"

  # TODO : encapsulate in a module
  def main_j_through
  # Get edges from user after a type check
    selected_edges=[]

    sel.each do |e|
     if e.is_a? Sketchup::Edge
       selected_edges << e
     end
    end

  # Get starting point from user
  # Draw joint lines from starting point in sequence
  end
  
  
  
# Commit tx
mod.commit_operation

