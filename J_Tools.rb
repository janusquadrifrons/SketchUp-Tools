# "Copyright 2022, janusquadrifrons"

# API hook
require "sketchup.rb"

# Show Ruby console at start
SKETCHUP_CONSOLE.show

class ProjectToLine

    # Initialize the input point upon start
    def activate
        @input = Sketchup::InputPoint.new
        @isPicked = false
        #@edges = Sketchup::InputPoint.new
    end

    # Left click response in design window
    def onLButtonDown flags, x, y, view
        if @isPicked == false
            @input.pick view, x, y
            Sketchup::set_status_text "Left Click", SB_VCB_LABEL
            pos = @input.position
            str = "%.2f, %.2f, %.2f" % [pos.x, pos.y, pos.z]
            Sketchup::set_status_text str, SB_VCB_VALUE
            @isPicked = true
            puts "Left button down - Point Picked"
        else
            # Retrieve enttity on current cursor location via PickHelper object
            pickhelper = view.pick_helper
            count = pickhelper.do_pick(x, y)
            best_picked = pickhelper.best_picked
            puts pickhelper.count
            puts "Entity Type → " + best_picked.to_s + " ←" # returns → Sketchup::Edge 

            best_picked_line = best_picked.line
            puts "Entity Type → " + best_picked_line.to_s + " ←" # returns → [Point3d(-83.3837, 161.118, 0), Vector3d(0.77154, -0.636181, 0)]

            @entity_path_list = pickhelper.path_at(0)
            pos = @input.position
            puts "@input → " + @input.to_s + " ←" # returns → Sketchup::InputPoint
            puts "Input Position → " + pos.to_s + " ←"
            
            input_pt = [pos.x, pos.y, pos.z]
            input_pt_2 = Geom::Point3d.new(pos.x, pos.y, pos.z) # Alt-2 : aynı sonucu verir

            puts "input_pt Input Position Each → " + input_pt.to_s + " ←"
            puts "input_pt_2 Input Position Each → " + input_pt_2.to_s + " ←"

            projected_point = input_pt.project_to_line(best_picked_line)    # input_pt → wrong arg type dedi
                                                                            # @input → undefined method 
            ents = Sketchup.active_model.entities 
            ents.add_line(input_pt, projected_point)

            puts @isPicked
            puts "Left button down - Edge Selected"
        end
    end
end

class LineFromOrigin

    # Initialize the input point upon start
    def activate
        @input_lfo = Sketchup::InputPoint.new
        puts "LİneFromOrigin : Activated."
    end

    # Left click response in design window
    def onLButtonDown flags, x, y, view

        # Retrieve enttity on current cursor location via PickHelper object
        @input_lfo.pick view, x, y
        Sketchup::set_status_text "Line From Origin", SB_VCB_LABEL
        pos = @input_lfo.position
        str = "%.2f, %.2f, %.2f" % [pos.x, pos.y, pos.z]
        Sketchup::set_status_text str, SB_VCB_VALUE
        puts "LineFromOrigin : Left button down - point picked"
        pos = @input_lfo.position

        ents = Sketchup.active_model.entities
        ents.add_line [0,0,0], [pos.x, pos.y, pos.z]

    end
end

# Create the command objects
cmd_projet_to_line = UI::Command.new("J_ProjectToLine") {
    Sketchup.active_model.select_tool ProjectToLine.new
}
cmd_line_from_origin = UI::Command.new("J_LineFromOrigin") {
    Sketchup.active_model.select_tool LineFromOrigin.new
}

# Add menu items and relate to commands
j_menu = UI.menu("Extensions")
j_menu.add_separator
j_submenu = j_menu.add_submenu("J_Tools")
j_submenu.add_item cmd_projet_to_line
j_submenu.add_item cmd_line_from_origin

# Add a toolbar
j_toolbar = UI::Toolbar.new "J_Tools"
j_toolbar.show

# Icon definitions
icon_project_to_line = File.join(__dir__, "J_Tools_icons", "projecttoline_24.png")
cmd_projet_to_line.small_icon = icon_project_to_line
cmd_projet_to_line.large_icon = icon_project_to_line
cmd_projet_to_line.tooltip = "J_ProjectToLine"
cmd_projet_to_line.status_bar_text = "Project your point to your lines."

icon_line_from_origin = File.join(__dir__, "J_Tools_icons", "linefromorigin_24.png")
cmd_line_from_origin.small_icon = icon_line_from_origin
cmd_line_from_origin.large_icon = icon_line_from_origin
cmd_line_from_origin.tooltip = "J_LineFromOrigin"
cmd_line_from_origin.status_bar_text = "Connect your point to the origin."

# Insert commands to the toolbar
j_toolbar.add_item cmd_projet_to_line
j_toolbar.add_item cmd_line_from_origin


