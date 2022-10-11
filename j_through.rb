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

## Main command body
# Start Transaction (Useful in case od an undo)
mod.start_operation "J_Through"

  # TODO : encapsulate in a module
  def main_j_through
  # Get edges from user
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

