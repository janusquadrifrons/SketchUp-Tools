# Default declerations
mod = Sketchup.active_model # Open model
ent = mod.entities # All entities in model
sel = mod.selection # Current selection
df = mod.definitions # Groups, components
vw = mod.active_view

#msg = UI.messagebox("Pick edges you want your joint extend to.")
icon = File.join(__dir__, "images", "multiple-32.png")

# Standart API hook
require 'sketchup.rb'

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

  def activate

    # We will need to sample 3d points from the model as the user interacts
    # with the tool and the model. For this we use InputPoint which also
    # adds some inference-magic.
    # We need to sample the 3d point under the mouse cursor and keep a
    # reference of what the user clicks on.
    @mouse_ip = Sketchup::InputPoint.new
    @picked_first_ip = Sketchup::InputPoint.new

    update_ui
  end

  # Clear out any custom drawings done to the viewport.
  def deactivate(view)
    view.invalidate
  end

  # Update status bar and viewport in case of orbit etc...
  def resume(view)
    update_ui
    view.invalidate
  end

  def suspend(view)
    view.invalidate
  end

  # Interruption by ESC key, re-activation or undo attempt.
  def onCancel(reason, view)
    reset_tool
    view.invalidate
  end

  def onMouseMove(flags, x, y, view)
    # We want to sample the 3d point under the cursor as the user moves it.
    if picked_first_point?
      # When the user picks a start point we use that while picking in
      # order for SketchUp to do it's inference magic. Note that if you
      # want to allow the user to lock inferencing you need to implement
      # `view.lock_inference`. This will be described in a later tutorial.
      @mouse_ip.pick(view, x, y, @picked_first_ip)
    else
      # When the user hasn't picked a start point yet we just use the
      # x and y coordinates of the cursor.
      @mouse_ip.pick(view, x, y)
    end
    # Here we let SketchUp display its inferencing similar to how the
    # native tools do it.
    view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
    # Lastly we want to ensure we update the view.
    view.invalidate
  end

  # When the user clicks in the viewport we want to create edges based on
  # the input points we have collected.
  def onLButtonDown(flags, x, y, view)
    if picked_first_point? && create_edge > 0
      # When the user have picked a start point and then picks another point
      # we create an edge and try to create new faces from that edge.
      # Like the native tool we reset the tool if it created new faces.
      reset_tool
    else
      # If no face was created we let the user chain new edges to the last
      # input point.
      @picked_first_ip.copy!(@mouse_ip)
    end

    # As always we want to update the statusbar text and view.
    update_ui
    view.invalidate
  end

  # Here we have hard coded a special ID for the pencil cursor in SketchUp.
  # Normally you would use `UI.create_cursor(cursor_path, 0, 0)` instead
  # with your own custom cursor bitmap:
  #
  #   CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
  CURSOR_PENCIL = 632
  def onSetCursor
    # Note that `onSetCursor` is called frequently so you should not do much
    # work here. At most you switch between different cursors representing
    # the state of the tool.
    UI.set_cursor(CURSOR_PENCIL)
  end

  # The `draw` method is called every time SketchUp updates the viewport.
  # You should take care to do as little work in this method as possible.
  # If you need to calculate things to draw it is best to cache the data in
  # order to get better frame rates.
  def draw(view)
    draw_preview(view)
    @mouse_ip.draw(view) if @mouse_ip.display?
  end

  # When you use `view.draw` and draw things outside the boundingbox of
  # the existing model geometry you will see that things get clipped.
  # In order to make sure everything you draw is visible you must return
  # a boundingbox here which defines the 3d model space you draw to.
  def getExtents
    bounds = Geom::BoundingBox.new
    bounds.add(picked_points)
    bounds
  end

  # In this example we put all the logic in the tool class itself. For more
  # complex tools you probably want to move that logic into its own class
  # in order to reduce complexity. If you are familiar with the MVC pattern
  # then consider a tool class a controller - you want to keep it short and
  # simple.
  private

  def update_ui
    if picked_first_point?
      Sketchup.status_text = 'Select an edge to project point.'
    else
      Sketchup.status_text = 'Select start point.'
    end
  end

  def reset_tool
    @picked_first_ip.clear
    update_ui
  end

  def picked_first_point?
    @picked_first_ip.valid?
  end

  def picked_points
    points = []
    points << @picked_first_ip.position if picked_first_point?
    points << @mouse_ip.position if @mouse_ip.valid?
    points
  end

  def draw_preview(view)
    points = picked_points
    return unless points.size == 2
    view.set_color_from_line(*points)
    view.line_width = 1
    view.line_stipple = ''
    view.draw(GL_LINES, points)
  end

  # Returns the number of created faces.
  def create_edge
    model = Sketchup.active_model
    model.start_operation('Edge', true)
    edge = model.active_entities.add_line(picked_points)
    num_faces = edge.find_faces || 0 # API returns nil instead of 0.
    model.commit_operation

    num_faces
  end

end # class LineTool


## MAIN BODY : UTILITY COMMAND
# Start Transaction (Useful in case od an undo)
mod.start_operation "J_Through"

  # TODO : encapsulate in a module
  def self.activate_line_tool
    Sketchup.active_model.select_tool(LineTool.new)
  end # activate_line_tool
  
  def main_j_through
  # Get edges from user after a type check
    selected_edges=[]

    mod = Sketchup.active_model # Open model
    ent = mod.entities # All entities in model
    sel = Sketchup.active_model.selection
    
    sel.each do |e|
      if e.is_a? Sketchup::Edge
        selected_edges << e
      end
    end

    self.activate_line_tool

    # TODO : action of projection MISSING ! Error: #<ArgumentError: wrong number of values in array> 
    line = selected_edges[0]
    old_point = @picked_first_ip.to_a
    new_point = old_point.project_to_line(line)
    
    ent.add_edge(@picked_first_ip, new_point)

  # Get starting point from user
  # Draw joint lines from starting point in sequence
  end # main_j_through
  
  
  
# Commit tx
mod.commit_operation

